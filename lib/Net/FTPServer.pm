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

# $Id: FTPServer.pm,v 1.33 2001/02/22 15:46:12 rich Exp $

=pod

=head1 NAME

Net::FTPServer - A secure, extensible and configurable Perl FTP server

=head1 SYNOPSIS

  ftpd [--help] [-d] [-v] [-p port] [-s] [-S] [-V] [-C conf_file] [-P pidfile]

=head1 DESCRIPTION

C<Net::FTPServer> is a secure, extensible and configurable FTP
server written in Perl.

Current features include:

 * Authenticated FTP access.
 * Anonymous FTP access.
 * Complete implementation of current RFCs.
 * ASCII or binary type file transfers.
 * Active or passive mode file transfers.
 * Run standalone or from inetd(8).
 * Security features: chroot, resource limits, tainting,
   protection against buffer overflows.
 * IP-based and/or IP-less virtual hosts.
 * Complete access control system.
 * Anonymous read-only FTP personality.
 * Virtual filesystem allows files to be served
   from a database.
 * Directory aliases and CDPATH support.
 * Extensible command set.

=head1 INSTALLING AND RUNNING THE SERVER

A standard C<ftpd.conf> file is supplied with the server.
You should study the comments in the file and edit it to
your satisfaction, and then copy it to C</etc/ftpd.conf>.

  cp ftpd.conf /etc/
  chown root.root /etc/ftpd.conf
  chmod 0755 /etc/ftpd.conf

Two start-up scripts are supplied with the ftp server,
to run it in two common configurations: either as a full
FTP server or as an anonymous-only read-only FTP server. The
scripts are C<ftpd> and C<ro-ftpd>. You may need to
edit these scripts if Perl is not stored in the standard
place on your system (the default path is C</usr/bin/perl>).

You should copy the appropriate script, either C<ftpd> or
C<ro-ftpd> to a suitable place (for example: C</usr/sbin/in.ftpd>).

  cp ftpd /usr/sbin/in.ftpd
  chown root.root /usr/sbin/in.ftpd
  chmod 0755 /usr/sbin/in.ftpd

=head2 STANDALONE SERVER

If you have a high load site, you will want to run C<Net::FTPServer>
as a standalone server. To start C<Net::FTPServer> as a standalone
server, do:

  /usr/sbin/in.ftpd -S

You may want to add this to your local start-up files so that
the server starts automatically when you boot the machine.

To stop the server, do:

  killall in.ftpd

=head2 RUNNING FROM INETD

Add the following line to C</etc/inetd.conf>:

  ftp stream tcp nowait root /usr/sbin/tcpd in.ftpd

(This assumes that you have the C<tcpd> package installed
to provide basic access control through C</etc/hosts.allow>
and C</etc/hosts.deny>. This access control is in addition
to any access control which you may configure through
C</etc/ftpd.conf>.)

After editing this file you will need to inform C<inetd>:

  killall -HUP inetd

=head1 COMMAND LINE FLAGS

  --help       Display help and exit
  -d, -v       Enable debugging
  -p PORT      Listen on port PORT instead of the default port
  -s           Run in daemon mode (default: run from inetd)
  -S           Run in background and in daemon mode
  -V           Show version information and exit
  -C CONF      Use CONF as configuration file (default: /etc/ftpd.conf)
  -P PIDFILE   Save pid into PIDFILE (daemon mode only)
  --test       Test mode (used only in automatic testing scripts)

=head1 CONFIGURING AND EXTENDING THE SERVER

C<Net::FTPServer> can be configured and extended in a number
of different ways.

Firstly, almost all common server configuration can be carried
out by editing the configuration file C</etc/ftpd.conf>.

Secondly, commands can be loaded into the server at run-time
to provide custom extensions to the common FTP command set.
These custom commands are written in Perl.

Thirdly, one of several different supplied I<personalities> can be
chosen. Personalities can be used to make deep changes to the FTP
server: for example, there is a supplied personality which allows the
FTP server to serve files from a relational database. By subclassing
C<Net::FTPServer>, C<Net::FTPServer::DirHandle> and
C<Net::FTPServer::FileHandle> you may also write your own
personalities.

The next sections talk about each of these possibilities in turn.

=head2 EDITING /etc/ftpd.conf

A standard C</etc/ftpd.conf> file is supplied with 
C<Net::FTPServer> in the distribution. This contains
all possible configurable options, information about
them and defaults. You should consult the comments in
this file for authoritative information.

=head2 LOADING CUSTOMIZED SITE COMMANDS

It is very simple to write custom SITE commands. These
commands are available to users when they type "SITE XYZ"
in a command line FTP client or when they define a custom
SITE command in their graphical FTP client.

SITE commands are unregulated by RFCs. You may define any commands and
give them any names and any function you wish. However, over time
various standard SITE commands have been recognized and implemented
in many FTP servers. C<Net::FTPServer> also implements these. They
are:

  SITE VERSION      Display the server software version.
  SITE EXEC         Execute a shell command on the server (in
                    C<Net::FTPServer> this is disabled by default!)
  SITE ALIAS        Display chdir aliases.
  SITE CDPATH       Display chdir paths.
  SITE CHECKMETHOD  Implement checksums.
  SITE CHECKSUM
  SITE IDLE         Get or set the idle timeout.

The following commands are found in C<wu-ftpd>, but not currently
implemented by C<Net::FTPServer>: SITE CHMOD, SITE GPASS, SITE GROUP,
SITE GROUPS, SITE INDEX, SITE MINFO, SITE NEWER, SITE UMASK.

So when you are choosing a name for a SITE command, it is probably
best not to choose one of the above names, unless you are specifically
implementing or overriding that command.

Custom SITE commands have to be written in Perl. However, there
is very little you need to understand in order to write these
commands -- you will only need a basic knowledge of Perl scripting.

As our first example, we will implement a C<SITE README> command.
This command just prints out some standard information.

Firstly create a file called C</usr/local/lib/site_readme.pl> (you
may choose a different path if you want). The file should contain:

  sub {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (200,
                  "This is the README file for mysite.example.com.",
                  "Mirrors are contained in /pub/mirrors directory.",
                  "       :       :       :       :       :",
                  "End of the README file.");
  }

Edit C</etc/ftpd.conf> and add the following command:

site command: readme /usr/local/lib/site_readme.pl

and restart the FTP server (check your system log [/var/log/messages]
for any syntax errors or other problems). Here is an example of a
user running the SITE README command:

  ftp> quote help site
  214-The following commands are recognized:
  214-    ALIAS   CHECKMETHOD     EXEC    README
  214-    CDPATH  CHECKSUM        IDLE    VERSION
  214 You can also use HELP to list general commands.
  ftp> site readme
  200-This is the README file for mysite.example.com.
  200-Mirrors are contained in /pub/mirrors directory.
  200-       :       :       :       :       :
  200 End of the README file.

Our second example demonstrates how to use parameters
(the C<$rest> argument). This is the C<SITE ECHO> command.

  sub {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Split the parameters up.
    my @params = split /\s+/, $rest;

    # Quote each parameter.
    my $reply = join ", ", map { "'$_'" } @params;

    $self->reply (200, "You said: $reply");
  }

Here is the C<SITE ECHO> command in use:

  ftp> quote help site
  214-The following commands are recognized:
  214-    ALIAS   CHECKMETHOD     ECHO    IDLE
  214-    CDPATH  CHECKSUM        EXEC    VERSION
  214 You can also use HELP to list general commands.
  ftp> site echo hello how are you?
  200 You said: 'hello', 'how', 'are', 'you?'

Our third example is more complex and shows how to interact
with the virtual filesystem (VFS). The C<SITE SHOW> command
will be used to list text files directly (the user normally
has to download the file and view it locally). Hence
C<SITE SHOW readme.txt> should print the contents of the
C<readme.txt> file in the local directory (if it exists).

