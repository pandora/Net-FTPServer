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

# $Id: FileHandle.pm,v 1.7 2000/09/12 12:50:55 rich Exp $

=pod

=head1 NAME

Net::FTPServer::FileHandle - A Net::FTPServer file handle.

=head1 SYNOPSIS

  use Net::FTPServer::FileHandle;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=cut

package Net::FTPServer::FileHandle;

use strict;

# Some magic which is required by CPAN. This is not the real version
# number. If you want that, have a look at FTPServer::VERSION.
use vars qw($VERSION);
$VERSION = '1.0';

use Net::FTPServer::Handle;

use vars qw(@ISA);

@ISA = qw(Net::FTPServer::Handle);

# This function is intentionally undocumented. It is only meant to
# be called internally.

sub new
  {
    my $class = shift;
    my $ftps = shift;
    my $path = shift;

    my $self = Net::FTPServer::Handle->new ($ftps);
    $self->{_pathname} = $path;

    return bless $self, $class;
  }

=pod

=item $filename = $fileh->filename;

Return the filename (last) component.

=cut

sub filename
  {
    my $self = shift;

    if ($self->{_pathname} =~ m,([^/]*)$,)
      {
	return $1;
      }

    die "incorrect pathname: ", $self->{_pathname};
  }

=pod

=item $dirh = $fileh->dir;

Return the directory which contains this file.

=cut

sub dir
  {
    my $self = shift;

    my $dirname = $self->{_pathname};
    $dirname =~ s,[^/]+$,,;

    return Net::FTPServer::DirHandle->new ($self->{ftps}, $dirname);
  }

=pod

=item $fh = $fileh->open (["r"|"w"|"a"]);

Open a file handle (derived from C<IO::Handle>, see
L<IO::Handle(3)>) in either read or write mode.

=cut

sub open
  {
    my $self = shift;
    my $mode = shift;

    return new IO::File $self->{_pathname}, $mode;
  }

=item $rv = $fileh->delete;

Delete the current file. If the delete command was
successful, then return 0, else if there was an error return -1.

=cut

sub delete
  {
    my $self = shift;

    unlink $self->{_pathname} or return -1;

    return 0;
  }

=pod

=item $rv = $fileh->can_read;

Return true if the current user can read the given file.

=cut

sub can_read
  {
    my $self = shift;

    return -r $self->{_pathname};
  }

=pod

=item $rv = $fileh->can_write;

Return true if the current user can overwrite the given file.

=cut

sub can_write
  {
    my $self = shift;

    return -w $self->{_pathname};
  }

=pod

=item $rv = $fileh->can_append

Return true if the current user can append to the given file.

=cut

sub can_append
  {
    my $self = shift;

    return -w $self->{_pathname};
  }

=pod

=item $rv = $fileh->can_rename;

Return true if the current user can change the name of the given file.

=cut

sub can_rename
  {
    my $self = shift;

    return $self->dir->can_write;
  }

=pod

=item $rv = $fileh->can_delete;

Return true if the current user can delete the given file.

=cut

sub can_delete
  {
    my $self = shift;

    return $self->dir->can_write;
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
