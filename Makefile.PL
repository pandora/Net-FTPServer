# $Id: Makefile.PL,v 1.7 2001/07/24 09:54:35 rich Exp $
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

# PREREQ_PM is crap! It doesn't enforce the prerequisites, and
# doesn't print an intelligible error message. Nor does it understand
# that some modules are optional, while others are absolutely
# required. Do our own prerequisite checking here. A lot of this
# code was borrowed from the Makefile.PL supplied with libwww-perl.
#
# NB. 'status' field is either 'required', for modules which are
# required, or anything else for modules which are optional.

my %modules
  = (
     'Authen::PAM' =>
     { status => "recommended",
       version => "0.12",
       message =>
       "Authen::PAM is missing. This module is required in order to\n".
       "perform user authentication against the full FTP server\n".
       "personality on most Unix platforms. Therefore unless you install\n".
       "this module, normal FTP server configurations will most likely\n".
       "not work.\n"
     },
     'BSD::Resource' =>
     { status => "highly recommended",
       message =>
       "BSD::Resource is missing. This module is required in order to\n".
       "place limits on the size of the FTP server process. Without this\n".
       "module, the FTP server will still work, but it will be vulnerable\n".
       "to certain sorts of denial of service (DoS) attacks.\n"
     },
     'Carp' => { status => "required" },
     'DBI' =>
     { status => "optional",
       message =>
       "DBI is missing. This module is required to run the test suite,\n".
       "and also if you want to run the FTP server against a PostgreSQL\n".
       "database.\n"
     },
     'Digest::MD5' =>
     { status => "optional",
       message =>
       "Digest::MD5 is missing. This module is required in order for the\n".
       "SITE CHECKSUM command to work.\n"
     },
     'Fcntl' => { status => "required" },
     'Getopt::Long' => { status => "required" },
     'IO::Dir' => { status => "required", package => "IO" },
     'IO::File' => { status => "required", package => "IO" },
     'IO::Handle' => { status => "required", package => "IO" },
     'IO::Scalar' => { status => "required", package => "IO-stringy",
		       version => "1.126" },
     'IO::Socket' => { status => "required", package => "IO" },
     'POSIX' => { status => "required" },
     'Socket' => { status => "required" },
     'Sys::Hostname' => { status => "required" },
     'Sys::Syslog' => { status => "required" },
    );

$| = 1;

# Check for modules.

my $missing_modules = 0;
my $missing_required_modules = 0;

foreach (sort keys %modules)
  {
    print "Checking for $modules{$_}{status} ";
    print "module $_ ";
    print ">= $modules{$_}{version} " if $modules{$_}{version};
    print "... ";

    my $eval = "require $_; ";
    $eval .= "$_->VERSION >= $modules{$_}{version}" if $modules{$_}{version};

    my $r = eval $eval;
    if ($@ || !$r)
      {
	$missing_modules++;
	$missing_required_modules++ if $modules{$_}{status} eq "required";

	print "not found.\n\n";

	if (exists $modules{$_}{package})
	  {
	    print
	      "This module is provided by the $modules{$_}{package} ",
	      "package.\n\n";
	  }

	sleep 1;

	if (exists $modules{$_}{message})
	  {
	    print "*** ", $modules{$_}{message}, "\n";
	    sleep 5;
	  }

      }
    else
      {
	print "ok.\n";
      }
  }

print "\n";

if ($missing_modules)
  {
    print <<EOT;
Obtain missing modules from CPAN [http://www.cpan.org/].

EOT
    sleep 2;
  }

if ($missing_required_modules)
  {
    print <<EOT;
Required modules are missing. Install these first.

EOT
    exit 1;
  }

WriteMakefile(
	      NAME => "Net::FTPServer",
	      VERSION_FROM => "lib/Net/FTPServer.pm",

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