All file accesses B<must> be done through the VFS, not
by directly accessing the disk. If you follow this convention
then your commands will be secure and will work correctly
with different back-end personalities (in particular when
``files'' are really blobs in a relational database).

  sub {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Get the file handle.
    my ($dirh, $fileh, $filename) = $self->_get ($rest);

    # File doesn't exist or not accessible. Return an error.
    unless ($fileh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Check it's a simple file.
    my ($mode) = $fileh->status;

    unless ($mode eq "f")
      {
	$self->reply (550,
		      "SITE SHOW command is only supported on plain files.");
	return;
      }

    # Try to open the file.
    my $file = $fileh->open ("r");

    unless ($file)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Copy data into memory.
    my @lines = ();

    while ($_ = $file->getline)
      {
	# Remove any native line endings.
	s/[\n\r]+$//;

	push @lines, $_;
      }

    # Close the file handle.
    $file->close;

    # Send the file back to the user.
    $self->reply (200, "File $filename:", @lines, "End of file.");
  }

This code is not quite complete. A better implementation would
also check the "retrieve rule" (so that people couldnE<39>t
use C<SITE SHOW> in order to get around access control limitations
which the server administrator has put in place). It would also
check the file more closely to make sure it was a text file and
would refuse to list very large files.

Here is an example (abbreviated) of a user using the
C<SITE SHOW> command:

  ftp> site show README
  200-File README:
  200-$Id: FTPServer.pm,v 1.33 2001/02/22 15:46:12 rich Exp $
  200-
  200-Net::FTPServer - A secure, extensible and configurable Perl FTP server.
  [...]
  200-To contact the author, please email: Richard Jones <rich@annexia.org>
  200 End of file.

=head2 STANDARD PERSONALITIES

Currently C<Net::FTPServer> is supplied with three standard
personalities. These are:

  Full    The complete read/write anonymous/authenticated FTP
          server which serves files from a standard Unix filesystem.

  RO      A small read-only anonymous-only FTP server similar
          in functionality to Dan Bernstein's publicfile
          program.

  DBeg1   An example FTP server which serves files to a PostgreSQL
          database. This supports files and hierarchical
          directories, multiple users (but not file permissions)
          and file upload.

The standard B<Full> personality will not be explained here.

The B<RO> personality is the Full personality with all code
related to writing files, creating directories, deleting, etc.
removed. The RO personality also only permits anonymous
logins and does not contain any code to do ordinary
authentication. It is therefore safe to use the RO
personality where you are only interested in serving
files to anonymous users and do not want to worry about
crackers discovering a way to trick the FTP server into
writing over a file.

The B<DBeg1> personality is a complete read/write
FTP server which stores files as BLOBs (Binary Large
OBjects) in a PostgreSQL relational database. The
personality supports file download and upload and
contains code to authenticate users against a C<users>
table in the database (database ``users'' are thus
completely unrelated to real Unix users). The
B<DBeg1> is intended only as an example. It does
not support advanced features such as file
permissions and quotas. As part of the schoolmaster.net
project Bibliotech Ltd. have developed an even more
advanced database personality which supports users,
groups, access control lists, quotas, recursive
moves and copies and many other features. However this
database personality is not available as source.

To use the DBeg1 personality you must first run a
PostgreSQL server (version 6.4 or above) and ensure
that you have access to it from your local user account.
Use the C<initdb>, C<createdb> and C<createuser>
commands to create the appropriate user account and
database (please consult the PostgreSQL administrators
manual for further information about this -- I do
not answer questions about basic PostgreSQL knowledge).

Here is my correctly set up PostgreSQL server, accessed
from my local user account ``rich'':

  cruiser:~$ psql
  Welcome to the POSTGRESQL interactive sql monitor:
    Please read the file COPYRIGHT for copyright terms of POSTGRESQL

     type \? for help on slash commands
     type \q to quit
     type \g or terminate with semicolon to execute query
   You are currently connected to the database: rich

  rich=> \d
  Couldn't find any tables, sequences or indices!

You will also need the following Perl modules installed:
DBI, DBD::Pg.

Now you will need to create a database called ``ftp'' and
populate it with data. This is how to do this:

  createdb ftp
  psql ftp < doc/eg1.sql

Check that no ERRORs are reported by PostgreSQL.

You should now be able to start the FTP server by running
the following command (I<not> as root):

  ./dbeg1-ftpd -S -p 2000 -C ftpd.conf

If the FTP server doesnE<39>t start correctly, you should
check the system log file [/var/log/messages].

Connect to the FTP server as follows:

  ftp localhost 2000

Log in as either rich/123456 or dan/123456 and then try
to move around, upload and download files, create and
delete directories, etc.

=head2 SUBCLASSING THE Net::FTPServer CLASSES

By subclassing C<Net::FTPServer>, C<Net::FTPServer::DirHandle> and/or
C<Net::FTPServer::FileHandle> you can create custom
personalities for the FTP server.

Typically by overriding the hooks in the C<Net::FTPServer> class
you can change the basic behaviour of the FTP server - turning
it into an anonymous read-only server, for example.

By overriding the hooks in C<Net::FTPServer::DirHandle> and
C<Net::FTPServer::FileHandle> you can create virtual filesystems:
serving files into and out of a database, for example.

The current manual page contains information about the
hooks in C<Net::FTPServer> which may be overridden.

See L<Net::FTPServer::DirHandle(3)> for information about
the methods in C<Net::FTPServer::DirHandle> which may be
overridden.

See L<Net::FTPServer::FileHandle(3)> for information about
the methods in C<Net::FTPServer::FileHandle> which may be
overridden.

The most reasonable way to create your own personality is
to extend one of the existing personalities. Choose the
one which most closely matches the personality that you
want to create. For example, suppose that you want to create
another database personality. A good place to start would
be by copying C<lib/Net/FTPServer/DBeg1/*.pm> to a new
directory C<lib/Net/FTPServer/MyDB/> (for example). Now
edit these files and substitute "MyDB" for "DBeg1". Then
examine each subroutine in these files and modify them,
consulting the appropriate manual page if you need to.

=head2 VIRTUAL HOSTS

C<Net:FTPServer> is capable of hosting multiple FTP sites on
a single machine. Because of the nature of the FTP protocol,
virtual hosting is almost always done by allocating a single
separate IP address per FTP site. However, C<Net::FTPServer>
also supports an experimental IP-less virtual hosting
system, although this requires modifications to the client.

Normal (IP-based) virtual hosting is carried out as follows:

 * For each FTP site, allocate a separate IP address.
 * Configure IP aliasing on your normal interface so that
   the single physical interface responds to multiple
   virtual IP addresses.
 * Add entries (A records) in DNS mapping each site's
   name to a separate IP address.
 * Add reverse entries (PTR records) in DNS mapping each
   IP address back to the site hostname. It is important
   that both forward and reverse DNS is set up correctly,
   else virtual hosting may not work.
 * In /etc/ftpd.conf you will need to add a virtual host
   section for each site like this:

     <Host sitename>

       ip: 1.2.3.4
       ... any specific configuration options for this site ...

     </Host>

   You don't in fact need the "ip:" part assuming that
   your forward and reverse DNS are set up correctly.
 * If you want to specify a lot of external sites, or
   generate the configuration file automatically from a
   database or a script, you may find the <Include filename>
   syntax useful.

There are examples in C</etc/ftpd.conf>. Here is how
IP-based virtual hosting works:

 * The server starts by listening on all interfaces.
 * A connection arrives at one of the IP addresses and a
   process is forked off.
 * The child process finds out which interface the
   client connected to and reverses the name.
 * If:
     the IP address matches one of the "ip:" declarations
     in any of the "Host" sections, 
   or:
     there is a reversal for the name, and the name
     matches one of the "Host" sections in the configuration
     file,
   then:
     configuration options are read from that
     section of the file and override any global configuration
     options specified elsewhere in the file.
 * Otherwise, the global configuration options only
   are used.

IP-less virtual hosting is an experimental feature. It
requires the client to send a C<HOST> command very early
on in the command stream -- before C<USER> and C<PASS>. The
C<HOST> command explicitly gives the hostname that the
FTP client is attempting to connect to, and so allows
many FTP sites to be multiplexed onto a single IP
address. At the present time, I am not aware of I<any>
FTP clients which implement the C<HOST> command, although
they will undoubtedly become more common in future.

This is how to set up IP-less virtual hosting:

 * Add entries (A or CNAME records) in DNS mapping the
   name of each site to a single IP address.
 * In /etc/ftpd.conf you will need to list the same single
   IP address to which all your sites map:

     virtual host multiplex: 1.2.3.4

 * In /etc/ftpd.conf you will need to add a virtual host
   section for each site like this:

     <Host sitename>

       ... any specific configuration options for this site ...

     </Host>

Here is how IP-less virtual hosting works:

 * The server starts by listening on one interface.
 * A connection arrives at the IP address and a
   process is forked off.
 * The IP address matches "virtual host multiplex"
   and so no IP-based virtual host processing is done.
 * One of the first commands that the client sends is
   "HOST" followed by the hostname of the site.
 * If there is a matching "Host" section in the
   configuration file, then configuration options are
   read from that section of the file and override any
   global configuration options specified elsewhere in
   the file.
 * If there is no matching "Host" section then the
   global configuration options alone are used.

The client is not permitted to issue the C<HOST> command
more than once, and is not permitted to issue it after
login.

=head2 VIRTUAL HOSTING AND SECURITY

Only certain configuration options are available inside
the E<lt>HostE<gt> sections of the configuration file.
Generally speaking, the only configuration options you
can put here are ones which take effect after the
site name has been determined -- hence "allow anonymous"
is OK (since itE<39>s an option which is parsed after
determining the site name and during log in), but
"port" is not (since it is parsed long before any
clients ever connect).

Make sure your default global configuration is
secure. If you are using IP-less virtual hosting,
this is particularly important, since if the client
never sends a C<HOST> command, the client gets
the global configuration. Even with IP-based virtual
hosting it may be possible for clients to sometimes
get the global configuration, for example if your
local name server fails.

IP-based virtual hosting always takes precedence
above IP-less virtual hosting.

With IP-less virtual hosting, access control cannot
be performed on a per-site basis. This is because the
client has to issue commands (ie. the C<HOST> command
at least) before the site name is known to the server.
However you may still have a global "access control rule".

=head1 METHODS

=over 4

=cut

package Net::FTPServer;

use strict;

use vars qw($VERSION $RELEASE);

$VERSION = '1.0.0';
$RELEASE = 3;

use Config;
use Getopt::Long qw(GetOptions);
use Sys::Hostname;
use Sys::Syslog qw(:DEFAULT setlogsock);
use Socket;
use IO::Socket;
use IO::File;
use BSD::Resource;
use Carp;
use Digest::MD5;
use POSIX qw(setsid dup2 ceil strftime);
use Fcntl qw(F_SETOWN);

use Net::FTPServer::FileHandle;
use Net::FTPServer::DirHandle;

use vars qw(@_default_commands
	    @_default_site_commands
	    @_supported_mlst_facts
	    $_default_timeout);

@_default_commands
  = (
     # Standard commands from RFC 959.
     "USER", "PASS", "ACCT", "CWD", "CDUP", "SMNT",
     "REIN", "QUIT", "PORT", "PASV", "TYPE", "STRU",
     "MODE", "RETR", "STOR", "STOU", "APPE", "ALLO",
     "REST", "RNFR", "RNTO", "ABOR", "DELE", "RMD",
     "MKD", "PWD", "LIST", "NLST", "SITE", "SYST",
     "STAT", "HELP", "NOOP",
     # RFC 1123 section 4.1.3.1 recommends implementing these.
     "XMKD", "XRMD", "XPWD", "XCUP", "XCWD",
     # From RFC 2389.
     "FEAT", "OPTS",
     # From ftpexts Internet Draft.
     "SIZE", "MDTM", "MLST", "MLSD",
     # Mail handling commands from obsolete RFC 765.
     "MLFL", "MAIL", "MSND", "MSOM", "MSAM", "MRSQ",
     "MRCP",
     # I18N support from RFC 2640.
     "LANG",
     # NcFTP sends the CLNT command, I know not from what RFC.
     "CLNT",
     # Experimental IP-less virtual hosting.
     "HOST",
    );

@_default_site_commands
  = (
     # Common extensions.
     "EXEC", "VERSION",
     # Wu-FTPD compatible extensions.
     "ALIAS", "CDPATH", "CHECKMETHOD", "CHECKSUM",
     "IDLE",
    );

@_supported_mlst_facts
  = (
     "TYPE", "SIZE", "MODIFY", "PERM", "UNIX.MODE"
    );

$_default_timeout = 900;

=pod

=item Net::FTPServer->run ([\@ARGV]);

This is the main entry point into the FTP server. It starts the
FTP server running. This function never normally returns.

If no arguments are given, then command line arguments are taken
from the global C<@ARGV> array.

=cut

sub run
  {
    my $class = shift;
    my $args = shift || \@ARGV;

    # Clean up the environment to allow tainting to work.
    $ENV{PATH} = "/usr/bin:/bin";
    $ENV{SHELL} = "/bin/sh";
    delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

    # Create Net::FTPServer object.
    my $self = {};
    bless $self, $class;

    # Construct version string.
    $self->{version_string}
    = "Net::FTPServer/" .
      $Net::FTPServer::VERSION . "-" .
      $Net::FTPServer::RELEASE;

    # Save the hostname.
    $self->{hostname} = hostname;

    # Construct a table of commands to subroutines.
    $self->{command_table} = {};
    foreach (@_default_commands) {
      my $subname = "_${_}_command";
      $self->{command_table}{$_} = \&$subname;
    }

    # Construct a list of SITE commands.
    $self->{site_command_table} = {};
    foreach (@_default_site_commands) {
      my $subname = "_SITE_${_}_command";
      $self->{site_command_table}{$_} = \&$subname;
    }

    # Construct a list of supported features (for FEAT command).
    $self->{features} = {
			 SIZE => undef,
			 REST => "STREAM",
			 MDTM => undef,
			 TVFS => undef,
			 UTF8 => undef,
			 MLST => join ("",
				       map { "$_*;" } @_supported_mlst_facts),
			 LANG => "EN*",
			 HOST => undef,
			};

    # Construct a list of supported options (for OPTS command).
    $self->{options} = {
			MLST => \&_OPTS_MLST_command,
		       };

    $self->pre_configuration_hook;

    # Global configuration.
    $self->{debug} = 0;
    $self->{_config_file} = "/etc/ftpd.conf";

    $self->options_hook ($args);
    $self->_get_configuration ($args);

    $self->post_configuration_hook;

    # Open syslog.
    if (defined $self->config ("log socket type")) {
      setlogsock $self->config ("log socket type")
    } else {
      setlogsock "unix";
    }

    openlog "ftpd", "pid", "daemon";
    syslog "info", "%s running", $self->{version_string};

    # Set up a hook for warn and die so that these cause messages to
    # be echoed to the syslog.
    $SIG{__WARN__} = sub {
      syslog "warning", $_[0];
      warn $_[0];
    };
    $SIG{__DIE__} = sub {
      syslog "err", $_[0];
      die $_[0];
    };

    # Set up signal handlers to give us a clean exit.
    # XXX Are these inherited?
    $SIG{PIPE} = sub {
      syslog "info", "client closed connection abruptly";
      exit;
    };
    $SIG{TERM} = sub {
      syslog "info", "exiting on TERM signal";
      $self->reply (421, "Manual shutdown from server");
      $self->_log_line ("[TERM RECEIVED]");
      exit;
    };
    $SIG{INT} = sub {
      syslog "info", "exiting on keyboard INT signal";
      exit;
    };
    $SIG{QUIT} = sub {
      syslog "info", "exiting on keyboard QUIT signal";
      exit;
    };
    $SIG{HUP} = sub {
      syslog "info", "exiting on HUP signal";
      exit;
    };
    $SIG{ALRM} = sub {
      syslog "info", "exiting on ALRM signal";
      print "421 Server closed the connection after idle timeout.\r\n";
      $self->_log_line ("[TIMED OUT!]");
      exit;
    };
    $SIG{URG} = sub {
      $self->{_urgent} = 1;
    };

    # Setup Client Logging.
    if (defined $self->config ("client logging"))
      {
	my $log_file = $self->config ("client logging");

	# Swap $VARIABLE with corresponding attribute (i.e., $hostname)
	$log_file =~ s/\$(\w+)/$self->{$1}/g;
	my $io = new IO::File $log_file, "a";
	if (defined $io)
	  {
	    $io->autoflush (1);
	    $self->{client_log} = $io;
	  }
	else
	  {
	    die "cannot append: $log_file: $!";
	  }
      }

    # Load customized SITE commands.
    my @custom_site_commands = $self->config ("site command");
    foreach (@custom_site_commands)
      {
	my ($cmdname, $filename) = split /\s+/, $_;
	my $sub = do $filename;
	if ($sub)
	  {
	    if (ref $sub eq "CODE") {
	      $self->{site_command_table}{uc $cmdname} = $sub;
	    } else {
	      syslog "err", "site command: $filename: must return an anonymous subroutine when evaluated (skipping)";
	    }
	  }
	else
	  {
	    if ($!) {
	      syslog "err", "site command: $filename: $! (ignored)"
	    } else {
	      syslog "err", "site command: $filename: $@ (ignored)"
	    }
	  }
      }

    # Daemon mode?
    if (defined $self->{_args_daemon_mode}
	? $self->{_args_daemon_mode}
	: $self->config ("daemon mode"))
      {
	# Fork into the background?
	if (defined $self->{_args_run_in_background}
	    ? $self->{_args_run_in_background}
	    : $self->config ("run in background"))
	  {
	    $self->_fork_into_background;
	  }

	$self->_save_pid;

	local $SIG{TERM} = sub {
	  syslog "info", "shutting down daemon";
	  $self->_log_line ("[DAEMON Shutdown]");
	  exit;
	};

	# Run as a daemon.
	$self->_be_daemon;
      }

    $| = 1;

    # Hook just after accepting the connection.
    $self->post_accept_hook;

    # Get the sockname of the socket so we know which interface
    # the client is bound to.
    my ($sockname, $sockport, $sockaddr, $sockaddrstring);

    unless ($self->{_test_mode})
      {
	$sockname = getsockname STDIN;
	if (!defined $sockname)
	  {
	    $self->reply(500, "inet mode requires a socket - use '$0 -S' for standalone.");
	    exit;
	  }
	($sockport, $sockaddr) = unpack_sockaddr_in ($sockname);
	$sockaddrstring = inet_ntoa ($sockaddr);

	# Added 21 Feb 2001 by Rob Brown <rbrown@about-inc.com>
	# If MSG_OOB data arrives on STDIN send it inline and trigger SIGURG
	setsockopt (STDIN, SOL_SOCKET, SO_OOBINLINE, pack ("l",1))
	  or warn "setsockopt: SO_OOBINLINE: $!";
	STDIN->fcntl (F_SETOWN, $$);
      }

    # Virtual hosts.
    my $sitename;

    if ($self->config ("enable virtual hosts"))
      {
	my $virtual_host_multiplex = $self->config ("virtual host multiplex");

	# IP-based virtual hosting?
	unless ($virtual_host_multiplex &&
		$virtual_host_multiplex eq $sockaddrstring)
	  {
	    # Look for a matching "ip:" configuration option in
	    # a <Host> section.
	    $sitename = $self->ip_host_config ($sockaddrstring);

	    unless ($sitename)
	      {
		# Try reversing the IP address in DNS instead.
		$sitename = gethostbyaddr ($sockaddr, AF_INET);
	      }

	    if ($self->{debug})
	      {
		if ($sitename)
		  {
		    syslog "info",
		           "IP-based virtual hosts: set site to $sitename";
		  }
		else
		  {
		    syslog "info",
		           "IP-based virtual hosts: no site found";
		  }
	      }
	  }
      }

    # Get the peername and other details of this socket.
    my ($peername, $peerport, $peeraddr, $peeraddrstring);

    unless ($self->{_test_mode})
      {
	$peername = getpeername STDIN;
	($peerport, $peeraddr) = unpack_sockaddr_in ($peername);
	$peeraddrstring = inet_ntoa ($peeraddr);
        $self->_log_line ("[CONNECTION FROM $peeraddrstring:$peerport]");
      }

    # Resolve the address.
    my $peerhostname;
    if ($self->config ("resolve addresses"))
      {
	my $hostname = gethostbyaddr ($peeraddr, AF_INET);

	if ($hostname)
	  {
	    my $ipaddr = gethostbyname ($hostname);

	    if ($ipaddr && inet_ntoa ($ipaddr) eq $peeraddrstring)
	      {
		$peerhostname = $hostname;
	      }
	  }

	if ($self->config ("require resolved addresses") && !$peerhostname)
	  {
	    syslog "err",
	    "cannot resolve address for connection from " .
	    "$peeraddrstring:$peerport";
	    exit 0;
	  }
      }

    # Set up request information.
    $self->{sockname} = $sockname;
    $self->{sockport} = $sockport;
    $self->{sockaddr} = $sockaddr;
    $self->{sockaddrstring} = $sockaddrstring;
    $self->{sitename} = $sitename;
    $self->{peername} = $peername;
    $self->{peerport} = $peerport;
    $self->{peeraddr} = $peeraddr;
    $self->{peeraddrstring} = $peeraddrstring;
    $self->{peerhostname} = $peerhostname;
    $self->{authenticated} = 0;
    $self->{loginattempts} = 0;

    # Default port information, used if no PORT command is issued. This
    # is used by the open_data_connection function. See RFC 959 section 3.2.
    $self->{_hostport} = $peerport;
    $self->{_hostaddr} = $peeraddr;
    $self->{_hostaddrstring} = $peeraddrstring;

    # Default mode is active. Issuing the PASV command switches the
    # server into passive mode.
    $self->{_passive} = 0;

    # Set up default connection state.
    $self->{type} = 'A';
    $self->{form} = 'N';
    $self->{mode} = 'S';
    $self->{stru} = 'F';

    # Other per-connection state.
    $self->{_mlst_facts} = \@_supported_mlst_facts;
    $self->{_checksum_method} = "MD5";
    $self->{_idle_timeout} = $self->config ("timeout") || $_default_timeout;
    $self->{maintainer_email}
    = defined $self->config ("maintainer email") ?
      $self->config ("maintainer email") :
      "root\@$self->{hostname}";
    $self->{_chdir_message_cache} = {};

    my $r = $self->access_control_hook;
    exit if $r == -1;

    # Perform normal access control.
    if ($r == 0)
      {
	unless ($self->_eval_rule ("access control rule"))
	  {
	    $self->reply (421, "Client denied by server configuration. Goodbye.");
	    exit;
	  }
      }

    # Install per-process limits.
    $r = $self->process_limits_hook;
    exit if $r == -1;

    # Perform normal per-process limits.
    if ($r == 0)
      {
	my $limits = get_rlimits ();

	#warn "limits = ", join (", ", keys %$limits);

	if (exists $limits->{RLIMIT_DATA}) {
	  my $limit = 1024 * ($self->config ("limit memory") || 8192);
	  setrlimit (RLIMIT_DATA, $limit, $limit)
	    or die "setrlimit: $!";
	}

	if (exists $limits->{RLIMIT_NPROC}) {
	  my $limit = $self->config ("limit nr processes") || 5;
	  setrlimit (RLIMIT_NPROC, $limit, $limit)
	    or die "setrlimit: $!";
	}

	if (exists $limits->{RLIMIT_NOFILE}) {
	  my $limit = $self->config ("limit nr files") || 20;
	  setrlimit (RLIMIT_NOFILE, $limit, $limit)
	    or die "setrlimit: $!";
	}
      }

    unless ($self->{_test_mode})
      {
	# Log the connection information available.
	my $peerinfodpy
	  = $peerhostname ?
	    "$peerhostname:$peerport ($peeraddrstring:$peerport)" :
	    "$peeraddrstring:$peerport";

	syslog "info", "connection from $peerinfodpy";

	# Change name of process in process listing.
	unless (defined $self->config ("change process name") &&
		!$self->config ("change process name"))
	  {
	    $0 = "ftpd $peerinfodpy";
	  }
      }

    # Send the greeting.
    my $greeting_type = $self->config ("greeting type") || "full";

    if ($greeting_type eq "full")
      {
	$self->reply (220, "$self->{hostname} FTP server ($self->{version_string}) ready.");
      }
    elsif ($greeting_type eq "brief")
      {
	$self->reply (220, "$self->{hostname} FTP server ready.");
      }
    elsif ($greeting_type eq "terse")
      {
	$self->reply (220, "FTP server ready.");
      }
    elsif ($greeting_type eq "text")
      {
	my $greeting_text = $self->config ("greeting text")
	  or die "greeting type is text, but no greeting text configuration value";
	$self->reply (220, $greeting_text);
      }
    else
      {
	die "unknown greeting type: ${greeting_type}";
      }

    # Get command filter, if set.
    my $cmd_filter = $self->config ("command filter");

    # Command the commands permitted when not authenticated.
    my %no_authentication_commands = ();

    if (defined $self->config ("no authentication commands"))
      {
	my @c = split /\s+/, $self->config ("no authentication commands");

	foreach (@c) { $no_authentication_commands{$_} = 1; }
      }
    else
      {
	%no_authentication_commands =
	  ("USER" => 1, "PASS" => 1, "LANG" => 1, "FEAT" => 1,
	   "HELP" => 1, "QUIT" => 1, "HOST" => 1);
      }

    # Start reading commands from the client.
    for (;;)
      {
	# Pre-command hook.
	$self->pre_command_hook;

	# Set an alarm to go off after so many seconds of idleness.
	alarm $self->{_idle_timeout};

	# Get next line of input from the client.
	# XXX This does not comply properly with RFC 2640 section 3.1 -
	# We should translate <CR><NUL> to <CR> and treat ONLY <CR><LF>
	# as a line ending character.
	last unless defined ($_ = <STDIN>);
        $self->_log_line ($_);

	# Restart alarm clock timer.
	alarm $self->{_idle_timeout};

	# When out-of-band data arrives (eg. when the client performs
	# an ABOR command), the client will send several telnet control
	# characters before the actual command. Drop those bytes now.
	s/^\377.// while m/^\377./;

	# Go slow?
	sleep $self->config ("command wait")
	  if $self->config ("command wait");

	# Remove trailing CRLF.
	s/[\n\r]+$//;

	# Command filter hook.
	$r = $self->command_filter_hook ($_);
	next if $r == -1;

	# Command filter.
	if ($r == 0 && defined $cmd_filter)
	  {
	    unless ($_ =~ m/$cmd_filter/)
	      {
		$self->reply (421, "Command does not match command filter.");
		exit 0;
	      }
	  }

	# Get the command.
	# See also RFC 2640 section 3.1.
	unless (m/^([A-Z]{3,4})\s?(.*)/i)
	  {
	    syslog "err",
	    "badly formed command received: %s", _escape($_);
            $self->_log_line ("[Badly formed command]", _escape($_));
	    exit 0;
	  }

	my ($cmd, $rest) = (uc $1, $2);

	syslog "info", "command: (%s, %s)",
	  _escape($cmd), _escape($rest)
	  if $self->{debug};

	# Command requires user to be authenticated?
	unless ($self->{authenticated} ||
		exists $no_authentication_commands{$cmd})
	  {
	    $self->reply (530, "Not logged in.");
	    next;
	  }

	# Got a command which matches in the table?
	unless (exists $self->{command_table}{$cmd})
	  {
	    $self->reply (500, "Unrecognized command.");
	    syslog "err", "unknown command received: %s", _escape($_);
	    next;
	  }

	# Run the command.
	&{$self->{command_table}{$cmd}} ($self, $cmd, $rest);

	# Post-command hook.
	$self->post_command_hook;
      }

    $self->_log_line ("[ENDED BY CLIENT $self->{peeraddrstring}:$self->{peerport}]");
    syslog "info", "connection terminated normally";
  }

# Added 21 Feb 2001 by Rob Brown <rbrown@about-inc.com>
# Client command logging
sub _log_line
  {
    my $self = shift;
    return unless exists $self->{client_log};
    my $message = join ("",@_);
    my $io = $self->{client_log};
    my $time = scalar localtime;
    my $authenticated = $self->{authenticated} ? "*" : "-";
    $message =~ s/\n*$/\n/;
    $io->print ("[$time][$$:$authenticated]$message");
  }

# Added 08 Feb 2001 by Rob Brown <rbrown@about-inc.com>
# Safely saves the process id to the specified pidfile.
# If no pidfile is specified, nothing happens.
sub _save_pid
  {
    my $self = shift;
    # Store pid into pidfile?
    $self->{_pidfile} =
      (defined $self->{_args_pidfile}
       ? $self->{_args_pidfile}
       : $self->config ("pidfile"));
    if (defined $self->{_pidfile})
      {
        my $pidfile = $self->{_pidfile};
        if ($pidfile =~ m%^([/\w\-\.]+)$%)
          {
            open (PID, ">$1")
              or die "cannot write $pidfile: $!";
            print PID "$$\n";
            close PID;
            eval "END {unlink('$1') if \$\$ == $$;}";
          } else {
            die "Refusing to create weird looking pidfile: $pidfile";
          }
      }
  }

# This subroutine loads the command line options and configuration file
# and resolves conflicts. Command line options have priority over
# certain things in the configuration file.

sub _get_configuration
  {
    my $self = shift;
    my $args = shift;
    local @ARGV = @$args;

    my ($debug, $help, $show_version);

    Getopt::Long::Configure ("no_ignore_case");

    GetOptions ("d+" => \$debug,
		"v+" => \$debug,
		"help|?" => \$help,
		"p=i" => \$self->{_args_ctrl_port},
		"s" => \$self->{_args_daemon_mode},
		"S" => \$self->{_args_run_in_background},
                "P=s" => \$self->{_args_pidfile},
		"V" => \$show_version,
		"C=s" => \$self->{_config_file},
		"test" => \$self->{_test_mode});

    # Show version and exit?
    if ($show_version)
      {
	print $self->{version_string}, "\n";
	exit 0;
      }

    # Show help and exit?
    if ($help)
      {
	print "ftpd [--help] [-d] [-v] [-p port] [-s] [-S] [-V] [-C conf_file] [-P pidfile]\n";
	exit 0;
      }

    # Run in background implies daemon mode.
    $self->{_args_daemon_mode} = 1
      if defined $self->{_args_run_in_background};

    # Read the configuration file.
    $self->{_config} = {};
    $self->{_config_ip_host} = {};
    $self->_open_config_file ($self->{_config_file});

    # Set debugging state.
    if (defined $debug) {
      $self->{debug} = 1
    } elsif (defined $self->config ("debug")) {
      $self->{debug} = $self->config ("debug")
    }
  }

# Fork into the background (command line -S option).

sub _fork_into_background
  {
    my $self = shift;

    my $pid = fork;
    die "fork: $!" unless defined $pid;

    # Parent process ends here.
    exit if $pid > 0;

    # Start a new session.
    setsid;

    # Close connection to tty and reopen 0, 1, 2 as /dev/null.
    # XXX Doesn't work. I've tried several variations on this
    # but haven't managed to make it work.
#    POSIX::close (0);
#    POSIX::close (1);
#    POSIX::close (2);
#    POSIX::open ("/dev/null", O_CREAT|O_EXCL|O_WRONLY, 0644);
#    POSIX::open ("/dev/null", O_CREAT|O_EXCL|O_WRONLY, 0644);
#    POSIX::open ("/dev/null", O_CREAT|O_EXCL|O_WRONLY, 0644);

    syslog "info", "forked into background";
  }

# Be a daemon (command line -s option).

sub _be_daemon
  {
    my $self = shift;

    syslog "info", "operating in daemon mode";
    $self->_log_line ("[DAEMON Started]");

    # Discover the default FTP port from /etc/services or equivalent.
    my $default_port = getservbyname "ftp", "tcp" || 21;

    # Construct argument list to socket.
    my @args = (Reuse => 1,
		Proto => "tcp",
		Type => SOCK_STREAM,
		LocalPort =>
		defined $self->{_args_ctrl_port}
		? $self->{_args_ctrl_port}
		: (defined $self->config ("port")
		   ? $self->config ("port")
		   : $default_port));

    # Get length of listen queue.
    if (defined $self->config ("listen queue")) {
      push @args, Listen => $self->config ("listen queue")
    } else {
      push @args, Listen => 10
    }

    # Get the local bind address.
    if (defined $self->config ("local address")) {
      push @args, LocalAddr => $self->config ("local address")
    }

    # Open a socket on the control port.
    $self->{_ctrl_sock} =
      IO::Socket::INET->new (@args)
	or die "socket: $!";

    # Set TCP keepalive?
    if (defined $self->config ("tcp keepalive"))
      {
	$self->{_ctrl_sock}->sockopt (SO_KEEPALIVE, 1)
	  or warn "setsockopt: SO_KEEPALIVE: $!";
      }

    $self->post_bind_hook;

    # Automatically clean up zombie children.
    if ($Config{osname} !~ /solaris/) {
      $SIG{CHLD} = sub { wait };
    } else {
      $SIG{CHLD} = "IGNORE";
    }

    # Accept new connections and fork off new process to handle it.
    for (;;)
      {
	$self->pre_accept_hook;

	# ACCEPT may be undefined if, for example, the TCP-level 3-way
	# handshake is not completed. If this happens, all we really want
	# to do is to retry the accept, not die. Thanks to
	# rbrown@about-inc.com for pointing this one out :-)

	my $sock;

	until (defined $sock)
	  {
	    $sock = $self->{_ctrl_sock}->accept;
	    warn "accept: $!" unless defined $sock;
	  }

	# Fork off a process to handle this connection.
	my $pid = fork;
	if (defined $pid)
	  {
	    if ($pid == 0)		# Child process.
	      {
		syslog "info", "starting child process" if $self->{debug};

		# Duplicate the socket so it looks like we were called
		# from inetd.
		dup2 ($sock->fileno, 0);
		dup2 ($sock->fileno, 1);

		# Return to the main process to handle the rest of
		# the connection.
		return;
	      }			# End of child process.
	  }
	else			# Error during fork(2).
	  {
	    warn "fork: $!";
	    sleep 5;		# Back off in case system is overloaded.
	  }
      }				# End of for (;;) loop in ftpd parent process.
  }

# Open configuration file and prepare to read configuration.

sub _open_config_file
  {
    my $self = shift;
    my $config_file = shift;

    my $config = new IO::File "<$config_file";
    unless ($config)
      {
	die "cannot open configuration file: $config_file: $!";
      }

    my $lineno = 0;
    my $sitename;

    # Read in the configuration options from the file.
    while ($_ = $config->getline)
      {
	$lineno++;

	# Remove trailing \n and \r.
	s/[\n\r]+$//;

	# Ignore blank lines and comments.
	next if /^\s*\#/;
	next if /^\s*$/;

	# More lines?
	while (/\\$/)
	  {
	    $_ .= $config->getline;
	    $lineno++;
	  }

	# Special treatment: <Include> files.
	if (/^\s*<Include\s+(.*)>\s*$/i)
	  {
	    $self->_open_config_file ($1);
	    next;
	  }

	# Special treatment: <Host> sections.
	if (/^\s*<Host\s+(.*)>\s*$/i)
	  {
	    if ($sitename)
	      {
		die "$config_file:$lineno: unfinished <Host> section";
	      }

	    $sitename = $1;
	    next;
	  }

	if (/^\s*<\/Host>\s*$/i)
	  {
	    unless ($sitename)
	      {
		die "$config_file:$lineno: unmatched </Host>";
	      }

	    $sitename = undef;
	    next;
	  }

	# Split the line on the first : character.
	unless (/^(.*?):(.*)$/)
	  {
	    die "$config_file:$lineno: syntax error in configuration file";
	  }

	my $key = $1;
	my $value = $2;

	$key =~ s/^\s+//;
	$key =~ s/\s+$//;

	$value =~ s/^\s+//;
	$value =~ s/\s+$//;

	# Convert the key to standard form so that small errors in the
	# FTP config file won't matter too much.
	$key = lc ($key);
	$key =~ tr/ / /s;

	# If the key is ``ip:'' then we treat it specially - adding it
	# to a hash from IP addresses to sites.
	if ($key eq "ip")
	  {
	    $self->{_config_ip_host}{$value} = $sitename;
	  }

	# Prefix the sitename, if defined.
	$key = "$sitename:$key" if $sitename;

	# Save this.
	$self->{_config}{$key} = [] unless exists $self->{_config}{$key};
	push @{$self->{_config}{$key}}, $value;
      }
  }

# Before printing something received from the user to syslog, escape
# any strange characters using this function.

sub _escape
  {
    local $_ = shift;
    s/([^ -~])/sprintf ("\\x%02x", ord ($1))/ge;
    $_;
  }

=pod

=item $ftps->reply ($code, $line, [$line, ...])

This function sends a standard single line or multi-line FTP
server reply to the client. The C<$code> should be one of the
standard reply codes listed in RFC 959. The one or more
C<$line> arguments are the (free text) of the reply. Do
I<not> include carriage returns at the end of each C<$line>.
This function adds the correct line ending format as specified
in the RFC.

=cut

sub reply
  {
    my $self = shift;

    my $code = shift;
    die "response code $code is not in RFC 959 format"
      unless $code =~ /^[1-5][0-5][0-9]$/;

    die "reply must contain one or more lines of text"
      unless @_ > 0;

    if (@_ == 1)		# Single-line response.
      {
	print $code, " ", $_[0], "\r\n";
      }
    else			# Multi-line response.
      {
	for (my $i = 0; $i < @_-1; ++$i)
	  {
	    print $code, "-", $_[$i], "\r\n";
	  }
	print $code, " ", $_[@_-1], "\r\n";
      }

    syslog "info", "reply: $code" if $self->{debug};
  }

=pod

=item $ftps->config ($name);

Read configuration option C<$name> from the configuration file.

=cut

sub config
  {
    my $self = shift;
    my $key = shift;

    # Convert the key to standard form.
    $key = lc ($key);
    $key =~ tr/ / /s;

    # Try site-specific configuration option.
    if ($self->{sitename} &&
	exists $self->{_config}{"$self->{sitename}:$key"})
      {
	unless (wantarray)
	  {
	    # Return scalar value, but warn if there are many values
	    # for this configuration operation.
	    if (@{$self->{_config}{"$self->{sitename}:$key"}} > 1)
	      {
		warn "called config in scalar context for an array valued key: $key";
	      }

	    return $self->{_config}{"$self->{sitename}:$key"}[0];
	  }
	else
	  {
	    return @{$self->{_config}{"$self->{sitename}:$key"}};
	  }
      }

    # Try global configuration option.
    if (exists $self->{_config}{$key})
      {
	unless (wantarray)
	  {
	    # Return scalar value, but warn if there are many values
	    # for this configuration operation.
	    if (@{$self->{_config}{$key}} > 1)
	      {
		warn "called config in scalar context for an array valued key: $key";
	      }

	    return $self->{_config}{$key}[0];
	  }
	else
	  {
	    return @{$self->{_config}{$key}};
	  }
      }

    # Nothing found.
    unless (wantarray) { return undef } else { return () }
  }

=pod

=item $ftps->ip_host_config ($ip_addr);

Look for a E<lt>HostE<gt> section which contains "ip: $ip_addr".
If one is found, return the site name of the Host section. Otherwise
return undef.

=cut

sub ip_host_config
  {
    my $self = shift;
    my $ip_addr = shift;

    if (exists $self->{_config_ip_host}{$ip_addr})
      {
	return $self->{_config_ip_host}{$ip_addr};
      }

    return undef;
  }

sub _HOST_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # HOST with no parameters just prints out the current site name.
    if ($rest eq "")
      {
	if ($self->{sitename}) {
	  $self->reply (200, "HOST is set to $self->{sitename}.");
	} else {
	  $self->reply (200, "HOST is not set.");
	}
	return;
      }

    # The user may only issue HOST before log in.
    if ($self->{authenticated})
      {
	$self->reply (501, "Cannot issue HOST command after logging in.");
	return;
      }

    # You cannot change HOST.
    if ($self->{sitename} && $self->{sitename} ne $rest)
      {
	$self->reply (501, "HOST already set to $self->{sitename}.");
	return;
      }

    # Check that the name is reasonable.
    unless ($rest =~ /^[-a-z0-9.]+$/i)
      {
	$self->reply (501, "HOST syntax error.");
	return;
      }

    # Allow the change.
    $self->{sitename} = $rest;
    $self->reply (200, "HOST set to $self->{sitename}.");
  }

sub _USER_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # If the user issues this command when logged in, generate an error.
    # We have to do this basically because of chroot and setuid stuff we
    # can't ``relogin'' as a different user.
    if ($self->{authenticated})
      {
	$self->reply (503, "You are already logged in.");
	return;
      }

    # Just save the username for now.
    $self->{user} = $rest;

    # Tried to log in anonymously?
    if ($rest eq "ftp" || $rest eq "anonymous")
      {
	unless ($self->config ("allow anonymous"))
	  {
	    $self->reply (421, "Anonymous logins not permitted.");
            $self->_log_line ("[No anonymous allowed]");
	    exit 0;
	  }

	$self->{user_is_anonymous} = 1;
      }

    unless ($self->{user_is_anonymous})
      {
	$self->reply (331, "Username OK, please send password.");
      }
    else
      {
	$self->reply (331, "Anonymous login OK, please send your email address as password.");
      }
  }

sub _PASS_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # If the user issues this command when logged in, generate an error.
    if ($self->{authenticated})
      {
	$self->reply (503, "You are already logged in.");
	return;
      }

    # Have we received a username?
    unless ($self->{user})
      {
	$self->reply (503, "Please send your username first.");
	return;
      }

    # If this is an anonymous login, check that the password conforms.
    my @anon_passwd_warning = ();

    if ($self->{user_is_anonymous})
      {
	my $cktype = $self->config ("anonymous password check") || "none";
	my $enforce = $self->config ("anonymous password enforce") || 0;

	# If the password ends with @, append hostname.
	my $hostname
	  = $self->{peerhostname} ?
	    $self->{peerhostname} :
	    $self->{peeraddrstring};

	$rest .= $hostname if $rest =~ /\@$/;

	if ($cktype ne "none")
	  {
	    my $valid;

	    if ($cktype eq "rfc822")
	      {
		$valid = $self->_anon_passwd_validate_rfc822 ($rest);
	      }
	    elsif ($cktype eq "nobrowser")
	      {
		$valid = $self->_anon_passwd_validate_nobrowser ($rest);
	      }
	    elsif ($cktype eq "trivial")
	      {
		$valid = $self->_anon_passwd_validate_trivial ($rest);
	      }
	    else
	      {
		die "unknown password check type: $cktype";
	      }

	    # Defer the warning until later on in the function.
	    unless ($valid)
	      {
		push @anon_passwd_warning,
		"The response \"$rest\" is not valid.",
		"Please use your email address as your password.",
		"  For example: joe\@$hostname",
		"($hostname will be added if password ends with \@).";
	      }

	    # ... unless we have been told to enforce it now.
	    if ($enforce && !$valid)
	      {
		$self->reply (530, @anon_passwd_warning);
		return;
	      }
	  }
      }

    # OK, now the real authentication check.
    if ($self->authentication_hook ($self->{user}, $rest,
				    $self->{user_is_anonymous}) < 0)
      {
	# See RFC 2577 section 5.
	sleep 5;

	# Login failed.
	$self->{loginattempts}++;

	if ($self->{loginattempts} >=
	    ($self->config ("max login attempts") || 3))
	  {
	    syslog "notice", "repeated login attempts from %s:%d",
	    $self->{peeraddrstring},
	    $self->{peerport};

	    # See RFC 2577 section 5.
	    $self->reply (421, "Too many login attempts. Goodbye.");
            $self->_log_line ("[Max logins reached]");
	    exit 0;
	  }

	$self->reply (530, "Login failed.");
	return;
      }

    # Perform user access control step.
    unless ($self->_eval_rule ("user access control rule"))
      {
	$self->reply (421, "User denied by server configuration. Goodbye.");
        $self->_log_line ("[Client denied]");
	exit;
      }

    # Login was officially OK.
    $self->{authenticated} = 1;

    # Compute home directory. We may need it when we display the
    # welcome message.
    unless ($self->{user_is_anonymous})
      {
	if (defined $self->config ("home directory"))
	  {
	    $self->{home_directory} = $self->config ("home directory");

	    $self->{home_directory} =~ s/%m/(getpwnam $self->{user})[7]/ge;
	    $self->{home_directory} =~ s/%U/$self->{user}/ge;
	    $self->{home_directory} =~ s/%%/%/g;
	  }
	else
	  {
	    $self->{home_directory} = (getpwnam $self->{user})[7];
	  }
      }
    else
      {
	# Anonymous users always get "/" as their home directory.
	$self->{home_directory} = "/";
      }

    # Send a welcome message -- before the chroot since we may
    # need to read a file in the real root.
    my $welcome_type = $self->config ("welcome type") || "normal";

    if ($welcome_type eq "normal")
      {
	if (! $self->{user_is_anonymous})
	  {
	    $self->reply (230,
			  @anon_passwd_warning,
			  "Welcome " . $self->{user} . ".");
	  }
	else
	  {
	    $self->reply (230,
			  @anon_passwd_warning,
			  "Welcome $rest.");
	  }
      }
    elsif ($welcome_type eq "text")
      {
	my $welcome_text = $self->config ("welcome text")
	  or die "welcome type is text, but no welcome text configuration value";

	$welcome_text = $self->_percent_substitutions ($welcome_text);

	$self->reply (230,
		      @anon_passwd_warning,
		      $welcome_text);
      }
    elsif ($welcome_type eq "file")
      {
	my $welcome_file = $self->config ("welcome file")
	  or die "welcome type is file, but no welcome file configuration value";

	my @lines = ();

	local (*FILE);

	if (open FILE, "<$welcome_file")
	  {
	    while (<FILE>) {
	      s/[\n\r]+$//;
	      push @lines, $self->_percent_substitutions ($_);
	    }
	    close FILE;
	  }
	else
	  {
	    @lines = ( "The server administrator has configured a welcome file,",
		       "but the file is missing." );
	  }

	$self->reply (230, @anon_passwd_warning, @lines);
      }
    else
      {
	die "unknown welcome type: $welcome_type";
      }

    # Open /etc/protocols etc., in case we chroot.
    setprotoent 1;
    sethostent 1;
    setnetent 1;
    setservent 1;
    setpwent;
    setgrent;

    # Perform chroot, etc., as required.
    $self->user_login_hook ($self->{user},
			    $self->{user_is_anonymous});

    # Set CWD to /.
    $self->{cwd} = $self->root_directory_hook;

    # Move to home directory.
    my $new_cwd;

    if ($new_cwd = $self->_chdir ($self->{cwd}, $self->{home_directory}))
      {
	$self->{cwd} = $new_cwd;
      }
    else
      {
	syslog "warning", "no home directory for user: $self->{user}";
      }

  }

sub _percent_substitutions
  {
    my $self = shift;
    local $_ = shift;

    # See ftpd.conf file, section on ``welcome text'' for a list of
    # the substitutions available.
    s/%C/$self->{cwd}->pathname/ge;
    s/%E/$self->{maintainer_email}/ge;
    s/%G/gmtime/ge;
    s/%R/$self->{peerhostname} ? $self->{peerhostname} : $self->{peeraddrstring}/ge;
    s/%L/$self->{hostname}/ge;
    s/%m/$self->{home_directory}/ge;
    s/%T/localtime/ge;
    s/%U/$self->{user}/ge;
    s/%u/$self->{user}/ge;
    s/%%/%/g;

    return $_;
  }

sub _anon_passwd_validate_rfc822
  {
    my $self = shift;
    my $pass = shift;

    # RFC 822 section 6.1, ``addr-spec''.
    # But in fact this is not very careful about checking
    # the address. There's probably a Perl library I should
    # be using here ... XXX
    return $pass =~ /^\S+\@\S+\.\S+$/;
  }

sub _anon_passwd_validate_nobrowser
  {
    my $self = shift;
    my $pass = shift;

    return
      $self->_anon_passwd_validate_rfc822 ($pass) &&
      $pass !~ /^mozilla@/ &&
      $pass !~ /^IE[0-9]+User@/ &&
      $pass !~ /^nobody@/;
  }

sub _anon_passwd_validate_trivial
  {
    my $self = shift;
    my $pass = shift;

    return $pass =~ /\@/;
  }

sub _ACCT_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Not likely that the ACCT command will ever be implemented,
    # unless there is some strange login method that needs to be
    # supported.
    $self->reply (500, "Command not implemented.");
  }

sub _CWD_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my $new_cwd;

    # Look relative to the current directory first.
    if ($new_cwd = $self->_chdir ($self->{cwd}, $rest))
      {
	$self->{cwd} = $new_cwd;
	$self->_chdir_message;
	return;
      }

    # Look for an alias called ``$rest''.
    if ($rest !~ /\//)
      {
	my @aliases = $self->config ("alias");

	foreach (@aliases)
	  {
	    my ($name, $dir) = split /\s+/, $_;

	    if ($name eq $rest &&
		($new_cwd = $self->_chdir ($self->{cwd}, $dir)))
	      {
		$self->{cwd} = $new_cwd;
		$self->_chdir_message;
		return;
	      }
	  }
      }

    # Look for a directory on the cdpath.
    if ($self->config ("cdpath"))
      {
	my @cdpath = split /\s+/, $self->config ("cdpath");

	foreach (@cdpath)
	  {
	    if (($new_cwd = $self->_chdir ($self->{cwd}, $_)) &&
		($new_cwd = $self->_chdir ($new_cwd, $rest)))
	      {
		$self->{cwd} = $new_cwd;
		$self->_chdir_message;
		return;
	      }
	  }
      }

    # All change directory methods failed.
    $self->reply (550, "Directory not found.");
  }

sub _CDUP_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    if (my $new_cwd = $self->_chdir ($self->{cwd}, ".."))
      {
	$self->{cwd} = $new_cwd;
	$self->_chdir_message;
      }
    else
      {
	$self->reply (550, "Directory not found.");
      }
  }

# This little function displays the contents of a special
# message file the first time a user visits a directory,
# if this capability has been configured in.

sub _chdir_message
  {
    my $self = shift;

    my $filename = $self->config ("chdir message file");
    my $file;

    if (defined $filename &&
	! exists $self->{_chdir_message_cache}{$self->{cwd}->pathname} &&
	($file = $self->{cwd}->open ($filename, "r")))
      {
	my @lines = ();
	local $_;

	# Read the file into memory and perform % escaping.
	while ($_ = $file->getline)
	  {
	    s/[\n\r]+$//;
	    push @lines, $self->_percent_substitutions ($_);
	  }
	$file->close;

	# Remember that we've visited this directory once in
	# this session.
	$self->{_chdir_message_cache}{$self->{cwd}->pathname} = 1;

	$self->reply (250, @lines, "Changed directory OK.");
      }
    else
      {
	$self->reply (250, "Changed directory OK.");
      }
  }

sub _SMNT_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Not a very useful command.
    $self->reply (500, "Command not implemented.");
  }

sub _REIN_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # This command is not implemented, because we do not allow a
    # user to revoke permissions and relogin (without disconnecting
    # and reconnecting anyway).
    $self->reply (500, "The REIN command is not supported. You must QUIT and reconnect.");
  }

sub _QUIT_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (221, "Goodbye. Service closing connection.");
    syslog "info", "connection terminated normally";

    my $host =
      ! $self->{_test_mode}
      ? "$self->{peeraddrstring}:$self->{peerport}"
      : "";

    $self->_log_line ("[ENDED BY SERVER $host]");
    exit;
  }

sub _PORT_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # The arguments to PORT are a1,a2,a3,a4,p1,p2 where a1 is the
    # most significant part of the address (eg. 127,0,0,1) and
    # p1 is the most significant part of the port.
    unless ($rest =~ /^([1-9][0-9]*|0),([1-9][0-9]*|0),([1-9][0-9]*|0),([1-9][0-9]*|0),([1-9][0-9]*|0),([1-9][0-9]*|0)/)
      {
	$self->reply (501, "Syntax error in PORT command.");
	return;
      }

    my $a1 = $1;
    my $a2 = $2;
    my $a3 = $3;
    my $a4 = $4;
    my $p1 = $5;
    my $p2 = $6;

    # Check host address.
    unless ($a1 > 0 && $a1 < 224 &&
	    $a2 >= 0 && $a2 < 256 &&
	    $a3 >= 0 && $a3 < 256 &&
	    $a4 >= 0 && $a4 < 256)
      {
	$self->reply (501, "Invalid host address.");
	return;
      }

    # Construct host address.
    my $hostaddrstring = "$a1.$a2.$a3.$a4";

    # Are we connecting back to the client?
    unless ($self->config ("allow proxy ftp"))
      {
	if (!$self->{_test_mode} && $hostaddrstring ne $self->{peeraddrstring})
	  {
	    # See RFC 2577 section 3.
	    $self->reply (504, "Proxy FTP is not allowed on this server.");
	    return;
	  }
      }

    # Construct port number.
    my $hostport = $p1 * 256 + $p2;

    # Check port number.
    unless ($hostport > 0 && $hostport < 65536)
      {
	$self->reply (501, "Invalid port number.");
      }

    # Allow connections back to ports < 1024?
    unless ($self->config ("allow connect low port"))
      {
	if ($hostport < 1024)
	  {
	    # See RFC 2577 section 3.
	    $self->reply (504, "This server will not connect back to ports < 1024.");
	    return;
	  }
      }

    $self->{_hostaddrstring} = $hostaddrstring;
    $self->{_hostaddr} = inet_aton ($hostaddrstring);
    $self->{_hostport} = $hostport;
    $self->{_passive} = 0;

    $self->reply (200, "PORT command OK.");
  }

sub _PASV_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Open a listening socket - but don't actually accept on it yet.
    # RFC 2577 section 8 suggests using random local port numbers.
    # In order to make firewall rules on FTP servers more sane, make
    # the range of local port numbers configurable, and default to
    # only opening ports in the range 49152-65535 (see:
    # http://www.isi.edu/in-notes/iana/assignments/port-numbers for
    # rationale).
    my $port_range = $self->config ("passive port range");
    $port_range = "49152-65535" unless defined $port_range;

    my $sock;

    if ($port_range eq "0")
      {
	# Use the standard kernel determined ephemeral port
	# by leaving off LocalPort parameter.
	$sock = IO::Socket::INET->new
	  (Listen => 1,
	   LocalAddr => $self->{sockaddrstring},
	   Reuse => 1,
	   Proto => "tcp",
	   Type => SOCK_STREAM);
      }
    else
      {
	# Parse the $port_range string and assign a port from the
	# range at random.
	my @ranges = split /\s*,\s*/, $port_range;
	my $total_width = 0;
	foreach (@ranges)
	  {
	    my ($min, $max) = split /\s*-\s*/, $_;
	    $_ = [ $min, $max, $max - $min + 1 ];
	    $total_width += $_->[2];
	  }

	# XXX We need to use a secure source of random numbers here, otherwise
	# this is a little bit pointless.
	my $count = 100;

	until (defined $sock || --$count == 0)
	  {
	    my $n = int (rand $total_width);
	    my $port;
	    foreach (@ranges)
	      {
		if ($n < $_->[2])
		  {
		    $port = $_->[0] + $n;
		    last;
		  }
		$n -= $_->[2];
	      }

	    $sock = IO::Socket::INET->new
	      (Listen => 1,
	       LocalAddr => $self->{sockaddrstring},
	       LocalPort => $port,
	       Reuse => 1,
	       Proto => "tcp",
	       Type => SOCK_STREAM);
	  }
      }

    unless ($sock)
      {
	# Return a code 550 here, even though this is not in the RFC. XXX
	$self->reply (550, "Can't open a listening socket.");
	return;
      }

    $self->{_passive} = 1;
    $self->{_passive_sock} = $sock;

    # Get our port number.
    my $sockport = $sock->sockport;

    # Split the port number into high and low components.
    my $p1 = int ($sockport / 256);
    my $p2 = $sockport % 256;

    unless ($self->{_test_mode})
      {
	my $sockaddrstring = $self->{sockaddrstring};

	# We will need to revise this for IPv6 XXX
	die
	  unless $sockaddrstring =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/;

	# Be very precise about this error message, since most clients
	# will have to parse the whole of it.
	$self->reply (227, "Entering Passive Mode ($1,$2,$3,$4,$p1,$p2)");
      }
    else
      {
	# Test mode: connect back to localhost.
	$self->reply (227, "Entering Passive Mode (127,0,0,1,$p1,$p2)");
      }
  }

