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

Net::FTPServer::HTTP::Mapper - Map GET resource to a URI.

=head1 SYNOPSIS

  use Net::FTPServer::HTTP::Mapper;

=head1 DESCRIPTION

Tries to transpose an FTP GET request to the desired HTTP URI.
The mapping logic is governed by pathToHttp() and will almost always need
to be overridden.

The default implementation of pathToHttp() requires the following user-defined config:

=over 

=item B<http_server_scheme>
    
    e.g. http

=item B<http_server>

    e.g. domain.com

=item B<http_server_port>

    e.g. 81

=back

Based on the above config, a GET request for I<abc.jpg> means that an image located
on B<http://domain.com:81/abc.jpg> will be delivered.

Paths built using CWD are not mapped to URI's by default i.e. files are supported but
hierarchical directories are not.

To do this Net::FTPServer::HTTP::DirHandle::get needs to be modified to support virtual paths-
as Net::FTPServer::InMem::DirHandle::get does.

=head1 METHODS

=over 4

=cut

package Net::FTPServer::HTTP::Mapper;

sub new { return bless $_[1], $_[0] }

sub pathToHttp {
    my ($self, $resource) = @_;
    return unless $resource;

    my $scheme = $self->config('http_server_scheme') || 'http';
    my $server = $self->config('http_server') || q{};
    my $port = $self->config('http_server_port') || 80;
    return unless $server;

    $server =~ s|//|/|g;
    return "$scheme://$server:$port/$resource";
}

sub config {return $_[0]->{_ftps}->config($_[1]) || q{}}

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

L<Net::FTPServer(3)>, L<perl(1)>

=cut

