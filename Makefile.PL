# $Id: Makefile.PL,v 1.9 2000/09/14 10:11:07 rich Exp $
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

use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME => "Net::FTPServer",
	      VERSION_FROM => "lib/Net/FTPServer.pm",

	      PREREQ_PM =>
	      {
	       Authen::PAM => 0,
	       BSD::Resource => 0,
	       Carp => 0,
	       Digest::MD5 => 0,
	       Getopt::Long => 0,
	       IO::Dir => 0,
	       #IO::File => 0,
	       IO::Socket => 0,
	       POSIX => 0,
	       Socket => 0,
	       Sys::Hostname => 0,
	       Sys::Syslog => 0,
	      },

	      dist =>
	      {
	       COMPRESS => 'gzip --force --best',
	       PREOP => 'cp Net-FTPServer.spec $(DISTVNAME)',
	      },

	      clean =>
	      {
	       FILES => '*.bak *~',
	      },

	      realclean =>
	      {
	       FILES => 'Net-FTPServer.spec',
	      },

	      depend =>
	      {
	       dist => 'Net-FTPServer.spec',
	       #'Net-FTPServer.spec' => '$(VERSION_FROM)',
	       #Makefile => '$(VERSION_FROM)',
	      },
	     );

package MY;

sub libscan
  {
    my ($self, $path) = @_;
    ($path =~ /\~$/) ? undef : $path;
  }

__END__