sub _TYPE_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # See RFC 959 section 5.3.2.
    if ($rest =~ /^([AI])$/i)
      {
	$self->{type} = uc $1;
      }
    elsif ($rest =~ /^([AI])\sN$/i)
      {
	$self->{type} = uc $1;
      }
    elsif ($rest =~ /^L\s8$/i)
      {
	$self->{type} = 'L8';
      }
    else
      {
	$self->reply (504, "This server does not support TYPE $rest.");
	return;
      }

    $self->reply (200, "TYPE changed to $rest.");
  }

sub _STRU_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # See RFC 959 section 5.3.2.
    # Although this defies the RFC, I'm not going to support
    # record or page structure. TOPS-20 didn't really take off
    # as an operating system in the 90s ...
    if ($rest =~ /^F$/i)
      {
	$self->{stru} = 'F';
      }
    else
      {
	$self->reply (504, "This server does not support STRU $rest.");
	return;
      }

    $self->reply (200, "STRU changed to $rest.");
  }

sub _MODE_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # See RFC 959 section 5.3.2.
    if ($rest =~ /^S$/i)
      {
	$self->{mode} = 'S';
      }
    else
      {
	$self->reply (504, "This server does not support MODE $rest.");
	return;
      }

    $self->reply (200, "MODE changed to $rest.");
  }

