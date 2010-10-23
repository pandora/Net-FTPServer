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

Net::FTPServer::HTTP::DirHandle - Get files via HTTP

=head1 SYNOPSIS

  use Net::FTPServer::HTTP::DirHandle;

=head1 DESCRIPTION

=head1 METHODS

=over 4

=cut

package Net::FTPServer::HTTP::DirHandle;

use strict;

use vars qw($VERSION);
( $VERSION ) = '$Revision: 1.1 $ ' =~ /\$Revision:\s+([^\s]+)/;


use Carp qw(confess croak);
use IO::Scalar;
use LWP::UserAgent;

use Net::FTPServer::DirHandle;
use Net::FTPServer::HTTP::Mapper;

use vars qw(@ISA);

@ISA = qw(Net::FTPServer::DirHandle);

# Global variables.
use vars qw(%dirs $next_dir_id %files $next_file_id);

# The initial directory structure.
$next_dir_id = 2;
$dirs{1} = { name => "", parent => 0 };
$next_file_id = 1;

# Return a new directory handle.

sub new
  {
    my $class = shift;
    my $ftps = shift;		# FTP server object.
    my $pathname = shift || "/"; # (only used in internal calls)
    my $dir_id = shift;		# (only used in internal calls)

    # Create object.
    my $self = Net::FTPServer::DirHandle->new ($ftps, $pathname);
    bless $self, $class;

    if ($dir_id)
      {
	$self->{fs_dir_id} = $dir_id;
      }
    else
      {
	$self->{fs_dir_id} = 1;
      }

    return $self;
  }

# Return a subdirectory handle or a file handle within this directory.

sub get {
    my $self = shift;
    my $filename = shift;

    $self->{_mapper} ||= Net::FTPServer::HTTP::Mapper->new({_ftps => $self->{ftps}});
    $self->{_ua} ||= LWP::UserAgent->new;

    # None of these cases should ever happen.
    confess "no filename" unless defined($filename) && length($filename);
    confess "slash filename" if $filename =~ /\//;
    confess ".. filename"    if $filename eq "..";
    confess ". filename"     if $filename eq ".";

    my $url = $self->{_mapper}->pathToHttp($filename);
    return unless $url;

    my $response = $self->{_ua}->get($url);
    if(length $response->content && $response->content_type =~ m|^image|) {
            if ($response->is_success) {
                    my $content = $response->decoded_content;
                    # Does the file exists on the web server ?
                    return new Net::FTPServer::HTTP::FileHandle (
                            $self->{ftps},
                            $self->pathname . $filename,
                            $self->{fs_dir_id},
                            time,
                            \$content,
                    );
            }
    }
    return;
}

sub parent { }
sub list { }
sub list_status { }
sub move { }
sub delete { }
sub mkdir { }

sub status 
  {
    my $self = shift;
    my $username = substr $self->{ftps}{user}, 0, 8;

    return ( 'd', 0755, 1, $username, "users", 1024, 0 );
  }


sub open
  {
    my $self = shift;
    my $filename = shift;
    my $mode = shift;

    if ($mode eq "r")		# Open an existing file for reading.
      {
	foreach (keys %files)
	  {
	    if ($files{$_}{dir_id} == $self->{fs_dir_id} &&
		$files{$_}{name} eq $filename)
	      {
		return new IO::Scalar ($files{$_}{content});
	      }
	  }

	return undef;
      }
    elsif ($mode eq "w")	# Create/overwrite the file.
      {
	# If a file with the same name exists already, erase it.
	foreach (keys %files)
	  {
	    if ($files{$_}{dir_id} == $self->{fs_dir_id} &&
		$files{$_}{name} eq $filename)
	      {
		delete $files{$_};
		last;
	      }
	  }

	my $content = "";

	$files{$next_file_id++} = { dir_id => $self->{fs_dir_id},
				    name => $filename,
				    content => \$content };

	return new IO::Scalar (\$content);
      }
    elsif ($mode eq "a")	# Append to the file.
      {
	foreach (keys %files)
	  {
	    if ($files{$_}{dir_id} == $self->{fs_dir_id} &&
		$files{$_}{name} eq $filename)
	      {
		return new IO::Scalar ($files{$_}{content});
	      }
	  }

	return undef;
      }
    else
      {
	croak "unknown file mode: $mode; use 'r', 'w' or 'a' instead";
      }
  }

1

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
