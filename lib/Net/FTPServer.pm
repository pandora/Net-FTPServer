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

# $Id: FTPServer.pm,v 1.35 2000/09/08 10:59:37 rich Exp $

=pod

=head1 NAME

Net::FTPServer - A secure, extensible and configurable Perl FTP server

=head1 SYNOPSIS

  ftpd [-d] [-v] [-p port] [-s] [-S] [-V] [-C conf_file]

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
FTP server or as an anonymous-only FTP server. The
scripts are C<ftpd> and C<anonftpd>. You may need to
edit these scripts if Perl is not stored in the standard
place on your system (the default path is C</usr/bin/perl>).

You should copy the appropriate script, either C<ftpd> or
C<anonftpd> to a suitable place (for example: C</usr/sbin/in.ftpd>).

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

=head2 LOADING CUSTOMIZED COMMAND SETS

XXX




=head2 STANDARD PERSONALITIES

XXX






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

=head1 METHODS

=over 4

=cut

package Net::FTPServer;

use strict;

use Getopt::Long qw(GetOptions);
use Sys::Hostname;
use Sys::Syslog qw(:DEFAULT setlogsock);
use Socket;
use IO::Socket;
use IO::Socket::INET;
use POSIX;
use BSD::Resource;
use Carp;

use Net::FTPServer::FileHandle;
use Net::FTPServer::DirHandle;

use vars qw(@_default_commands
	    @_default_site_commands
	    @_supported_mlst_facts
	    $_default_timeout
	    $VERSION $RELEASE);

$VERSION = '0.4.5';
$RELEASE = 1;

@_default_commands
  = (
     # Standard commands from RFC 959.
     "USER", "PASS", "ACCT", "CWD", "CDUP", "SMNT",
     "REIN", "QUIT", "PORT", "PASV", "TYPE", "STRU",
     "MODE", "RETR", "STOR", "STOU", "APPE", "ALLO",
     "REST", "RNFR", "RNTO", "ABOR", "DELE", "RMD",
     "MKD", "PWD", "LIST", "NLST", "SITE", "SYST",
     "STAT", "HELP", "NOOP",
     # RFC 1123 secdion 4.1.3.1 recommends implementing these.
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
      exit;
    };

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

	# Run as a daemon.
	$self->_be_daemon;
      }

    $| = 1;

    # Hook just after accepting the connection.
    $self->post_accept_hook;

    # Get the peername and other details of this socket.
    my $peername = getpeername STDIN;

    my ($peerport, $peeraddr) = unpack_sockaddr_in ($peername);
    my $peeraddrstring = inet_ntoa ($peeraddr);
    my $peerhostname;

    # Get the sockname of the socket so we know which interface
    # the client is bound to.
    my $sockname = getsockname STDIN;
    my ($sockport, $sockaddr) = unpack_sockaddr_in ($sockname);
    my $sockaddrstring = inet_ntoa ($sockaddr);

    # Resolve the address.
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
    $self->{peername} = $peername;
    $self->{peerport} = $peerport;
    $self->{peeraddr} = $peeraddr;
    $self->{peeraddrstring} = $peeraddrstring;
    $self->{peerhostname} = $peerhostname;
    $self->{sockname} = $sockname;
    $self->{sockport} = $sockport;
    $self->{sockaddr} = $sockaddr;
    $self->{sockaddrstring} = $sockaddrstring;
    $self->{authenticated} = 0;
    $self->{loginattempts} = 0;

    # Default port information, used if no PORT command is issued. This
    # is used by the open_data_connection function. See RFC 959 section 3.2.
    $self->{_hostport} = $peerport;
    $self->{_hostaddr} = $peeraddr;
    $self->{_hostaddrstring} = $peeraddrstring;

    # Default mode is active. Issuing the PASV command switches the
    # server into passive mode. There doesn't appear to be a way to
    # make the server return to active mode.
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
	my $limit = 1024 * ($self->config ("limit memory") || 8192);
	setrlimit (RLIMIT_AS, $limit, $limit)
	  or die "setrlimit: $!";

	$limit = $self->config ("limit nr processes") || 5;
	setrlimit (RLIMIT_NPROC, $limit, $limit)
	  or die "setrlimit: $!";

	$limit = $self->config ("limit nr files") || 20;
	setrlimit (RLIMIT_NOFILE, $limit, $limit)
	  or die "setrlimit: $!";
      }

    # Log the connection information available.
    if ($peerhostname)
      {
	syslog "info",
	"connection from " .
	"$peerhostname:$peerport ($peeraddrstring:$peerport)";
      }
    else
      {
	syslog "info",
	"connection from $peeraddrstring:$peerport";
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

	# Reset the alarm.
	alarm 0;

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
	    exit 0;
	  }

	my ($cmd, $rest) = (uc $1, $2);

	syslog "info", "command: (%s, %s)",
	  _escape($cmd), _escape($rest)
	  if $self->{debug};

	# All commands except USER, PASS, LANG, FEAT, QUIT and HELP
	# require user to be authenticated.
	if (!$self->{authenticated} &&
	    $cmd ne "USER" && $cmd ne "PASS" && $cmd ne "LANG" &&
	    $cmd ne "LANG" && $cmd ne "HELP" && $cmd ne "QUIT")
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

    syslog "info", "connection terminated normally";
  }