sub _RETR_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my ($dirh, $fileh, $filename) = $self->_get ($rest);
    my $transfer_hook;

    unless ($fileh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Check access control.
    unless ($self->_eval_rule ("retrieve rule",
			       $fileh->pathname, $filename, $dirh->pathname))
      {
	$self->reply (550, "RETR command denied by server configuration.");
	return;
      }

    # Check it's a simple file.
    my ($mode) = $fileh->status;
    unless ($mode eq "f")
      {
	$self->reply (550, "RETR command is only supported on plain files.");
	return;
      }

    # Try to open the file.
    my $file = $fileh->open ("r");

    unless ($file)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    $self->reply (150,
		  "Opening " .
		  ($self->{type} eq 'A' ? "ASCII mode" : "BINARY mode") .
		  " data connection for file $filename.");

    # Open a path back to the client.
    my $sock = $self->open_data_connection;

    unless ($sock)
      {
	$self->reply (425, "Can't open data connection.");
	return;
      }

    # What mode are we sending this file in?
    unless ($self->{type} eq 'A') # Binary type.
      {
	my ($r, $buffer, $n, $w);

	# Restart the connection from previous point?
	if ($self->{_restart})
	  {
	    $file->sysseek ($self->{_restart}, SEEK_SET);
	    $self->{_restart} = 0;
	  }

	# Copy data.
	while ($r = $file->sysread ($buffer, 65536))
	  {
	    # Restart alarm clock timer.
	    alarm $self->{_idle_timeout};

	    if ($transfer_hook
		= $self->transfer_hook ("r", $file, $sock, \$buffer))
	      {
		$sock->close;
		$file->close;
		$self->reply (426,
			      "File retrieval error: $transfer_hook",
			      "Data connection has been closed.");
		return;
	      }

	    for ($n = 0; $n < $r; )
	      {
		$w = $sock->syswrite ($buffer, $r - $n, $n);

		unless (defined $w)
		  {
		    # There was an error.
		    my $reason = $!;

		    $sock->close;
		    $file->close;
		    $self->reply (426,
				  "File retrieval error: $reason",
				  "Data connection has been closed.");
		    return;
		  }

		$n += $w;
	      }

	    # Transfer aborted by client?
	    if ($self->{_urgent})
	      {
		$self->reply (426, "Transfer aborted. Data connection closed.");
		$self->{_urgent} = 0;
		return;
	      }
	  }

	unless (defined $r)
	  {
	    # There was an error.
	    my $reason = $!;

	    $sock->close;
	    $file->close;
	    $self->reply (426,
			  "File retrieval error: $reason",
			  "Data connection has been closed.");
	    return;
	  }
      }
    else			# ASCII type.
      {
	# Restart the connection from previous point?
	if ($self->{_restart})
	  {
	    for (my $i = 0; $i < $self->{_restart}; ++$i)
	      {
		$file->getc;
	      }
	    $self->{_restart} = 0;
	  }

	# Copy data.
	while ($_ = $file->getline)
	  {
	    # Remove any native line endings.
	    s/[\n\r]+$//;

	    # Restart alarm clock timer.
	    alarm $self->{_idle_timeout};

	    if ($transfer_hook = $self->transfer_hook ("r", $file, $sock, \$_))
	      {
		$sock->close;
		$file->close;
		$self->reply (426,
			      "File retrieval error: $transfer_hook",
			      "Data connection has been closed.");
		return;
	      }

	    # Write the line with telnet-format line endings.
	    $sock->print ("$_\r\n");
	    if ($self->{_urgent})
	      {
		$self->reply (426, "Transfer aborted. Data connection closed.");
		$self->{_urgent} = 0;
		return;
	      }
	  }
      }

    $sock->close;
    $file->close;

    $self->reply (226, "File retrieval complete. Data connection has been closed.");
  }

