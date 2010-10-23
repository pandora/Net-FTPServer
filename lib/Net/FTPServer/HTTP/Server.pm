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

=pod

=head1 NAME

Net::FTPServer::HTTP::Server - Get files via HTTP

=head1 SYNOPSIS

  http-ftpd [-d] [-v] [-p port] [-s] [-S] [-V] [-C conf_file]

=head1 DESCRIPTION

C<Net::FTPServer::HTTP::Server> implements a simple
FTP server which gets files from a remote location over HTTP.

FTP -> HTTP mapping is handled by C<Net::FTPServer::HTTP::Mapper>

=head1 METHODS

=over 4

=cut

package Net::FTPServer::HTTP::Server;

use strict;

use vars qw($VERSION);
( $VERSION ) = '$Revision: 1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;

use Net::FTPServer::HTTP::FileHandle;
use Net::FTPServer::HTTP::DirHandle;

use base 'Net::FTPServer::Full::Server';

# This is called before configuration.

sub pre_configuration_hook
  {
    my $self = shift;

    $self->{version_string} .= " Net::FTPServer::HTTP/$VERSION";
  }

=pod

=item $dirh = $self->root_directory_hook;

Hook: Return an instance of Net::FTPServer::FullDirHandle
corresponding to the root directory.

=cut

sub root_directory_hook {
    my $self = shift;
    return new Net::FTPServer::HTTP::DirHandle ($self);
}

1;

__END__

=back 4

=head1 AUTHORS

Richard Jones (rich@annexia.org).

Anastasi Thomas (athomas@cpan.org)

=head1 COPYRIGHT

Copyright (C) 2000 Biblio@Tech Ltd., Unit 2-3, 50 Carnwath Road,
London, SW6 3EG, UK

=head1 SEE ALSO

L<Net::FTPServer(3)>.

=cut