# This subroutine loads the command line options and configuration file
# and resolves conflicts. Command line options have priority over
# certain things in the configuration file.

sub _get_configuration
  {
    my $self = shift;
    my $args = shift;
    local @ARGV = @$args;

    my ($debug, $show_version);

    GetOptions ("d+" => \$debug,
		"v+" => \$debug,
		"p=i" => \$self->{_args_ctrl_port},
		"s" => \$self->{_args_daemon_mode},
		"S" => \$self->{_args_run_in_background},
		"V" => \$show_version,
		"C=s" => \$self->{_config_file});

    # Show version and exit?
    if ($show_version)
      {
	print STDERR $self->{version_string};
	exit 0;
      }

    # Run in background implies daemon mode.
    $self->{_args_daemon_mode} = 1
      if defined $self->{_args_run_in_background};

    # Read the configuration file.
    $self->_open_config_file;

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
    POSIX::setsid;

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

    # Discover the default FTP port from /etc/services or equivalent.
    my $default_port = getservbyname "ftp", "tcp" || 21;

    # Construct argument list to socket.
    my @args = (Reuse => 1,
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

    # Automatically clean up zombie children.
    $SIG{CHLD} = sub { wait };

    # Accept new connections and fork off new process to handle it.
    for (;;)
      {
	$self->pre_accept_hook;

	my $sock = $self->{_ctrl_sock}->accept
	  or die "accept: $!";

	# Fork off a process to handle this connection.
	my $pid = fork;
	if (defined $pid)
	  {
	    if ($pid == 0)		# Child process.
	      {
		syslog "info", "starting child process" if $self->{debug};
		
		# Duplicate the socket so it looks like we were called
		# from inetd.
		POSIX::dup2 ($sock->fileno, 0);
		POSIX::dup2 ($sock->fileno, 1);

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
    my $config_file = $self->{_config_file};

    $self->{_config} = {};

    unless (open CONFIG, "<$config_file")
      {
	warn "cannot open configuration file: $config_file: $!";
	return;
      }

    my $lineno = 0;

    # Read in the configuration options from the file.
    while (<CONFIG>)
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
	    $_ .= <CONFIG>;
	    $lineno++;
	  }

	# Split the line on the first : character.
	unless (/^(.*?):(.*)$/)
	  {
	    syslog "error", "$config_file:$lineno: syntax error in configuration file";
	    exit 1
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

	# Save this.
	$self->{_config}{$key} = [] unless exists $self->{_config}{$key};
	push @{$self->{_config}{$key}}, $value;
      }

    close CONFIG;

#    # Print out the configuration options.
#    foreach (sort keys %{$self->{_config}})
#      {
#	warn "$_: [" . join (", ", @{$self->{_config}{$_}}) . "]";
#      }
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

    unless (exists $self->{_config}{$key})
      {
	unless (wantarray) { return undef } else { return () }
      }
    else
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



    return undef;
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
	    exit 0;
	  }

	$self->reply (530, "Login failed.");
	return;
      }

    # Perform user access control step.
    unless ($self->_eval_rule ("user access control rule"))
      {
	$self->reply (421, "User denied by server configuration. Goodbye.");
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

	open FILE, "<$welcome_file"
	  or die "welcome file: $welcome_file: $!";
	while (<FILE>) {
	  s/[\n\r]+$//;
	  push @lines, $self->_percent_substitutions ($_);
	}
	close FILE;

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
	warn "no home directory for user: $self->{user}";
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
	if ($hostaddrstring ne $self->{peeraddrstring})
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

    $self->reply (200, "PORT command OK.");
  }

sub _PASV_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Open a listening socket - but don't actually accept on it yet.
    # RFC 2577 section 8 suggests using random local port numbers.

    # Note: Why don't I just use ``LocalPort => 0''? Well, I did, but
    # IO::Socket::INET used to just throw the following wierd error:
    # Argument "PASV" isn't numeric in entersub at \
    #   /usr/lib/perl5/5.00503/i686-linux/IO/Socket/INET.pm line 194
    # (note that $_ = "PASV" at this point). Why?

    my ($sock, $count);
    $count = 100;

    until (defined $sock || --$count == 0)
      {
	# XXX Use a secure source of random numbers, otherwise this
	# is a little bit pointless ...

	# See http://www.isi.edu/in-notes/iana/assignments/port-numbers
	my $port = int (rand (65535 - 49152)) + 49152;

	$sock = IO::Socket::INET->new (Listen => 1,
				       LocalAddr => $self->{sockaddrstring},
				       LocalPort => $port,
				       Reuse => 1);
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
    my $sockaddrstring = $self->{sockaddrstring};

    # We will need to revise this for IPv6 XXX
    die unless $sockaddrstring =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/;

    # Split the port number into high and low components.
    my $p1 = int ($sockport / 256);
    my $p2 = $sockport % 256;

    # Be very precise about this error message, since most clients
    # will have to parse the whole of it.
    $self->reply (227, "Entering Passive Mode ($1, $2, $3, $4, $p1, $p2)");
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
	    for ($n = 0; $n < $r; )
	      {
		$w = $sock->syswrite ($buffer, $r - $n);

		unless (defined $w)
		  {
		    # There was an error.
		    $sock->close;
		    $file->close;
		    $self->reply (426,
				  "File retrieval error: $!",
				  "Data connection has been closed.");
		    return;
		  }

		$n += $w;
	      }
	  }

	unless (defined $r)
	  {
	    # There was an error.
	    $sock->close;
	    $file->close;
	    $self->reply (426,
			  "File retrieval error: $!",
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
	    # Write the line with telnet-format line endings.
	    $sock->print ("$_\r\n");
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

    # RFC 959 Section 4.1.3: Treat this as a NOOP.
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

    $self->reply (250, "File has been renamed.");
  }

sub _ABOR_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # XXX The ability to abort a transfer in progress is not implemented yet.
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

    $self->reply (257, "\"" . $pathname . "\"");
  }

sub _LIST_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

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

    # OK, we're either listing a full directory, listing a single
    # file or listing a wildcard.
    if ($fileh)			# Single file in $dirh.
      {
	$self->_list_file ($sock, $fileh, $filename);
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

	    $self->_list_file ($sock, $handle, $filename, $statusref);
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

    # OK, we're either listing a full directory, listing a single
    # file or listing a wildcard.
    if ($fileh)			# Single file in $dirh.
      {
	$sock->print ($filename, "\r\n");
      }
    else			# Wildcard or full directory $dirh.
      {
	my $r = $dirh->list ($wildcard);

	foreach (@$r)
	  {
	    my $filename = $_->[0];
	    my $handle = $_->[1];

	    $sock->print ($filename, "\r\n");
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
    my $enabled
      = defined $self->config ("allow site exec command")
	? $self->config ("allow site exec command") : 0;

    unless ($enabled)
      {
	$self->reply (502, "SITE EXEC is disabled at this site.");
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

    $rest = uc ($rest);

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

    # Using the eval here ensures that we don't fail totally
    # if Digest::MD5 is not installed.
    eval
      {
	use Digest::MD5;

	my $ctx = Digest::MD5->new;
	$ctx->addfile ($file);	# IO::Handles are also filehandle globs.

	$self->reply (200, $ctx->hexdigest . " " . $filename);
      };
    if ($@)
      {
	$self->reply (500, "Cannot open MD5 library.");
	return;
      }
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
    my $min_timeout = 30;
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

	$status{Client} = "$self->{peeraddrstring}:$self->{peerport}";
	$status{Client}
	.= " ($self->{peerhostname}:$self->{peerport})"
	  if $self->{peerhostname};

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

    # Without any arguments, return a list of commands supported.
    if ($rest eq "")
      {
	my @lines = _format_list (sort keys %{$self->{command_table}});

	$self->reply (214,
		      "The following commands are recognized:",
		      @lines,
		      "You can also use HELP SITE to list site specific commands.");
      }
    # HELP SITE.
    elsif (uc $rest eq "SITE")
      {
	my @lines = _format_list (sort keys %{$self->{site_command_table}});

	$self->reply (214,
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
    my $rows = int (POSIX::ceil (@_ / 4.));

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
    return _MKD_command (@_);
  }

sub _XRMD_command
  {
    return _RMD_command (@_);
  }

sub _XPWD_command
  {
    return _PWD_command (@_);
  }

sub _XCUP_command
  {
    return _CDUP_command (@_);
  }

sub _XCWD_command
  {
    return _CWD_command (@_);
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
    my $fmt_time = POSIX::strftime "%Y%m%d%H%M%S", gmtime ($time);

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
    # XXX CHECK LIST RULE HERE.

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
	    my $fmt_time = POSIX::strftime "%Y%m%d%H%M%S", gmtime ($mtime);
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

    my $rule = $self->config ($rulename) || "1";

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
	$dirh = new Net::FTPServer::DirHandle ($self);
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
	$dirh = new Net::FTPServer::DirHandle ($self);
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
	$dirh = new Net::FTPServer::DirHandle ($self);
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

    my $fmt_time = POSIX::strftime $fmt, gmtime ($mtime);

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

    # Get the directory.
    my ($dirh, $fileh, $filename) = $self->_get ($path);

    unless ($dirh)
      {
	$self->reply (550, "File or directory not found.");
	return;
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

    # Choose a unique name for this file, not very cleverly.
    # XXX Is there a security problem here? One obvious problem
    # is that it reveals the server's PID which might be useful
    # to crackers under some circumstances.
    $filename = "X$$" if $unique;

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
	    for ($n = 0; $n < $r; )
	      {
		$w = $file->syswrite ($buffer, $r - $n);

		unless (defined $w)
		  {
		    # There was an error.
		    $sock->close;
		    $file->close;
		    $self->reply (426,
				  "File retrieval error: $!",
				  "Data connection has been closed.");
		    return;
		  }

		$n += $w;
	      }
	  }

	unless (defined $r)
	  {
	    # There was an error.
	    $sock->close;
	    $file->close;
	    $self->reply (426,
			  "File retrieval error: $!",
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
	    s/[\n\r]+$//;
	    # Write the line with native format line endings.
	    $file->print ("$_\n");
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
    my $self = shift;
    my $user = shift;
    my $pass = shift;
    my $user_is_anon = shift;

    # Allow anonymous users. By this point we have already checked
    # that allow anonymous is true in the configuration file.
    return 0 if $user_is_anon;

    unless ($self->config ("pam authentication"))
      {
	# Verify user information against the password file.
	my $hashed_pass = (getpwnam $user)[1] or return -1;

	# Check password.
	my $salt = substr $hashed_pass, 0, 2;

	return -1 if crypt ($pass, $salt) ne $hashed_pass;
      }
    else
      {
	return -1 if $self->_pam_check_password ($user, $pass) < 0;
      }

    # Successful login.
    return 0;
  }


sub _pam_check_password
  {
    my $self = shift;
    my $user = shift;
    my $pass = shift;

    # As noted in the source to wu-ftpd, this is something
    # of an abuse of the PAM protocol. However the FTP protocol
    # gives us little choice in the matter.

    # The ``eval'' means we only require the PAM code if we
    # actually require PAM authentication support in the
    # configuration file.

    eval
      {
	use Authen::PAM;

	my $pam_conv_func = sub
	  {
	    my @res;

	    while (@_)
	      {
		my $msg_type = shift;
		my $msg = shift;

		if ($msg_type == PAM_PROMPT_ECHO_ON)
		  {
		    # XXX PAM_CONV_ERR not defined in Authen::PAM.
		    return ( 19 );
		  }
		elsif ($msg_type == PAM_PROMPT_ECHO_OFF)
		  {
		    push @res, PAM_SUCCESS;
		    push @res, $pass;
		  }
		elsif ($msg_type == PAM_TEXT_INFO)
		  {
		    push @res, PAM_SUCCESS;
		    push @res, "";
		  }
		elsif ($msg_type == PAM_ERROR_MSG)
		  {
		    push @res, PAM_SUCCESS;
		    push @res, "";
		  }
		else
		  {
		    # XXX PAM_CONV_ERR not defined in Authen::PAM.
		    return ( 19 );
		  }
	      }

	    push @res, PAM_SUCCESS;
	    return @res;
	  };

	my $pam_appl = $self->config ("pam application name") || "ftp";
	my $pamh = new Authen::PAM ($pam_appl, $user, $pam_conv_func);

	ref ($pamh) || die "PAM error: pam_start: $pamh";

	$pamh->pam_set_item (PAM_RHOST, $self->{peeraddrstring})
	  == PAM_SUCCESS
	    or die "PAM error: pam_set_item";

	$pamh->pam_authenticate (0) == PAM_SUCCESS
	  or die "PAM error: pam_authenticate";

	$pamh->pam_acct_mgmt (0) == PAM_SUCCESS
	  or die "PAM error: pam_acct_mgmt";

	$pamh->pam_setcred (PAM_ESTABLISH_CRED) == PAM_SUCCESS
	  or die "PAM error: pam_setcred";
      }; # eval

    return -1 if $@;

    return 0;
  }

=pod

=item $self->user_login_hook ($user, $user_is_anon)

Hook: Called just after user C<$user> has successfully logged in.

Status: required.

=cut

sub user_login_hook
  {
    my $self = shift;
    my $user = shift;
    my $user_is_anon = shift;

    my ($login, $pass, $uid, $gid, $quota, $comment, $gecos, $homedir);

    # For non-anonymous users, just get the uid/gid.
    if (! $user_is_anon)
      {
	($login, $pass, $uid, $gid) = getpwnam $user
	  or die "no user $user in password file";

	# Chroot for this non-anonymous user?
	my $root_directory = $self->config ("root directory");

	if (defined $root_directory)
	  {
	    $root_directory =~ s/%m/(getpwnam $user)[7]/ge;
	    $root_directory =~ s/%U/$user/ge;
	    $root_directory =~ s/%%/%/g;

	    chroot $root_directory
	      or die "cannot chroot: $root_directory: $!";
	  }
      }
    # For anonymous users, chroot to ftp directory.
    else
      {
	($login, $pass, $uid, $gid, $quota, $comment, $gecos, $homedir)
	  = getpwnam "ftp"
	    or die "no ftp user in password file";

	chroot $homedir or die "cannot chroot: $homedir: $!";
      }

    # We don't allow users to relogin, so completely change to
    # the user specified.

    # Change effective UID.
    $) = $gid;
    $> = $uid;

    # Change real UID.
    $( = $gid;
    $< = $uid;

    # XXX Need to initgroups too?
  }

=pod

=item $dirh = $self->root_directory_hook;

Hook: Return an instance of Net::FTPServer::DirHandle (or a subclass)
corresponding to the root directory.

Status: optional.

=cut

sub root_directory_hook
  {
    my $self = shift;

    return new Net::FTPServer::DirHandle ($self);
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

You cannot abort a transfer in progress yet. Nor can you check
the status of a transfer in progress. Using the telnet interrupt
commands can cause the FTP server to fail.

User upload/download limits.

Limit number of clients. Limit number of clients by host or IP address.

Virtual hosts.

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