sub _STOR_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->_store ($rest);
  }

sub _STOU_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->_store ($rest, unique => 1);
  }

sub _APPE_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->_store ($rest, append => 1);
  }

sub _ALLO_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # RFC 959 Section 4.1.3: Treat this as a NOOP. Note that djb
    # recommends replying with 202 here [http://cr.yp.to/ftp/stor.html].
    $self->reply (200, "OK");
  }

sub _REST_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    unless ($rest =~ /^([1-9][0-9]*|0)$/)
      {
	$self->reply (501, "REST command needs a numeric argument.");
	return;
      }

    $self->{_restart} = $1;
    $self->reply (350, "Restarting next transfer at $1.");
  }

sub _RNFR_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my ($dirh, $fileh, $filename) = $self->_get ($rest);

    unless ($fileh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Store the file handle so we can complete the operation.
    $self->{_rename_fileh} = $fileh;

    $self->reply (350, "OK. Send RNTO command to complete rename operation.");
  }

sub _RNTO_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Seen a previous RNFR command?
    unless ($self->{_rename_fileh})
      {
	$self->reply (503, "Send RNFR command first.");
	return;
      }

    # Get the directory name.
    my ($dirh, $fileh, $filename) = $self->_get ($rest);

    # Are we trying to overwrite a previously existing file?
    if (defined $fileh &&
	defined $self->config ("allow rename to overwrite") &&
	! $self->config ("allow rename to overwrite"))
      {
	$self->reply (550, "Cannot rename file.");
	return;
      }

    # Attempt the rename operation.
    if ($self->{_rename_fileh}->move ($dirh, $filename) < 0)
      {
	$self->reply (550, "Cannot rename file.");
	return;
      }

    delete $self->{_rename_fileh};

    $self->reply (250, "File has been renamed.");
  }

sub _ABOR_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (226, "Command aborted successfully.");
  }

# Note that in the current implementation, DELE and RMD are synonyms.
sub _DELE_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my ($dirh, $fileh, $filename) = $self->_get ($rest);

    unless ($fileh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Check access control.
    unless ($self->_eval_rule ("delete rule",
			       $fileh->pathname, $filename, $dirh->pathname))
      {
	$self->reply (550, "DELE command denied by server configuration.");
	return;
      }

    # Attempt to delete the file.
    if ($fileh->delete < 0)
      {
	$self->reply (550, "Cannot delete file.");
	return;
      }

    $self->reply (250, "File has been deleted.");
  }

sub _RMD_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my ($dirh, $fileh, $filename) = $self->_get ($rest);

    unless ($fileh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Check access control.
    unless ($self->_eval_rule ("delete rule",
			       $fileh->pathname, $filename, $dirh->pathname))
      {
	$self->reply (550, "RMD command denied by server configuration.");
	return;
      }

    # Attempt to delete the file.
    if ($fileh->delete < 0)
      {
	$self->reply (550, "Cannot delete file.");
	return;
      }

    $self->reply (250, "File has been deleted.");
  }

sub _MKD_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my ($dirh, $fileh, $filename) = $self->_get ($rest);

    if ($fileh)
      {
	$self->reply (550, "File or directory already exists.");
	return;
      }

    # Access control.
    unless ($self->_eval_rule ("mkdir rule",
			       $dirh->pathname . $filename,
			       $filename, $dirh->pathname))
      {
	$self->reply (550, "MKD command denied by server configuration.");
	return;
      }

    # Try to create a subdirectory with the appropriate filename.
    if ($dirh->mkdir ($filename) < 0)
      {
	$self->reply (550, "Could not create directory.");
	return;
      }

    $self->reply (250, "Directory has been created.");
  }

sub _PWD_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # See RFC 959 Appendix II and draft-ietf-ftpext-mlst-11.txt section 6.2.1.
    my $pathname = $self->{cwd}->pathname;
    $pathname =~ s,/+$,, unless $pathname eq "/";
    $pathname =~ tr,/,/,s;

    $self->reply (257, "\"$pathname\"");
  }

