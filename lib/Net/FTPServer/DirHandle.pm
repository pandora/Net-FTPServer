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

# $Id: DirHandle.pm,v 1.9 2000/09/12 12:50:55 rich Exp $

=pod

=head1 NAME

Net::FTPServer::DirHandle - A Net::FTPServer directory handle.

=head1 SYNOPSIS

  use Net::FTPServer::DirHandle;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=cut

package Net::FTPServer::DirHandle;

use strict;

# Some magic which is required by CPAN. This is not the real version
# number. If you want that, have a look at FTPServer::VERSION.
use vars qw($VERSION);
$VERSION = '1.0';

use IO::Dir;
use Carp qw(confess);

use Net::FTPServer::Handle;

use vars qw(@ISA);

@ISA = qw(Net::FTPServer::Handle);

=pod

=item $dirh = new Net::FTPServer::DirHandle ($ftps);

Create a new directory handle. The directory handle corresponds to "/".

=cut

sub new
  {
    my $class = shift;
    my $ftps = shift;

    # Only internal calls will supply the $path argument. It must end
    # with a "/".
    my $path = shift || "/";

    my $self = Net::FTPServer::Handle->new ($ftps);
    $self->{_pathname} = $path;

    return bless $self, $class;
  }

=pod

=item $dirh = $dirh->parent;

Return the parent directory of the directory C<$dirh>. If
the directory is already "/", this returns the same directory handle.

=cut

sub parent
  {
    my $self = shift;

    # Already in "/" ?
    return $self if $self->is_root;

    my $new_pathname = $self->{_pathname};
    $new_pathname =~ s,[^/]*/$,,;

    return Net::FTPServer::DirHandle->new ($self->{ftps}, $new_pathname);
  }

=pod

=item $rv = $dirh->is_root;

Return true if the current directory is the root directory.

=cut

sub is_root
  {
    my $self = shift;

    return $self->{_pathname} eq "/";
  }

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
    confess unless $filename;
    confess if $filename =~ /\//;
    confess if $filename eq "..";
    confess if $filename eq ".";

    my $pathname = $self->{_pathname} . $filename;
    lstat $pathname;

    if (-d _)
      {
	return Net::FTPServer::DirHandle->new ($self->{ftps}, $pathname."/");
      }

    if (-e _)
      {
	return Net::FTPServer::FileHandle->new ($self->{ftps}, $pathname);
      }

    return undef;
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
	$wildcard =~ s,([^?*a-zA-Z0-9]),\\$1,g; # Escape punctuation.
	$wildcard =~ s,\*,.*,g;	# Turn * into .*
	$wildcard =~ s,\?,.,g;	# Turn ? into .
	$wildcard = "^$wildcard\$"; # Bracket it.
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
	    ? Net::FTPServer::DirHandle->new ($self->{ftps}, $self->{_pathname} . $file)
	    : Net::FTPServer::FileHandle->new ($self->{ftps}, $self->{_pathname} . $file);

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

=item $rv = $dirh->delete;

Delete the current directory. If the delete command was
successful, then return 0, else if there was an error return -1.

It is normally only possible to delete a directory if it
is empty.

=cut

sub delete
  {
    my $self = shift;

    rmdir $self->{_pathname} or return -1;

    return 0;
  }

=item $rv = $dirh->mkdir ($name);

Create a subdirectory called C<$name> within the current directory
C<$dirh>.

=cut

sub mkdir
  {
    my $self = shift;
    my $name = shift;

    die if $name =~ /\//;	# Should never happen.

    mkdir $self->{_pathname} . $name, 0755 or return -1;

    return 0;
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

    return new IO::File $self->{_pathname} . $filename, $mode;
  }

=pod

=item $rv = $fileh->can_write;

Return true if the current user can write into the current
directory (ie. create files, rename files, delete files, etc.).

=cut

sub can_write
  {
    my $self = shift;

    return -w $self->{_pathname};
  }

=pod

=item $rv = $fileh->can_delete;

Return true if the current user can delete the current
directory.

=cut

sub can_delete
  {
    my $self = shift;

    return 0 if $self->is_root;

    return $self->parent->can_write;
  }

=pod

=item $rv = $fileh->can_enter;

Return true if the current user can enter the current
directory.

=cut

sub can_enter
  {
    my $self = shift;

    return -x $self->{_pathname};
  }

=pod

=item $rv = $fileh->can_list;

Return true if the current user can list the current
directory.

=cut

sub can_list
  {
    my $self = shift;

    return -r $self->{_pathname};
  }

=pod

=item $rv = $fileh->can_rename;

Return true if the current user can rename the current
directory.

=cut

sub can_rename
  {
    my $self = shift;

    return $self->parent->can_write;
  }

=pod

=item $rv = $fileh->can_mkdir;

Return true if the current user can create subdirectories of the
current directory.

=cut

sub can_mkdir
  {
    my $self = shift;

    return -w $self->{_pathname};
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
