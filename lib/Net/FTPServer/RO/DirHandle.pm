#!/usr/bin/perl -w -T
# -*- perl -*-

# Net::FTPServer A Perl FTP Server
# Copyright (C) 2000 Bibliotech Ltd., Unit 2-3, 50 Carnwath Road,
# London, SW6 3EG, United Kingdom.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# $Id: DirHandle.pm,v 1.7 2001/07/25 19:18:23 rich Exp $

=pod

=head1 NAME

Net::FTPServer::RO::DirHandle - The anonymous, read-only FTP server personality

=head1 SYNOPSIS

  use Net::FTPServer::RO::DirHandle;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=cut

package Net::FTPServer::RO::DirHandle;

use strict;

# Some magic which is required by CPAN. This is not the real version
# number. If you want that, have a look at FTPServer::VERSION.
use vars qw($VERSION);
$VERSION = '1.0';

use IO::Dir;
use Carp qw(confess);

use Net::FTPServer::DirHandle;

use vars qw(@ISA);

@ISA = qw(Net::FTPServer::DirHandle);

=pod

=item $handle = $dirh->get ($filename);

Return the file or directory C<$handle> corresponding to
the file C<$filename> in directory C<$dirh>. If there is
no file or subdirectory of that name, then this returns
undef.

=cut

sub get
  {
    my $self = shift;
    my $filename = shift;

    # None of these cases should ever happen.
    confess "no filename" unless defined($filename) && length($filename);
    confess "slash filename" if $filename =~ /\//;
    confess ".. filename"    if $filename eq "..";
    confess ". filename"     if $filename eq ".";

    my $pathname = $self->{_pathname} . $filename;
    stat $pathname;

    if (-d _)
      {
	return Net::FTPServer::RO::DirHandle->new ($self->{ftps}, $pathname."/");
      }

    if (-e _)
      {
	return Net::FTPServer::RO::FileHandle->new ($self->{ftps}, $pathname);
      }

    return undef;
  }

=item $dirh = $dirh->parent;

Return the parent directory of the directory C<$dirh>. If
the directory is already "/", this returns the same directory handle.

=cut

sub parent
  {
    my $self = shift;

    my $parent = $self->SUPER::parent;
    bless $parent, ref $self;
    return $parent;
  }

=pod

=item $ref = $dirh->list ([$wildcard]);

Return a list of the contents of directory C<$dirh>. The list
returned is a reference to an array of pairs:

  [ $filename, $handle ]

The list returned does I<not> include "." or "..".

The list is sorted into alphabetical order automatically.

=cut

sub list
  {
    my $self = shift;
    my $wildcard = shift;

    # Convert wildcard to a regular expression.
    if ($wildcard)
      {
	$wildcard = $self->{ftps}->wildcard_to_regex ($wildcard);
      }

    my $dir = new IO::Dir ($self->{_pathname})
      or return undef;

    my $file;
    my @filenames = ();

    while (defined ($file = $dir->read))
      {
	next if $file eq "." || $file eq "..";
	next if $wildcard && $file !~ /$wildcard/;

	push @filenames, $file;
      }

    $dir->close;

    @filenames = sort @filenames;
    my @array = ();

    foreach $file (@filenames)
      {
	my $handle
	  = -d "$self->{_pathname}$file"
	    ? Net::FTPServer::RO::DirHandle->new ($self->{ftps}, $self->{_pathname} . $file)
	    : Net::FTPServer::RO::FileHandle->new ($self->{ftps}, $self->{_pathname} . $file);

	push @array, [ $file, $handle ];
      }

    return \@array;
  }

=pod

=item $ref = $dirh->list_status ([$wildcard]);

Return a list of the contents of directory C<$dirh> and
status information. The list returned is a reference to
an array of triplets:

  [ $filename, $handle, $statusref ]

where $statusref is the tuple returned from the C<status>
method (see L<Net::FTPServer::Handle>).

The list returned does I<not> include "." or "..".

The list is sorted into alphabetical order automatically.

=cut

sub list_status
  {
    my $self = shift;

    my $arrayref = $self->list (@_);
    my $elem;

    foreach $elem (@$arrayref)
      {
	my @status = $elem->[1]->status;
	push @$elem, \@status;
      }

    return $arrayref;
  }

=pod

=item ($mode, $perms, $nlink, $user, $group, $size, $time) = $handle->status;