sub _LIST_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # This is something of a hack. Some clients expect a Unix server
    # to respond to flags on the 'ls command line'. Remove these flags
    # and ignore them. This is particularly an issue with ncftp 2.4.3.
    $rest =~ s/^-[a-zA-Z0-9]+\s?//;

    my ($dirh, $wildcard, $fileh, $filename)
      = $self->_list ($rest);

    unless ($dirh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Check access control.
    unless ($self->_eval_rule ("list rule",
			       undef, undef, $dirh->pathname))
      {
	$self->reply (550, "LIST command denied by server configuration.");
	return;
      }

    $self->reply (150, "Opening data connection for file listing.");

    # Open a path back to the client.
    my $sock = $self->open_data_connection;

    unless ($sock)
      {
	$self->reply (425, "Can't open data connection.");
	return;
      }

    # If the path ($rest) contains a directory name, extract it so that
    # we can prefix it to every filename listed. Thanks rbrown@about-inc.com
    # for pointing this problem out.
    my $prefix = (($fileh || $wildcard) && $rest =~ /(.*\/).*/) ? $1 : "";

    # OK, we're either listing a full directory, listing a single
    # file or listing a wildcard.
    if ($fileh)			# Single file in $dirh.
      {
	$self->_list_file ($sock, $fileh, $prefix . $filename);
      }
    else			# Wildcard or full directory $dirh.
      {
	unless ($wildcard)
	  {
	    # Synthesize "total" field.
	    $sock->print ("total 1\r\n");

	    # Synthesize . and .. entries. I suppose that there will
	    # be some FTP clients out there which will get confused if
	    # they don't see these.
	    my @status = ('d', 0777, 2, "root", "root", 4096, 1);
	    $self->_list_file ($sock, undef, ".", \@status);
	    $self->_list_file ($sock, undef, "..", \@status);
	  }

	my $r = $dirh->list_status ($wildcard);

	foreach (@$r)
	  {
	    my $filename = $_->[0];
	    my $handle = $_->[1];
	    my $statusref = $_->[2];

	    $self->_list_file ($sock, $handle, $prefix . $filename, $statusref);
	  }
      }

    $sock->close;

    $self->reply (226, "Listing complete. Data connection has been closed.");
  }

sub _NLST_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # This is something of a hack. Some clients expect a Unix server
    # to respond to flags on the 'ls command line'. Remove these flags
    # and ignore them. This is particularly an issue with ncftp 2.4.3.
    $rest =~ s/^-[a-zA-Z0-9]+\s?//;

    my ($dirh, $wildcard, $fileh, $filename)
      = $self->_list ($rest);

    unless ($dirh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    $self->reply (150, "Opening data connection for file listing.");

    # Open a path back to the client.
    my $sock = $self->open_data_connection;

    unless ($sock)
      {
	$self->reply (425, "Can't open data connection.");
	return;
      }

    # If the path ($rest) contains a directory name, extract it so that
    # we can prefix it to every filename listed. Thanks rbrown@about-inc.com
    # for pointing this problem out.
    my $prefix = (($fileh || $wildcard) && $rest =~ /(.*\/).*/) ? $1 : "";

    # OK, we're either listing a full directory, listing a single
    # file or listing a wildcard.
    if ($fileh)			# Single file in $dirh.
      {
	$sock->print ($prefix . $filename, "\r\n");
      }
    else			# Wildcard or full directory $dirh.
      {
	my $r = $dirh->list ($wildcard);

	foreach (@$r)
	  {
	    my $filename = $_->[0];
	    my $handle = $_->[1];

	    $sock->print ($prefix . $filename, "\r\n");
	  }
      }

    $sock->close;

    $self->reply (226, "Listing complete. Data connection has been closed.");
  }

sub _SITE_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Find the command.
    # See also RFC 2640 section 3.1.
    unless ($rest =~ /^([A-Z]{3,})\s?(.*)/i)
      {
	$self->reply (501, "Syntax error in SITE command.");
	return;
      }

    ($cmd, $rest) = (uc $1, $2);

    # Find the appropriate command and run it.
    unless (exists $self->{site_command_table}{$cmd})
      {
	$self->reply (501, "Unknown SITE command.");
	return;
      }

    &{$self->{site_command_table}{$cmd}} ($self, $cmd, $rest);
  }

sub _SITE_EXEC_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # This command is DISABLED by default.
    unless ($self->config ("allow site exec command"))
      {
	$self->reply (502, "SITE EXEC is disabled at this site.");
	return;
      }

    # Don't allow this command for anonymous users.
    if ($self->{user_is_anonymous})
      {
	$self->reply (502, "SITE EXEC is not permitted for anonymous logins.");
	return;
      }

    # We trust everything the client sends us implicitly. Foolish? Probably.
    $rest = $1 if $rest =~ /(.*)/;

    # Run it and collect the output.
    unless (open OUTPUT, "$rest |")
      {
	$self->reply (451, "Error running command: $!");
	return;
      }

    my @result, ();

    while (<OUTPUT>)
      {
	# Remove trailing \n, \r.
	s/[\n\r]+$//;

	push @result, $_;
      }

    close OUTPUT;

    # Return the result to the client.
    $self->reply (200, "Result from command $rest:", @result);
  }

sub _SITE_VERSION_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my $enabled
      = defined $self->config ("allow site version command")
	? $self->config ("allow site version command") : 1;

    unless ($enabled)
      {
	$self->reply (502, "SITE VERSION is disabled at this site.");
	return;
      }

    # Return the version string.
    $self->reply (200, $self->{version_string});
  }

sub _SITE_ALIAS_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my @aliases = $self->config ("alias");

    # List out all aliases?
    if ($rest eq "")
      {
	$self->reply (214,
		      "The following aliases are defined:",
		      @aliases,
		      "End of alias list.");
	return;
      }

    # Find a particular alias.
    foreach (@aliases)
      {
	my ($name, $dir) = split /\s+/, $_;
	if ($name eq $rest)
	  {
	    $self->reply (214, "$name is an alias for $dir.");
	    return;
	  }
      }

    # No alias found.
    $self->reply (502,
		"Unknown alias $rest. Note that aliases are case sensitive.");
  }

sub _SITE_CDPATH_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my $cdpath = $self->config ("cdpath");

    unless (defined $cdpath)
      {
	$self->reply (502, "No CDPATH is defined in this server.");
	return;
      }

    my @cdpath = split /\s+/, $cdpath;

    $self->reply (214, "The current CDPATH is:", @cdpath, "End of CDPATH.");
  }

sub _SITE_CHECKMETHOD_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $rest = uc $rest;

    if ($rest eq "MD5")
      {
	$self->{_checksum_method} = $rest;
	$self->reply (200, "Checksum method is now: $rest");
      }
    elsif ($rest eq "")
      {
	$self->reply (200, "Checksum method is now: $self->{_checksum_method}");
      }
    else
      {
	$self->reply (500, "Unknown checksum method. I know about MD5.");
      }
  }

sub _SITE_CHECKSUM_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my ($dirh, $fileh, $filename) = $self->_get ($rest);

    unless ($fileh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    my ($mode) = $fileh->status;

    unless ($mode eq 'f')
      {
	$self->reply (550, "SITE CHECKSUM only works on plain files.");
	return;
      }

    my $file = $fileh->open ("r");

    unless ($file)
      {
	$self->reply (550, "File not found.");
	return;
      }

    my $ctx = Digest::MD5->new;
    $ctx->addfile ($file);	# IO::Handles are also filehandle globs.

    $self->reply (200, $ctx->hexdigest . " " . $filename);
  }

sub _SITE_IDLE_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    if ($rest eq "")
      {
	$self->reply (200, "Current idle timeout is $self->{_idle_timeout} seconds.");
	return;
      }

    # As with wu-ftpd, we only allow idle timeouts to be set between
    # 30 seconds and the current maximum set in the configuration file.
    # In test mode, allow the idle timeout to be set to as small as 1
    # second -- useful for testing without having to hang around.
    my $min_timeout = ! $self->{_test_mode} ? 30 : 1;
    my $max_timeout = $self->config ("timeout") || $_default_timeout;

    unless ($rest =~ /^[1-9][0-9]*$/ &&
	    $rest >= $min_timeout && $rest <= $max_timeout)
      {
	$self->reply (500, "Idle timeout must be between $min_timeout and $max_timeout seconds.");
	return;
      }

    $self->{_idle_timeout} = $rest;

    $self->reply (200, "Current idle timeout set to $self->{_idle_timeout} seconds.");
  }

sub _SYST_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (215, "UNIX Type: L8");
  }

sub _SIZE_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my ($dirh, $fileh, $filename) = $self->_get ($rest);

    unless ($fileh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Get the mode, size etc. Remember to check the mode.
    my ($mode, $perms, $nlink, $user, $group, $size, $time)
      = $fileh->status;

    if ($mode ne "f")
      {
	$self->reply (550, "SIZE command is only supported on plain files.");
	return;
      }

    if ($self->{type} eq 'A')
      {
	# ASCII mode: we have to count the characters by hand.
	$size = 0;
	my $file = $fileh->open ("r");
	$size++ while (defined ($file->getc));
	$file->close;
      }

    $self->reply (213, "$size");
  }

sub _STAT_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # STAT is a very strange command. It can either be used to show
    # general internal information about the server in a free format,
    # or else it can be used to list a directory over the control
    # connection. See RFC 959 Section 4.1.3.

    if ($rest eq "")
      {
	# Internal status.
	my %status = ();

	unless (defined $self->config ("allow site version command") &&
		! $self->config ("allow site version command"))
	  {
	    $status{Version} = $self->{version_string};
	  }

	$status{TYPE} = $self->{type};
	$status{MODE} = $self->{mode};
	$status{FORM} = $self->{form};
	$status{STRUcture} = $self->{stru};

	$status{"Data Connection"} = "None"; # XXX

	if ($self->{peeraddrstring} && $self->{peerport})
	  {
	    $status{Client} = "$self->{peeraddrstring}:$self->{peerport}";
	    $status{Client} .= " ($self->{peerhostname}:$self->{peerport})"
	      if $self->{peerhostname};
	  }

	unless ($self->{user_is_anonymous})
	  {
	    $status{User} = $self->{user};
	  }
	else
	  {
	    $status{User} = "anonymous";
	  }

	my @status = map { $_ . ": " . $status{$_} } sort keys %status;

	$self->reply (211, "FTP server status:", @status, "End of status");
      }
    else
      {
	# Act like the LIST command.
	my ($dirh, $wildcard, $fileh, $filename)
	  = $self->_list ($rest);

	unless ($dirh)
	  {
	    $self->reply (550, "File or directory not found.");
	    return;
	  }

	my @lines = ();

	# OK, we're either listing a full directory, listing a single
	# file or listing a wildcard.
	if ($fileh)		# Single file in $dirh.
	  {
	    push @lines, $filename;
	  }
	else			# Wildcard or full directory $dirh.
	  {
	    my $r = $dirh->list_status ($wildcard);

	    foreach (@$r)
	      {
		my $filename = $_->[0];

		push @lines, $filename;
	      }
	  }

	# Send them back to the client.
	$self->reply (213, "Status of $rest:", @lines, "End of status");
      }
  }

sub _HELP_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my @version_info = ();

    # Dan Bernstein recommends sending the server version info here.
    unless (defined $self->config ("allow site version command") &&
	    ! $self->config ("allow site version command"))
      {
	@version_info = ( $self->{version_string} );
      }

    # Without any arguments, return a list of commands supported.
    if ($rest eq "")
      {
	my @lines = _format_list (sort keys %{$self->{command_table}});

	$self->reply (214,
		      @version_info,
		      "The following commands are recognized:",
		      @lines,
		      "You can also use HELP SITE to list site specific commands.");
      }
    # HELP SITE.
    elsif (uc $rest eq "SITE")
      {
	my @lines = _format_list (sort keys %{$self->{site_command_table}});

	$self->reply (214,
		      @version_info,
		      "The following commands are recognized:",
		      @lines,
		      "You can also use HELP to list general commands.");
      }
    # No other form of HELP available right now.
    else
      {
	$self->reply (214,
		      "No command-specific help is available right now. Use HELP or HELP SITE.");
      }
  }

sub _format_list
  {
    my @lines = ();
    my ($r, $c);
    my $rows = int (ceil (@_ / 4.));

    for ($r = 0; $r < $rows; ++$r)
      {
	my @r = ();

	for ($c = 0; $c < 4; ++$c)
	  {
	    my $n = $c * $rows + $r;

	    push @r, $_[$n] if $n < @_;
	  }

	push @lines, "\t" . join "\t", @r;
      }

    return @lines;
  }

sub _NOOP_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (200, "OK");
  }

sub _XMKD_command
  {
    return shift->_MKD_command (@_);
  }

sub _XRMD_command
  {
    return shift->_RMD_command (@_);
  }

sub _XPWD_command
  {
    return shift->_PWD_command (@_);
  }

sub _XCUP_command
  {
    return shift->_CDUP_command (@_);
  }

sub _XCWD_command
  {
    return shift->_CWD_command (@_);
  }

sub _FEAT_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    if ($rest ne "")
      {
	$self->reply (501, "Unexpected parameters to FEAT command.");
	return;
      }

    # Print out the extensions supported. Don't use $self->reply, since
    # it doesn't have the exact guaranteed behaviour (it instead immitates
    # wu-ftpd by putting the server code in each line).
    # 
    # See RFC 2389 section 3.2.
    print "211-Extensions supported:\r\n";

    foreach (sort keys %{$self->{features}})
      {
	unless ($self->{features}{$_})
	  {
	    print " $_\r\n";
	  }
	else
	  {
	    print " $_ ", $self->{features}{$_}, "\r\n";
	  }
      }

    print "211 END\r\n";
  }

sub _OPTS_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # RFC 2389 section 4.
    # See also RFC 2640 section 3.1.
    unless ($rest =~ /^([A-Z]{3,4})\s?(.*)/i)
      {
	$self->reply (501, "Syntax error in OPTS command.");
	return;
      }

    ($cmd, $rest) = (uc $1, $2);

    # Find the appropriate command.
    unless (exists $self->{options}{$cmd})
      {
	$self->reply (501, "Command has no settable options.");
	return;
      }

    # The command should print either a 200 or a 451 reply.
    &{$self->{options}{$cmd}} ($self, $cmd, $rest);
  }

sub _MSAM_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (502, "Obsolete RFC 765 mail commands not implemented.");
  }

sub _MRSQ_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (502, "Obsolete RFC 765 mail commands not implemented.");
  }

sub _MLFL_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (502, "Obsolete RFC 765 mail commands not implemented.");
  }

sub _MRCP_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (502, "Obsolete RFC 765 mail commands not implemented.");
  }

sub _MAIL_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (502, "Obsolete RFC 765 mail commands not implemented.");
  }

sub _MSND_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (502, "Obsolete RFC 765 mail commands not implemented.");
  }

sub _MSOM_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (502, "Obsolete RFC 765 mail commands not implemented.");
  }

sub _LANG_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # The beginnings of language support.
    #
    # XXX To complete language support we need to implement the FEAT
    # command for language properly, put gettext around all strings
    # and also arrange for strings to be translated. See RFC 2640.

    # If no argument, then we want to find the current language.
    if ($rest eq "")
      {
	my $lang = $ENV{LANGUAGE} || "en";
	$self->reply (200, "Language is $lang.");
	return;
      }

    # We limit the whole tag to 8 chars since (a) it's highly unlikely
    # that any genuine language code would be longer than this and
    # (b) there are all sorts of possible libc exploits available if
    # the user is allowed to set this to arbitrary values.
    unless (length ($rest) <= 8 &&
	    $rest =~ /^[A-Z]{1,8}(-[A-Z]{1-8})*$/i)
      {
	$self->reply (504, "Incorrect language.");
	return;
      }

    $ENV{LANGUAGE} = $rest;
    $self->reply (200, "Language changed to $rest.");
  }

sub _CLNT_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # NcFTP sends the CLNT command. I don't know what RFC this
    # comes from.
    $self->reply (200, "Hello $rest.");
  }

sub _MDTM_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my ($dirh, $fileh, $filename) = $self->_get ($rest);

    unless ($fileh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Get the status.
    my ($mode, $perms, $nlink, $user, $group, $size, $time)
      = $fileh->status;

    # Format the modification time. See draft-ietf-ftpext-mlst-11.txt
    # sections 2.3 and 3.1.
    my $fmt_time = strftime "%Y%m%d%H%M%S", gmtime ($time);

    $self->reply (213, $fmt_time);
  }

sub _MLST_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # If not file name is given, then we need to return
    # status on the current directory. Else we return
    # status on the file or directory name given.
    my $fileh = $self->{cwd};
    my $filename = ".";

    if ($rest ne "")
      {
	my $dirh;

	($dirh, $fileh, $filename) = $self->_get ($rest);

	# XXX There is a bug here: "MLST /" fails with 550 error.
	unless ($fileh)
	  {
	    $self->reply (550, "File or directory not found.");
	    return;
	  }
      }

    # Check access control.
    unless ($self->_eval_rule ("list rule",
			       undef, undef, $fileh->dir->pathname))
      {
	$self->reply (550, "LIST command denied by server configuration.");
	return;
      }

    # Get the status.
    my ($mode, $perms, $nlink, $user, $group, $size, $time)
      = $fileh->status;

    # Return the requested information over the control connection.
    my $info = $self->_mlst_format ($filename, $fileh);

    # Can't use $self->reply since it produces the wrong format.
    print "250-Listing of $filename:\r\n";
    print " ", $info, "\r\n";
    print "250 End of listing.\r\n";
  }

sub _MLSD_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # XXX Note that this is slightly wrong. According to the Internet
    # Draft we shouldn't handle wildcards in the MLST or MLSD commands.
    my ($dirh, $wildcard, $fileh, $filename)
      = $self->_list ($rest);

    unless ($dirh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Check access control.
    unless ($self->_eval_rule ("list rule",
			       undef, undef, $dirh->pathname))
      {
	$self->reply (550, "MLSD command denied by server configuration.");
	return;
      }

    $self->reply (150, "Opening data connection for file listing.");

    # Open a path back to the client.
    my $sock = $self->open_data_connection;

    unless ($sock)
      {
	$self->reply (425, "Can't open data connection.");
	return;
      }

    # OK, we're either listing a full directory, listing a single
    # file or listing a wildcard.
    if ($fileh)			# Single file in $dirh.
      {
	$sock->print ($self->_mlst_format ($filename, $fileh), "\r\n");
      }
    else			# Wildcard or full directory $dirh.
      {
	my $r = $dirh->list_status ($wildcard);

	foreach (@$r)
	  {
	    my $filename = $_->[0];
	    my $handle = $_->[1];
	    my $statusref = $_->[2];

	    $sock->print ($self->_mlst_format ($filename,
					       $handle, $statusref), "\r\n");
	  }
      }

    $sock->close;

    $self->reply (226, "Listing complete. Data connection has been closed.");
  }

sub _OPTS_MLST_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Break up the list of facts.
    my @facts = split /;/, $rest;

    $self->{_mlst_facts} = [];

    # Check that all the facts asked for are supported.
    foreach (@facts)
      {
	$_ = uc;

	if ($_ ne "")
	  {
	    if ($self->_is_supported_mlst_fact ($_))
	      {
		push @{$self->{_mlst_facts}}, $_;
	      }
	  }
      }

    # Return the list of facts enabled.
    $self->reply (200,
		  "MLST OPTS " .
		  join ("",
			map { "$_;" } @{$self->{_mlst_facts}}));

    # Update the FEAT list.
    $self->{features}{MLST} = $self->_mlst_features;
  }

sub _is_supported_mlst_fact
  {
    my $self = shift;
    my $fact = shift;

    foreach my $supported_fact (@_supported_mlst_facts)
      {
	return 1 if $fact eq $supported_fact;
      }

    return 0;
  }

sub _mlst_features
  {
    my $self = shift;
    my $out = "";

    foreach my $supported_fact (@_supported_mlst_facts)
      {
	if ($self->_is_enabled_fact ($supported_fact)) {
	  $out .= "$supported_fact*;"
	} else {
	  $out .= "$supported_fact;"
	}
      }

    return $out;
  }

sub _is_enabled_fact
  {
    my $self = shift;
    my $fact = shift;

    foreach my $enabled_fact (@{$self->{_mlst_facts}})
      {
	return 1 if $fact eq $enabled_fact;
      }
    return 0;
  }

use vars qw(%_mode_to_mlst_unix_type);

# XXX I made these up. Is there a list anywhere?
%_mode_to_mlst_unix_type = (
			    l => "LINK",
			    p => "PIPE",
			    s => "SOCKET",
			    b => "BLOCK",
			    c => "CHAR",
			   );

sub _mlst_format
  {
    my $self = shift;
    my $filename = shift;
    my $handle = shift;
    my $statusref = shift;
    local $_;

    # Get the status information.
    my @status;
    if ($statusref) { @status = @$statusref }
    else            { @status = $handle->status }

    # Break out the fields of the status information.
    my ($mode, $perms, $nlink, $user, $group, $size, $mtime) = @status;

    # Return the requested facts.
    my @facts = ();

    foreach (@{$self->{_mlst_facts}})
      {
	if ($_ eq "TYPE")
	  {
	    if ($mode eq "f") {
	      push @facts, "$_=file";
	    } elsif ($mode eq "d") {
	      if ($filename eq ".") {
		push @facts, "$_=cdir";
	      } elsif ($filename eq "..") {
		push @facts, "$_=pdir";
	      } else {
		push @facts, "$_=dir";
	      }
	    } else {
	      push @facts, "$_=OS.UNIX=$_mode_to_mlst_unix_type{$mode}";
	    }
	  }
	elsif ($_ eq "SIZE")
	  {
	    push @facts, "$_=$size";
	  }
	elsif ($_ eq "MODIFY")
	  {
	    my $fmt_time = strftime "%Y%m%d%H%M%S", gmtime ($mtime);
	    push @facts, "$_=$fmt_time";
	  }
	elsif ($_ eq "PERM")
	  {
	    if ($mode eq "f")
	      {
		push @facts,
		"$_=" . ($handle->can_read ? "r" : "") .
		        ($handle->can_write ? "w" : "") .
		        ($handle->can_append ? "a" : "") .
			($handle->can_rename ? "f" : "") .
		        ($handle->can_delete ? "d" : "");
	      }
	    elsif ($mode eq "d")
	      {
		push @facts,
		"$_=" . ($handle->can_write ? "c" : "") .
		        ($handle->can_delete ? "d" : "") .
		        ($handle->can_enter ? "e" : "") .
		        ($handle->can_list ? "l" : "") .
			($handle->can_rename ? "f" : "") .
		        ($handle->can_mkdir ? "m" : "");
	      }
	    else
	      {
		# Pipes, block specials, etc.
		push @facts,
		"$_=" . ($handle->can_read ? "r" : "") .
		        ($handle->can_write ? "w" : "") .
		        ($handle->can_rename ? "f" : "") .
		        ($handle->can_delete ? "d" : "");
	      }
	  }
	elsif ($_ eq "UNIX.MODE")
	  {
	    my $unix_mode = sprintf ("%s%s%s%s%s%s%s%s%s",
				     ($perms & 0400 ? 'r' : '-'),
				     ($perms & 0200 ? 'w' : '-'),
				     ($perms & 0100 ? 'x' : '-'),
				     ($perms & 040 ? 'r' : '-'),
				     ($perms & 020 ? 'w' : '-'),
				     ($perms & 010 ? 'x' : '-'),
				     ($perms & 04 ? 'r' : '-'),
				     ($perms & 02 ? 'w' : '-'),
				     ($perms & 01 ? 'x' : '-'));
	    push @facts, "$_=$unix_mode";
	  }
	else
	  {
	    die "unknown MLST fact: $_";
	  }
      }

    # Return the facts to the user in a string.
    return join (";", @facts) . "; " . $filename;
  }

# Evaluate an access control rule from the configuration file.

sub _eval_rule
  {
    my $self = shift;
    my $rulename = shift;
    my $pathname = shift;
    my $filename = shift;
    my $dirname = shift;

    my $rule
      = defined $self->config ($rulename) ? $self->config ($rulename) : "1";

    # Set up the variables.
    my $hostname = $self->{peerhostname};
    my $ip = $self->{peeraddrstring};
    my $user = $self->{user};
    my $user_is_anonymous = $self->{user_is_anonymous};
    my $type = $self->{type};
    my $form = $self->{form};
    my $mode = $self->{mode};
    my $stru = $self->{stru};

    my $rv = eval $rule;
    die if $@;

    return $rv;
  }

# Move from one directory to another. Return the new directory handle.

sub _chdir
  {
    my $self = shift;
    my $dirh = shift;
    my $path = shift;
    local $_;

    # If the path starts with a "/" then it's an absolute path.
    if (substr ($path, 0, 1) eq "/")
      {
	$dirh = $self->root_directory_hook;
	$path =~ s,^/+,,;
      }

    # Split the path into its component parts and process each separately.
    my @elems = split /\//, $path;

    foreach (@elems)
      {
	if ($_ eq "" || $_ eq ".") { next } # Ignore these.
	elsif ($_ eq "..")
	  {
	    # Go to parent directory.
	    $dirh = $dirh->parent;
	  }
	else
	  {
	    # Go into subdirectory, if it exists.
	    $dirh = $dirh->get ($_);

	    return undef
	      unless $dirh && $dirh->isa ("Net::FTPServer::DirHandle");
	  }
      }

    return $dirh;
  }

# The list command understands the following forms for $path:
#
#   <<empty>>         List current directory.
#   file              List single file in cwd.
#   wildcard          List files by wildcard in cwd.
#   path/to/dir       List contents of directory, relative to cwd.
#   /path/to/dir      List contents of directory, absolute.
#   path/to/file      List single file, relative to cwd.
#   /path/to/file     List single file, absolute.
#   path/to/wildcard  List files by wildcard, relative to cwd.
#   /path/to/wildcard List files by wildcard, absolute.

sub _list
  {
    my $self = shift;
    my $path = shift;

    my $dirh = $self->{cwd};

    # Absolute path?
    if (substr ($path, 0, 1) eq "/")
      {
	$dirh = $self->root_directory_hook;
	$path =~ s,^/+,,;
      }

    # Parse the first elements of the path until we find the appropriate
    # working directory.
    my @elems = split /\//, $path;
    my ($wildcard, $fileh, $filename);
    local $_;

    for (my $i = 0; $i < @elems; ++$i)
      {
	$_ = $elems[$i];
	my $lastelement = $i == @elems-1;

	if ($_ eq "" || $_ eq ".") { next } # Ignore these.
	elsif ($_ eq "..")
	  {
	    # Go to parent directory.
	    $dirh = $dirh->parent;
	  }
	else
	  {
	    # What is it?
	    my $handle = $dirh->get ($_);

	    if (!$lastelement)
	      {
		if (!$handle)
		  {
		    return ();
		  }
		elsif (!$handle->isa ("Net::FTPServer::DirHandle"))
		  {
		    return ();
		  }
		else
		  {
		    $dirh = $handle;
		  }
	      }
	    else # it's the last element - treat it nicely.
	      {
		if (!$handle)
		  {
		    # But it could be a wildcard ...
		    if (/\*/ || /\?/)
		      {
			$wildcard = $_;
		      }
		    else
		      {
			return ();
		      }
		  }
		elsif (!$handle->isa ("Net::FTPServer::DirHandle"))
		  {
		    # So it's a file.
		    $fileh = $handle;
		    $filename = $_;
		  }
		else
		  {
		    $dirh = $handle;
		  }
	      }
	  }
      } # for

    return ($dirh, $wildcard, $fileh, $filename);
  }

# The get command understands the following forms for $path:
#
#   file              List single file in cwd.
#   path/to/file      List single file, relative to cwd.
#   /path/to/file     List single file, absolute.
#
# Returns ($dirh, $fileh, $filename) where:
#
#   $dirh is set if the directory exists
#   $fileh is set if the directory and the file exist
#   $filename is just the last component part of the path
#     and is always set if $dirh is set.

sub _get
  {
    my $self = shift;
    my $path = shift;

    my $dirh = $self->{cwd};

    # Absolute path?
    if (substr ($path, 0, 1) eq "/")
      {
	$dirh = $self->root_directory_hook;
	$path =~ s,^/+,,;
      }

    # Parse the first elements of path until we find the appropriate
    # working directory.
    my @elems = split /\//, $path;
    my $filename = pop @elems;

    unless ($filename)
      {
	return ();
      }

    foreach (@elems)
      {
	if ($_ eq "" || $_ eq ".") { next } # Ignore these.
	elsif ($_ eq "..")
	  {
	    # Go to parent directory.
	    $dirh = $dirh->parent;
	  }
	else
	  {
	    my $handle = $dirh->get ($_);

	    if (!$handle)
	      {
		return ();
	      }
	    elsif (!$handle->isa ("Net::FTPServer::DirHandle"))
	      {
		return ();
	      }
	    else
	      {
		$dirh = $handle;
	      }
	  }
      }

    # Get the file handle.
    my $fileh = $dirh->get ($filename);

    return ($dirh, $fileh, $filename);
  }

=pod

=item $sock = $self->open_data_connection;

Open a data connection. Returns the socket (an instance of C<IO::Socket>) or undef if it fails for some reason.

=cut