Return the file or directory status. The fields returned are:

  $mode     Mode        'd' = directory,
                        'f' = file,
                        and others as with
                        the find(1) -type option.
  $perms    Permissions Permissions in normal octal numeric format.
  $nlink    Link count
  $user     Username    In printable format.
  $group    Group name  In printable format.
  $size     Size        File size in bytes.
  $time     Time        Time (usually mtime) in Unix time_t format.

In derived classes, some of this status information may well be
synthesized, since virtual filesystems will often not contain
information in a Unix-like format.

=cut

sub status
  {
    my $self = shift;

    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,
	$atime, $mtime, $ctime, $blksize, $blocks)
      = lstat $self->{_pathname};

    # If the directory has been removed since we created this
    # handle, then $dev will be undefined. Return dummy status
    # information.
    return ("d", 0000, 1, "-", "-", 0, 0) unless $dev;

    # Generate printable user/group.
    my $user = getpwuid ($uid) || "-";
    my $group = getgrgid ($gid) || "-";

    # Permissions from mode.
    my $perms = $mode & 0777;

    # Work out the mode using special "_" operator which causes Perl
    # to use the result of the previous stat call.
    $mode
      = (-f _ ? 'f' :
	 (-d _ ? 'd' :
	  (-l _ ? 'l' :
	   (-p _ ? 'p' :
	    (-S _ ? 's' :
	     (-b _ ? 'b' :
	      (-c _ ? 'c' : '?')))))));

    return ($mode, $perms, $nlink, $user, $group, $size, $mtime);
  }

=pod

=item $rv = $handle->move ($dirh, $filename);

Move the current file (or directory) into directory C<$dirh> and
call it C<$filename>. If the operation is successful, return 0,
else return -1.

Underlying filesystems may impose limitations on moves: for example,
it may not be possible to move a directory; it may not be possible
to move a file to another directory; it may not be possible to
move a file across filesystems.

=cut

sub move
  {
    return -1;			# Not permitted in read-only server.
  }

=pod

=item $rv = $dirh->delete;

Delete the current directory. If the delete command was
successful, then return 0, else if there was an error return -1.

It is normally only possible to delete a directory if it
is empty.

=cut

sub delete
  {
    return -1;			# Not permitted in read-only server.
  }

=item $rv = $dirh->mkdir ($name);

Create a subdirectory called C<$name> within the current directory
C<$dirh>.

=cut

sub mkdir
  {
    return -1;			# Not permitted in read-only server.
  }

=item $file = $dirh->open ($filename, "r"|"w"|"a");

Open or create a file called C<$filename> in the current directory,
opening it for either read, write or append. This function
returns a C<IO::File> handle object.

=cut

sub open
  {
    my $self = shift;
    my $filename = shift;
    my $mode = shift;

    die if $filename =~ /\//;	# Should never happen.

    return undef unless $mode eq "r";

    return new IO::File $self->{_pathname} . $filename, $mode;
  }

=pod

=item $rv = $dirh->can_write;

Return true if the current user can write into the current
directory (ie. create files, rename files, delete files, etc.).

=cut

sub can_write
  {
    return 0;
  }

=pod

=item $rv = $dirh->can_delete;

Return true if the current user can delete the current
directory.

=cut

sub can_delete
  {
    return 0;
  }

=pod

=item $rv = $dirh->can_enter;

Return true if the current user can enter the current
directory.

=cut

sub can_enter
  {
    my $self = shift;

    return -x $self->{_pathname};
  }

=pod

=item $rv = $dirh->can_list;

Return true if the current user can list the current
directory.

=cut

sub can_list
  {
    my $self = shift;

    return -r $self->{_pathname};
  }

=pod

=item $rv = $dirh->can_rename;

Return true if the current user can rename the current
directory.

=cut

sub can_rename
  {
    return 0;
  }

=pod

=item $rv = $dirh->can_mkdir;

Return true if the current user can create subdirectories of the
current directory.

=cut

sub can_mkdir
  {
    return 0;
  }

1 # So that the require or use succeeds.

__END__

=back 4

=head1 AUTHORS

Richard Jones (rich@annexia.org).

=head1 COPYRIGHT

Copyright (C) 2000 Biblio@Tech Ltd., Unit 2-3, 50 Carnwath Road,
London, SW6 3EG, UK

=head1 SEE ALSO

L<Net::FTPServer(3)>, L<perl(1)>

=cut