sub open_data_connection
  {
    my $self = shift;
    my $sock;

    if (! $self->{_passive})
      {
	# Active mode - connect back to the client.
	$sock
	  = new IO::Socket::INET->new (PeerAddr => $self->{_hostaddrstring},
				       PeerPort => $self->{_hostport},
				       Proto => "tcp",
				       Type => SOCK_STREAM,
				       Reuse => 1)
	    or return undef;
      }
    else
      {
	# Passive mode - wait for a connection from the client.
	$sock = $self->{_passive_sock}->accept or return undef;

	# Check that the peer address of the connection is the
	# client's own IP address.
	# XXX This test is commented out because it causes Netscape 4
	# to fail on loopback connections.
#	unless ($self->config ("allow proxy ftp"))
#	  {
#	    my $peeraddrstring = inet_ntoa ($sock->peeraddr);

#	    if ($peeraddrstring ne $self->{peeraddrstring})
#	      {
#		$self->reply (504, "Proxy FTP is not allowed on this server.");
#		return;
#	      }
#	  }
      }

    # Set TCP keepalive?
    if (defined $self->config ("tcp keepalive"))
      {
	$sock->sockopt (SO_KEEPALIVE, 1)
	  or warn "setsockopt: SO_KEEPALIVE: $!";
      }

    # Set TCP initial window size?
    if (defined $self->config ("tcp window"))
      {
	$sock->sockopt (SO_SNDBUF, $self->config ("tcp window"))
	  or warn "setsockopt: SO_SNDBUF: $!";
	$sock->sockopt (SO_RCVBUF, $self->config ("tcp window"))
	  or warn "setsockopt: SO_RCVBUF: $!";
      }

    return $sock;
  }

# $self->_list_file ($sock, $fileh, [$filename, [$statusref]]);
#
# List a single file over the data connection $sock.

sub _list_file
  {
    my $self = shift;
    my $sock = shift;
    my $fileh = shift;
    my $filename = shift || $fileh->filename;
    my $statusref = shift;

    # Get the status information.
    my @status;
    if ($statusref) { @status = @$statusref }
    else            { @status = $fileh->status }

    # Break out the fields of the status information.
    my ($mode, $perms, $nlink, $user, $group, $size, $mtime) = @status;

    # Generate printable date (this logic is taken from GNU fileutils:
    # src/ls.c: print_long_format).
    my $time = time;
    my $fmt;
    if ($time > $mtime + 6 * 30 * 24 * 60 * 60 || $time < $mtime - 60 * 60)
      {
	$fmt = "%b %e  %Y";
      }
    else
      {
	$fmt = "%b %e %H:%M";
      }

    my $fmt_time = strftime $fmt, gmtime ($mtime);

    # Display the file.
    $sock->printf ("%s%s%s%s%s%s%s%s%s%s%4d %-8s %-8s %8d %s %s\r\n",
		   ($mode eq 'f' ? '-' : $mode),
		   ($perms & 0400 ? 'r' : '-'),
		   ($perms & 0200 ? 'w' : '-'),
		   ($perms & 0100 ? 'x' : '-'),
		   ($perms & 040 ? 'r' : '-'),
		   ($perms & 020 ? 'w' : '-'),
		   ($perms & 010 ? 'x' : '-'),
		   ($perms & 04 ? 'r' : '-'),
		   ($perms & 02 ? 'w' : '-'),
		   ($perms & 01 ? 'x' : '-'),
		   $nlink,
		   $user,
		   $group,
		   $size,
		   $fmt_time,
		   $filename);
  }

# Implement the STOR, STOU (store unique) and APPE (append) commands.

sub _store
  {
    my $self = shift;
    my $path = shift;
    my %params = @_;

    my $unique = $params{unique} || 0;
    my $append = $params{append} || 0;

    my ($dirh, $fileh, $filename, $transfer_hook);

    unless ($unique)
      {
	# Get the directory.
	($dirh, $fileh, $filename) = $self->_get ($path);

	unless ($dirh)
	  {
	    $self->reply (550, "File or directory not found.");
	    return;
	  }
      }
    else			# STOU command -- ignore any parameters.
      {
	$dirh = $self->{cwd};

	# Choose a unique name for this file.
	my $i = 0;
	while ($dirh->get ("X$i")) {
	  $i++;
	}

	$filename = "X$i";
      }

    # Check access control.
    unless ($self->_eval_rule ("store rule",
			       $dirh->pathname . $filename,
			       $filename, $dirh->pathname))
      {
	$self->reply (550, "Store command denied by server configuration.");
	return;
      }

    # Are we trying to overwrite a previously existing file?
    if (! $append &&
	defined $fileh &&
	defined $self->config ("allow store to overwrite") &&
	! $self->config ("allow store to overwrite"))
      {
	$self->reply (550, "Cannot rename file.");
	return;
      }

    # Try to open the file.
    my $file = $dirh->open ($filename, ($append ? "a" : "w"));

    unless ($file)
      {
	$self->reply (550, "Cannot create file $filename.");
	return;
      }

    unless ($unique)
      {
	$self->reply (150,
		      "Opening " .
		      ($self->{type} eq 'A' ? "ASCII mode" : "BINARY mode") .
		      " data connection for file $filename.");
      }
    else
      {
	# RFC 1123 section 4.1.2.9.
	$self->reply (150, "FILE: $filename");
      }

    # Open a path back to the client.
    my $sock = $self->open_data_connection;

    unless ($sock)
      {
	$self->reply (425, "Can't open data connection.");
	return;
      }

    # What mode are we receiving this file in?
    unless ($self->{type} eq 'A') # Binary type.
      {
	my ($r, $buffer, $n, $w);

	# XXX Do we need to support REST?

	# Copy data.
	while ($r = $sock->sysread ($buffer, 65536))
	  {
	    # Restart alarm clock timer.
	    alarm $self->{_idle_timeout};

	    if ($transfer_hook
		= $self->transfer_hook ("w", $file, $sock, \$buffer))
	      {
		$sock->close;
		$file->close;
		$self->reply (426,
			      "File store error: $transfer_hook",
			      "Data connection has been closed.");
		return;
	      }

	    for ($n = 0; $n < $r; )
	      {
		$w = $file->syswrite ($buffer, $r - $n, $n);

		unless (defined $w)
		  {
		    # There was an error.
		    my $reason = $!;

		    $sock->close;
		    $file->close;
		    $self->reply (426,
				  "File store error: $reason",
				  "Data connection has been closed.");
		    return;
		  }

		$n += $w;
	      }
	  }

	unless (defined $r)
	  {
	    # There was an error.
	    my $reason = $!;

	    $sock->close;
	    $file->close;
	    $self->reply (426,
			  "File store error: $reason",
			  "Data connection has been closed.");
	    return;
	  }
      }
    else			# ASCII type.
      {
	# XXX Do we need to support REST?

	# Copy data.
	while ($_ = $sock->getline)
	  {
	    # Remove any telnet-format line endings.
	    s/[\n\r]*$//;

	    # Restart alarm clock timer.
	    alarm $self->{_idle_timeout};

	    if ($transfer_hook = $self->transfer_hook ("w", $file, $sock, \$_))
	      {
		$sock->close;
		$file->close;
		$self->reply (426,
			      "File store error: $transfer_hook",
			      "Data connection has been closed.");
		return;
	      }

	    # Write the line with native format line endings.
	    my $w = $file->print ("$_\n");
	    unless (defined $w)
	      {
		my $reason = $!;
		# There was an error.
		$sock->close;
		$file->close;
		$self->reply (426,
			      "File store error: $reason",
			      "Data connection has been closed.");
		return;
	      }
	  }
      }

    $sock->close;
    $file->close;

    $self->reply (226, "File store complete. Data connection has been closed.");
  }

=pod

=item $self->pre_configuration_hook ();

Hook: Called before command line arguments and configuration file
are read.

Status: optional.

Notes: You may append your own information to C<$self->{version_string}>
from this hook.

=cut

sub pre_configuration_hook
  {
  }

=pod

=item $self->options_hook (\@args);

Hook: Called before command line arguments are parsed.

Status: optional.

Notes: You can use this hook to supply your own command line arguments.
If you parse any arguments, you should remove them from the @args
array.

=cut

sub options_hook
  {
  }

=pod

=item $self->post_configuration_hook ();

Hook: Called after all command line arguments and configuration file
have been read and parsed.

Status: optional.

=cut

sub post_configuration_hook
  {
  }

=pod

=item $self->post_bind_hook ();

Hook: Called only in daemon mode after the control port is bound
but before starting the accept infinite loop block.

Status: optional.

=cut

sub post_bind_hook
  {
  }

=pod

=item $self->pre_accept_hook ();

Hook: Called in daemon mode only just before C<accept(2)> is called
in the parent FTP server process.

Status: optional.

=cut

sub pre_accept_hook
  {
  }

=pod

=item $self->post_accept_hook ();

Hook: Called both in daemon mode and in inetd mode just after the
connection has been accepted. This is called in the child process.

Status: optional.

=cut

sub post_accept_hook
  {
  }

=pod

=item $rv = $self->access_control_hook;

Hook: Called after C<accept(2)>-ing the connection to perform access
control. Detailed request information is contained in the $self
object.  If the function returns -1 then the socket is immediately
closed and no FTP processing happens on it. If the function returns 0,
then normal access control is performed on the socket before FTP
processing starts. If the function returns 1, then normal access
control is I<not> performed on the socket and FTP processing begins
immediately.

Status: optional.

=cut

sub access_control_hook
  {
    return 0;
  }

=pod

=item $rv = $self->process_limits_hook;

Hook: Called after C<accept(2)>-ing the connection to perform
per-process limits (eg. by using the setrlimit(2) system
call). Access control has already been performed and detailed
request information is contained in the C<$self> object.

If the function returns -1 then the socket is immediately closed and
no FTP processing happens on it. If the function returns 0, then
normal per-process limits are applied before any FTP processing
starts. If the function returns 1, then normal per-process limits are
I<not> performed and FTP processing begins immediately.

Status: optional.

=cut

sub process_limits_hook
  {
    return 0;
  }

=pod

=item $rv = $self->authentication_hook ($user, $pass, $user_is_anon)

Hook: Called to perform authentication. If the authentication
succeeds, this should return 0. If the authentication fails,
this should return -1.

Status: required.

=cut

sub authentication_hook
  {
    die "authentication_hook is required";
  }

=pod

=item $self->user_login_hook ($user, $user_is_anon)

Hook: Called just after user C<$user> has successfully logged in. A good
place to change uid and chroot if necessary.

Status: optional.

=cut

sub user_login_hook
  {
  }

=pod

=item $dirh = $self->root_directory_hook;

Hook: Return an instance of a subclass of Net::FTPServer::DirHandle
corresponding to the root directory.

Status: required.

=cut

sub root_directory_hook
  {
    die "root_directory_hook is required";
  }

=pod

=item $self->pre_command_hook;

Hook: This hook is called just before the server begins to wait for
the client to issue the next command over the control connection.

Status: optional.

=cut

sub pre_command_hook
  {
  }

=pod

=item $rv = $self->command_filter_hook ($cmdline);

Hook: This hook is called immediately after the client issues
command C<$cmdline>, but B<before> any checking or processing
is performed on the command. If this function returns -1, then
the server immediately goes back to waiting for the next
command. If this function returns 0, then normal command filtering
is carried out and the command is processed. If this function
returns 1 then normal command filtering is B<not> performed
and the command processing begins immediately.

Important Note: This hook must be careful B<not> to overwrite
the global C<$_> variable.

Do not use this function to add your own commands. Instead
use the C<$self-E<gt>{command_table}> and C<$self-E<gt>{site_command_table}>
hashes.

Status: optional.

=cut

sub command_filter_hook
  {
    return 0;
  }


=pod

=item $error = $self->transfer_hook ($mode, $file, $sock, \$buffer);

  $mode     -  Open mode on the File object (Either reading or writing)
  $file     -  File object as returned from DirHandle::open
  $sock     -  Data IO::Socket object used for transfering
  \$buffer  -  Reference to current buffer about to be written

The \$buffer is passed by reference to minimize the stack overhead
for efficiency purposes only.  It is B<not> meant to be modified by
the transfer_hook subroutine.  (It can cause corruption if the
length of $buffer is modified.)

Hook: This hook is called after reading $buffer and before writing
$buffer to its destination.  If arg1 is "r", $buffer was read
from the File object and written to the Data socket.  If arg1 is
"w", $buffer will be written to the File object because it was
read from the Data Socket.  The return value is the error for not
being able to perform the write.  Return undef to avoid aborting
the transfer process.

Status: optional.

=cut

sub transfer_hook
  {
    return undef;
  }

=pod

=item $self->post_command_hook

Hook: This hook is called after all command processing has been
carried out on this command.

Status: optional.

=cut

sub post_command_hook
  {
  }

1 # So that the require or use succeeds.

__END__

=back 4

=head1 BUGS

The SIZE, REST and RETR commands probably do not work correctly
in ASCII mode.

REST does not work before STOR/STOU/APPE (is it supposed to?)

You cannot abort a transfer in progress yet. Nor can you check
the status of a transfer in progress. Using the telnet interrupt
commands can cause the FTP server to fail.

User upload/download limits.

Limit number of clients. Limit number of clients by host or IP address.

The following commands are recognized by C<wu-ftpd>, but are not yet
implemented by C<Net::FTPServer>:

  SITE CHMOD   There is a problem supporting this with our VFS.
  SITE GPASS   Group functions are not really relevant for us.
  SITE GROUP   -"- ditto -"-
  SITE GROUPS  -"- ditto -"-
  SITE INDEX   This is a synonym for SITE EXEC.
  SITE MINFO   This command is no longer supported by wu-ftpd.
  SITE NEWER   This command is no longer supported by wu-ftpd.
  SITE UMASK   This command is difficult to support with VFS.

Symbolic links are not handled elegantly (or indeed at all) yet.

The program needs to log a lot more general transfer and
access information to syslog.

Equivalent of ProFTPDE<39>s ``DisplayReadme'' function.

The ability to hide dot files (probably best to build this
into the VFS layer). This should apply across all commands.
See ProFTPDE<39>s ``IgnoreHidden'' function.

Do ident (RFC913) authentication at login. Have a way to
turn this on and off.

Access to LDAP authentication database (can currently be done using a
PAM module). In general, we should support pluggable authentication.

Log formatting similar to ProFTPD command LogFormat.

More timeouts to avoid various denial of service attacks. For example,
the server should always timeout when waiting too long for an
active data connection.

Support for IPv6 (see RFC 2428), EPRT, EPSV commands.

Upload and download tar.gz/zip files automatically.

See also "XXX" comments in the code for other problems, missing features
and bugs.

=head1 FILES

  /etc/ftpd.conf
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer.pm
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer/DirHandle.pm
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer/FileHandle.pm
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer/Handle.pm

=head1 AUTHORS

Richard Jones (rich@annexia.org).

=head1 COPYRIGHT

Copyright (C) 2000 Biblio@Tech Ltd., Unit 2-3, 50 Carnwath Road,
London, SW6 3EG, UK

=head1 SEE ALSO

L<Net::FTPServer::Handle(3)>,
L<Net::FTPServer::FileHandle(3)>,
L<Net::FTPServer::DirHandle(3)>,
L<Authen::PAM(3)>,
L<Net::FTP(3)>,
L<perl(1)>,
RFC 765,
RFC 959,
RFC 1579,
RFC 2389,
RFC 2428,
RFC 2577,
RFC 2640,
Extensions to FTP Internet Draft draft-ietf-ftpext-mlst-NN.txt.

=cut
