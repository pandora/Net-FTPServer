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

# $Id: FTPServer.pm,v 1.94 2001/07/03 16:55:10 rich Exp $

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

A standard C<ftpd.conf> file is supplied with the distribution.
Full documentation for all the possible options which you
may use in this file is contained in this manual page. See
the section CONFIGURATION below.

You should edit the standard file and then copy it
to C</etc/ftpd.conf>:

  cp ftpd.conf /etc/
  chown root.root /etc/ftpd.conf
  chmod 0644 /etc/ftpd.conf

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

=head2 CONFIGURATION

A standard C</etc/ftpd.conf> file is supplied with 
C<Net::FTPServer> in the distribution. The possible
configuration options are listed in full below.

=over 4

=item E<lt>Include filenameE<gt>

Use the E<lt>Include filenameE<gt> directive to include
the contents of C<filename> directly at the current point
within the configuration file.

You cannot use E<lt>IncludeE<gt> within a E<lt>HostE<gt>
section, or at least you I<can> but it wonE<39>t work the
way you expect.

=item debug

Run with debugging. Equivalent to the command line -d option.

Default: 0

Example: C<debug: 1>

=item port

The TCP port number on which the FTP server listens when
running in daemon mode (see C<daemon mode> option below).

Default: The standard ftp/tcp service port from C</etc/services>

Example: C<port: 8021>

=item daemon mode

Run as a daemon. If set, the FTP server will open a listening
socket on its default port number, accept new connections and
fork off a new process to handle each connection. If not set
(the default), the FTP server will handle a single connection
on stdin/stdout, which is suitable for use from inetd.

The equivalent command line options are -s and -S.

Default: 0

Example: C<daemon mode: 1>

=item run in background

Run in the background. If set, the FTP server will fork into
the background before running.

The equivalent command line option is -S.

Default: 0

Example: C<run in background: 1>

=item maintainer email

MaintainerE<39>s email address.

Default: root@I<hostname>

Example: C<maintainer email: bob@example.com>

=item timeout

Timeout on control connection. If a command has not been
received after this many seconds, the server drops the
connection. You may set this to zero to disable timeouts
completely (although this is not recommended).

Default: 900 (seconds)

Example: C<timeout: 600>

=item limit memory

=item limit nr processes

=item limit nr files

Resource limits. These limits are applied to each child
process and are important in avoiding denial of service (DoS)
attacks against the FTP server.

 Resource         Default   Unit
 limit memory        8192   KBytes  Amount of memory per child
 limit nr processes     5   (none)  Number of processes
 limit nr files        20   (none)  Number of open files

Example: 

 limit memory:       16384
 limit nr processes:    10
 limit nr files:        40

=item max clients

Limit on the number of clients who can simultaneously connect.
If this limit is ever reached, new clients will immediately be
closed.  It will not even ask the client to login.  This
feature works in daemon mode only.

Default: 255

Example: C<max clients: 600>

=item max clients message

Message to display when ``max clients'' has been reached.

You may use the following % escape sequences within the
message for internal variables:

 %x  ``max clients'' setting that has been reached
 %E  maintainer email address (from ``maintainer email''
     setting above)
 %G  time in GMT
 %R  remote hostname or IP address if ``resolve addresses''
     is not set
 %L  local hostname
 %T  local time
 %%  just an ordinary ``%''

Default: Maximum connections reached

Example: C<max clients message: Only %x simultaneous connections allowed.  Please try again later.>

=item resolve addresses

Resolve addresses. If set, attempt to do a reverse lookup on
client addresses for logging purposes. If you set this then
some clients may experience long delays when they try to
connect. Not recommended on high load servers.

Default: 0

Example: C<resolve addresses: 1>

=item require resolved addresses

Require resolved addresses. If set, client addresses must validly resolve
otherwise clients will not be able to connect. If you set this
then some clients will not be able to connect, even though it is
probably the fault of their ISP.

Default: 0

Example: C<require resolved addresses: 1>

=item change process name

Change process name. If set (the default) then the FTP server will
change its process name to reflect the IP address or hostname of
the client. If not set then the FTP server will not try to change
its process name.

Default: 1

Example: C<change process name: 0>

=item greeting type

Greeting type. The greeting is printed before the user has logged in.
Possible greeting types are:

    full     Full greeting, including hostname and version number.
    brief    Hostname only.
    terse    Nothing
    text     Display greeting from ``greeting text'' option.

The SITE VERSION command can also reveal the version number. You
may need to turn this off by setting C<allow site version command: 0>
below.

Default: full

Example: C<greeting type: text>

=item greeting text

Greeting text. If the C<greeting type> is set to C<text> then this
contains the text to display.

Default: none

Example: C<greeting text: Hello. IE<39>ll be your server today.>

=item welcome type

Welcome type. The welcome is printed after a user has logged in.
Possible welcome types are:

    normal   Normal welcome message: ``Welcome <<username>>.''
    text     Take the welcome message from ``welcome text'' option.
    file     Take the welcome message from ``welcome file'' file.

Default: normal

Example: C<welcome type: text>

=item welcome text

If C<welcome type> is set to C<text>, then this contains the text
to be printed after a user has logged in.

You may use the following % escape sequences within the welcome
text to substitute for internal variables:

 %C  current working directory
 %E  maintainer's email address (from ``maintainer email''
     setting above)
 %G  time in GMT
 %R  remote hostname or IP address if ``resolve addresses''
     is not set
 %L  local hostname
 %m  user's home directory (see ``home directory'' below)
 %T  local time
 %U  username given when logging in
 %u  currently a synonym for %U, but in future will be
     determined from RFC931 authentication, like wu-ftpd
 %%  just an ordinary ``%''

Default: none

Example: C<welcome text: Welcome to this FTP server.>

=item welcome file

If C<welcome type> is set to C<file>, then this contains the file
to be printed after a user has logged in.

You may use any of the % escape sequences defined in C<welcome text>
above.

Default: none

Example: C<welcome file: /etc/motd>

=item home directory

Home directory. This is the home directory where we put the
user once they have logged in. This only applies to non-anonymous
logins. Anonymous logins are always placed in "/", which is at the
root of their chrooted environment.

You may use an absolute path here, or else one of the following
special forms:

 %m   Use home directory from password file or from NSS.
 %U   Username.
 %%   A single % character.

For example, to force a user to start in C<~/anon-ftp> when they
log in, set this to C<%m/anon-ftp>.

Note that setting the home directory does not perform a chroot.
Use the C<root directory> setting below to jail users into a
particular directory.

Home directories are I<relative> to the current root directory.

In the anonymous read-only (ro-ftpd) personality, set home
directory to C</> or else you will get a warning whenever a user
logs in.

Default: %m

Examples:

 home directory: %m/anon-ftp
 home directory: /

=item root directory

Root directory. Immediately after logging in, perform a chroot
into the named directory. This only applies to non-anonymous
logins, and furthermore it only applies if you have a non-database
VFS installed. Database VFSes typically cannot perform chroot
(or, to be more accurate, they have a different concept of
chroot - typically assigning each user their own completely
separate namespace).

You may use %m and %U as above.

For example, to jail a user under C<~/anon-ftp> after login, do:

  home directory: /
  root directory: %m/anon-ftp

Notice that the home directory is I<relative> to the current
root directory.

Default: (none)

Example: C<root directory: %m/anon-ftp>

=item time zone

Time zone to be used for MDTM and LIST stat information.

Default: GMT

Examples:

 time zone: Etc/GMT+3
 time zone: Europe/London
 time zone: US/Mountain

=item local address

Local addresses. If you wish the FTP server (in daemon mode) to
only bind to a particular local interface, then give its address
here.

Default: none

Example: C<local address: 127.0.0.1>

Allow anonymous access. If set, then allow anonymous access through
the C<ftp> and C<anonymous> accounts.

Default: 0

Example: C<allow anonymous: 1>

=item anonymous password check

=item anonymous password enforce

Validate email addresses. Normally when logging in anonymously,
you are asked to enter your email address as a password. These options
can be used to check and enforce email addresses in this field (to
some extent, at least -- you obviously canE<39>t force someone to
enter a true email address).

The C<anonymous password check> option may be set to C<rfc822>,
C<no browser>, C<trivial> or C<none>. If set to C<rfc822> then
the user must enter a valid RFC 822 email address as password. If
set to C<no browser> then a valid RFC 822 email address must be
entered, and various common browser email addresses like
C<mozilla@> and C<IEI<ver>User@> are refused. If set to C<trivial>
then we just check that the address contains an @ char. If set to
C<none>, then we do no checking. The default is C<none>.

If the C<anonymous password enforce> option is set and the
password fails the check above, then the user will not be allowed
to log in. The default is 0 (unset).

These options only have effect when C<allow anonymous> is set.

Example:

 anonymous password check: rfc822
 anonymous password enforce: 1

=item allow proxy ftp

Allow proxy FTP. If this is set, then the FTP server can be told to
actively connect to addresses and ports on any machine in the world.
This is not such a great idea, but required if you follow the RFC
very closely. If not set (the default), the FTP server will only
connect back to the client machine.

Default: 0

Example: C<allow proxy ftp: 1>

=item allow connect low port

Allow the FTP server to connect back to ports E<lt> 1024. This is rarely
useful and could pose a serious security hole in some circumstances.

Default: 0

Example: C<allow connect low port: 1>

=item max login attempts

Maximum number of login attempts before we drop the connection
and issue a warning in the logs. Wu-ftpd defaults this to 5.

Default: 3

Example: C<max login attempts: 5>

=item pam authentication

Use PAM for authentication. Required on systems such as Red Hat Linux
and Solaris which use PAM for authentication rather than the normal
C</etc/passwd> mechanisms. You will need to have the Authen-PAM Perl
module installed for this to work.

Default: 0

Example: C<pam authentication: 1>

=item pam application name

If PAM authentication is enabled, then this is the PAM application
name. I have used C<ftp> as the default which is the same name
that wu-ftpd chooses. FreeBSD users will want to use C<ftpd> here.

Default: ftp

Example: C<pam application name: ftpd>

=item passive port range

What range of local ports will the FTP server listen on in passive
mode? Choose a range here like C<1024-5999,49152-65535>. The special
value C<0> means that the FTP server will use a kernel-assigned
ephemeral port.

Default: 49152-65535

Example: C<passive port range: 0>

=item pidfile

Location of the file to store the process ID (PID).
Applies only to the deamonized process, not the child processes.

Default: (no pidfile created)

Example: C<pidfile: /var/run/ftpd.pid>

=item client logging

Location to store all client commands sent to the server.
The format is the date, the pid, and the command.
Following the pid is a "-" if not authenticated the
username if the connection is authenticated.
Example of before and after authentication:

 [Wed Feb 21 18:41:32 2001][23818:-]USER rob
 [Wed Feb 21 18:41:33 2001][23818:-]PASS 123456
 [Wed Feb 21 18:41:33 2001][23818:*]SYST

Default: (no logging)

Examples:

 client logging: /var/log/ftpd.log
 client logging: /tmp/ftpd_log.$hostname

=item hide passwords in client log

If set to 1, then password (C<PASS>) commands will not be
logged in the client log. This option has no effect unless
client logging is enabled.

Default: 0 (PASS lines will be shown)

Example: C<hide passwords in client log: 1>

=item enable syslog

Enable syslogging. If set, then Net::FTPServer will send much
information to syslog. On many systems, this information will
be available in /var/log/messages or /var/adm/messages. If
clear, syslogging is disabled.

Default: 1

Example: C<enable syslog: 0>

=item ident timeout

Timeout for ident authentication lookups.
A timeout (in seconds) must be specified in order to
enable ident lookups.  There is no way to specify an
infinite timeout.  Use 0 to disable this feature.

Default: 0

Example: C<ident timeout: 10>

=item access control rule

=item user access control rule

=item retrieve rule

=item store rule

=item delete rule

=item list rule

=item mkdir rule

=item rename rule

Access control rules.
 
Access control rules are all specified as short snippets of
Perl script. This allows the maximum configurability -- you
can express just about any rules you want -- but at the price
of learning a little Perl.

You can use the following variables from the Perl:

 $hostname      Resolved hostname of the client [1]
 $ip            IP address of the client
 $user          User name [2]
 $user_is_anonymous  True if the user is an anonymous user [2]
 $pathname      Full pathname of the file being affected [2]
 $filename      Filename of the file being affected [2,3]
 $dirname       Directory name containing file being affected [2]
 $type          'A' for ASCII, 'B' for binary, 'L8' for local 8-bit
 $form          Always 'N'
 $mode          Always 'S'
 $stru          Always 'F'

Notes:

[1] May be undefined, particularly if C<resolve addresses> is not set.

[2] Not available in C<access control rule> since the user has not
logged in at this point.

[3] Not available for C<list directory rule>.

Access control rule. The FTP server will not accept any connections
from a site unless this rule succeeds. Note that only C<$hostname>
and C<$ip> are available to this rule, and unless C<resolve addresses>
and C<require resolved addresses> are both set C<$hostname> may
be undefined.

Default: 1

Examples:

 (a) Deny connections from *.badguys.com:

     access control rule: defined ($hostname) && \
                          $hostname !~ /\.badguys\.com$/

 (b) Only allow connections from local network 10.0.0.0/24:

     access control rule: $ip =~ /^10\./

User access control rule. After the user logs in successfully,
this rule is then called to determine if the user may be permitted
access.

Default: 1

Examples:

 (a) Only allow ``rich'' to log in from 10.x.x.x network:

     user access control rule: $user ne "rich" || \
                               $ip =~ /^10\./

 (b) Only allow anonymous users to log in if they come from
     hosts with resolving hostnames (``resolve addresses'' must
     also be set):

     user access control rule: !$user_is_anonymous || \
                               defined ($hostname)

 (c) Do not allow user ``jeff'' to log in at all:

     user access control rule: $user ne "jeff"

Retrieve rule. This rule controls who may retrieve (download) files.

Default: 1

Examples:

 (a) Do not allow anyone to retrieve ``/etc/*'' or any file anywhere
     called ``.htaccess'':

     retrieve rule: $dirname !~ m|^/etc/| && $filename ne ".htaccess"

 (b) Only allow anonymous users to retrieve files from under the
     ``/pub'' directory.

     retrieve rule: !$user_is_anonymous || $dirname =~ m|^/pub/|

Store rule. This rule controls who may store (upload) files.

In the anonymous read-only (ro-ftpd) personality, it is not
possible to upload files anyway, so setting this rule has no
effect.

Default: 1

Examples:

 (a) Only allow users to upload files to the ``/incoming''
     directory.

     store rule: $dirname =~ m|^/incoming/|

 (b) Anonymous users can only upload files to ``/incoming''
     directory.

     store rule: !$user_is_anonymous || $dirname =~ m|^/incoming/|

 (c) Disable file upload.

     store rule: 0

Delete rule. This rule controls who may delete files or rmdir directories.

In the anonymous read-only (ro-ftpd) personality, it is not
possible to delete files anyway, so setting this rule has no
effect.

Default: 1

Example: C<delete rule: 0>

List rule. This rule controls who may list out the contents of a
directory.

Default: 1

Example: C<list rule: $dirname =~ m|^/pub/|>

Mkdir rule. This rule controls who may create a subdirectory.

In the anonymous read-only (ro-ftpd) personality, it is not
possible to create directories anyway, so setting this rule has
no effect.

Default: 1

Example: C<mkdir rule: 0>

Rename rule. This rule controls which files or directories can be renamed.

Default: 1

Example: C<rename rule: $pathname !~ m|/.htaccess$|>

=item chdir message file

Change directory message file. If set, then the first time (per
session) that a user goes into a directory which contains a file
matching this name, that file will be displayed.

The file may contain any of the % escape sequences available.
See C<welcome text> documentation above.

Default: (none)

Example: C<chdir message file: .message>

=item allow rename to overwrite

Allow the rename (RNFR/RNTO) command to overwrite files. If unset,
then we try to test whether the rename command would overwrite a
file and disallow it. However there are some race conditions with
this test.

Default: 1

Example: C<allow rename to overwrite: 0>

=item allow store to overwrite

Allow the store commands (STOR/STOU/APPE) to overwrite files. If unset,
then we try to test whether the store command would overwrite a
file and disallow it. However there are some race conditions with
this test.

Default: 1

Example: C<allow store to overwrite: 0>

=item alias

Define an alias C<name> for directory C<dir>. For example, the command
C<alias: mirror /pub/mirror> would allow the user to access the
C</pub/mirror> directory directly just by typing C<cd mirror>.

Aliases only apply to the cd (CWD) command. The C<cd foo> command checks
for directories in the following order:

 foo in the current directory
 an alias called foo
 foo in each directory in the cdpath (see ``cdpath'' command below)

You may list an many aliases as you want.

Alias names cannot contain slashes (/).

Although alias dirs may start without a slash (/), this is unwise and
itE<39>s better that they always start with a slash (/) char.

General format: C<alias: I<name> I<dir>>

=item cdpath

Define a search path which is used when changing directories. For
example, the command C<cdpath: /pub/mirror /pub/sites> would allow
the user to access the C</pub/mirror/ftp.cpan.org> directory
directly by just typing C<cd ftp.cpan.org>.

The C<cd foo> command checks for directories in the following order:

 foo in the current directory
 an alias called foo (see ``alias'' command above)
 foo in each directory in the cdpath

General format: C<cdpath: I<dir1> [I<dir2> [I<dir3> ...]]>

=item allow site version command

SITE VERSION command. If set, then the SITE VERSION command reveals
the current Net::FTPServer version string. If unset, then the command
is disabled.

Default: 1

Example: C<allow site version command: 0>

=item allow site exec command

SITE EXEC command. If set, then the SITE EXEC command allows arbitrary
commands to be executed on the server as the current user. If unset,
then this command is disabled. The default is disabled for obvious
security reasons.

If you do allow SITE EXEC, you may need to increase the per process
memory, processes and files limits above.

Default: 0

Example: C<allow site exec command: 1>

=item site command

Custom SITE commands. Use this command to define custom SITE
commands. Please read the section LOADING CUSTOMIZED SITE
COMMANDS in this manual page for more detailed information.

The C<site command> command has the form:

C<site command: I<cmdname> I<file>>

I<cmdname> is the name of the command (eg. for SITE README you
would set I<cmdname> == C<readme>). I<file> is a file containing the
code of the site command in the form of an anonymous Perl
subroutine. The file should have the form:

 sub {
   my $self = shift;		# The FTPServer object.
   my $cmd = shift;		# Contains the command itself.
   my $rest = shift;		# Contains any parameters passed by the user.

      :     :
      :     :

   $self->reply (RESPONSE_CODE, RESPONSE_TEXT);
 }

You may define as many site commands as you want. You may also
override site commands from the current personality here.

Example:

 site command: quota /usr/local/lib/ftp/quota.pl

and the file C</usr/local/lib/ftp/quota.pl> contains:

 sub {
   my $self = shift;		# The FTPServer object.
   my $cmd = shift;		# Contains "QUOTA".
   my $rest = shift;		# Contains parameters passed by user.

   # ... Some code to compute the user's quota ...

   $self->reply (200, "Your quota is $quota MB.");
 }

The client types C<SITE QUOTA> and the server responds with:

 "200 Your quota is 12.5 MB.".

=item E<lt>Host hostnameE<gt> ... E<lt>/HostE<gt>

E<lt>Host hostnameE<gt> ... E<lt>/HostE<gt> encloses
commands which are applicable only to a particular
host. C<hostname> may be either a fully-qualified
domain name (for IP-less virtual hosts) or an IP
address (for IP-based virtual hosts). You should read
the section VIRTUAL HOSTS in this manual page for
more information on the different types of virtual
hosts and how to set it up in more detail.

Note also that unless you have set C<enable virtual hosts: 1>,
all E<lt>HostE<gt> sections will be ignored.

=item enable virtual hosts

Unless this option is uncommented, virtual hosting is disabled
and the E<lt>HostE<gt> sections in the configuration file have no effect.

Default: 0

Example: C<enable virtual hosts: 1>

=item virtual host multiplex

IP-less virtual hosts. If you want to enable IP-less virtual
hosts, then you must set up your DNS so that all hosts map
to a single IP address, and place that IP address here. This
is roughly equivalent to the Apache C<NameVirtualHost> option.

IP-less virtual hosting is an experimental feature which
requires changes to clients.

Default: (none)

Example: C<virtual host multiplex: 1.2.3.4>

Example E<lt>HostE<gt> section. Allow the dangerous SITE EXEC command
on local connections. (Note that this is still dangerous).

 <Host localhost.localdomain>
   ip: 127.0.0.1
   allow site exec command: 1
 </Host>

Example E<lt>HostE<gt> section. This shows you how to do IP-based
virtual hosts. I assume that you have set up your DNS so that
C<ftp.bob.example.com> maps to IP C<1.2.3.4> and C<ftp.jane.example.com>
maps to IP C<1.2.3.5>, and you have set up suitable IP aliasing
in the kernel.

You do not need the C<ip:> command if you have configured reverse
DNS correctly AND you trust your local DNS servers.

 <Host ftp.bob.example.com>
   ip: 1.2.3.4
   root directory: /home/bob
   home directory: /
   user access control rule: $user eq "bob"
   maintainer email: bob@bob.example.com
 </Host>

 <Host ftp.jane.example.com>
   ip: 1.2.3.5
   root directory: /home/jane
   home directory: /
   allow anonymous: 1
   user access control rule: $user_is_anonymous
   maintainer email: jane@jane.example.com
 </Host>

These rules set up two virtual hosts called C<ftp.bob.example.com>
and C<ftp.jane.example.com>. The former is located under bob's
home directory and only he is allowed to log in. The latter is
located under jane's home directory and only allows anonymous
access.

Example E<lt>HostE<gt> section. This shows you how to do IP-less
virtual hosts. Note that IP-less virtual hosts are a highly
experimental feature, and require the client to support the
HOST command.

You need to set up your DNS so that both C<ftp.bob.example.com>
and C<ftp.jane.example.com> point to your own IP address.

 virtual host multiplex: 1.2.3.4

 <Host ftp.bob.example.com>
   root directory: /home/bob
   home directory: /
   user access control rule: $user eq "bob"
 </Host>

 <Host ftp.jane.example.com>
   root directory: /home/jane
   home directory: /
   allow anonymous: 1
   user access control rule: $user_is_anonymous
 </Host>

=item log socket type

Socket type for contacting syslog. This is the argument to
the C<Sys::Syslog::setlogsock> function.

Default: unix

Example: C<log socket type: inet>

=item listen queue

Length of the listen queue when running in daemon mode.

Default: 10

Example: C<listen queue: 20>

=item tcp window

Set TCP window. See RFC 2415
I<Simulation Studies of Increased Initial TCP Window Size>.
This setting only affects the data
socket. ItE<39>s not likely that you will need to or should change
this setting from the system-specific default.

Default: (system-specific TCP window size)

Example: C<tcp window: 4380>

=item tcp keepalive

Set TCP keepalive.

Default: (system-specific keepalive setting)

Example: C<tcp keepalive: 1>

=item command filter

Command filter. If set, then all commands are checked against
this regular expression before being executed. If a command
doesnE<39>t match the filter, then the command connection is
immediately dropped. This is equivalent to the C<AllowFilter>
command in ProFTPD. Remember to include C<^...$> around the filter.

Default: (no filter)

Example: C<command filter: ^[A-Za-z0-9 /]+$>

=item command wait

Go slow. If set, then the server will sleep for this many seconds
before beginning to process each command. This command would be
a lot more useful if you could apply it only to particular
classes of connection.

Default: (no wait)

Example: C<command wait: 5>

=item no authentication commands

The list of commands which a client may issue before they have
authenticated themselves is very limited. Obviously C<USER> and
C<PASS> are allowed (otherwise a user would never be able to log
in!), also C<QUIT>, C<LANG>, C<HOST> and C<FEAT>. C<HELP> is also permitted
(although dubious). Any other commands not on this list will
result in a I<530 Not logged in.> error.

This list ought to contain at least C<USER>, C<PASS> and C<QUIT>
otherwise the server wonE<39>t be very functional.

Some commands cannot be added here -- eg. adding C<CWD> or C<RETR>
to this list is likely to make the FTP server crash, or else enable
users to read files only available to root. Hence use this with
great care.

Default: USER PASS QUIT LANG HOST FEAT HELP

Example: C<no authentication commands: USER PASS QUIT>

=item E<lt>PerlE<gt> ... E<lt>/PerlE<gt>

Use the E<lt>PerlE<gt> directive to write Perl code directly
into your configuration file. Here is a simple example:

 <Perl>
 use Sys::Hostname;
 $config{'maintainer email'} = "root\@" . hostname ();
 $config{port} = 8000 + 21;
 $config{debug} = $ENV{FTP_DEBUG} ? 1 : 0;
 </Perl>

As shown in the example, to set a configuration option called
C<foo>, you simply assign to the variable C<$config{foo}>.

All normal Perl functionality is available to you, including
use of C<require> if you need to run an external Perl script.

The E<lt>PerlE<gt> and E<lt>/PerlE<gt> directives must each appear
on a single line on their own.

You cannot use a E<lt>PerlE<gt> section within a E<lt>HostE<gt>
section. Instead, you must simulate it by assigning to the
C<%host_config> variable like this:

 <Perl>
 $host_config{'localhost.localdomain'}{ip} = "127.0.0.1";
 $host_config{'localhost.localdomain'}{'allow site exec command'}= 1;
 </Perl>

The above is equivalent to the following ordinary E<lt>HostE<gt>
section:

 <Host localhost.localdomain>
   ip: 127.0.0.1
   allow site exec command: 1
 </Host>

You may also assign to the C<$self> variable in order to set
variables directly in the C<Net::FTPServer> object itself. This
is pretty hairy, and hence not recommended, but you dig your own
hole if you want. Here is a contrived example:

 <Perl>
 $self->{version_string} = "my FTP server/1.0";
 </Perl>

A cleaner, but more complex way to do this would be to use
a personality.

=back 4

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
  200-$Id: FTPServer.pm,v 1.94 2001/07/03 16:55:10 rich Exp $
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

$VERSION = '1.0.19';
$RELEASE = 3;

use Config;
use Getopt::Long qw(GetOptions);
use Sys::Hostname;
use Sys::Syslog qw();
use Socket;
use IO::Socket;
use IO::File;
use BSD::Resource;
use Carp;
use Digest::MD5;
use POSIX qw(setsid dup dup2 ceil strftime WNOHANG);
use Fcntl qw(F_SETOWN F_SETFD FD_CLOEXEC);

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
    my $args = shift || [@ARGV];

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

    # Initialize Max Clients Settings
    $self->{_max_clients} =
      $self->config ("max clients") || 255;
    $self->{_max_clients_message} =
      $self->config ("max clients message") ||
	"Maximum connections reached";

    # Open syslog.
    $self->{_enable_syslog} =
      (!defined $self->config ("enable syslog") ||
       $self->config ("enable syslog")) &&
      !$self->{_test_mode};

    if ($self->{_enable_syslog})
      {
	if (defined $self->config ("log socket type")) {
	  Sys::Syslog::setlogsock $self->config ("log socket type")
	} else {
	  Sys::Syslog::setlogsock "unix";
	}

	Sys::Syslog::openlog "ftpd", "pid", "daemon";
	$self->log ("info", "%s running", $self->{version_string});
      }

    # Set up a hook for warn and die so that these cause messages to
    # be echoed to the syslog.
    $SIG{__WARN__} = sub {
      $self->log ("warning", $_[0]);
      warn $_[0];
    };
    $SIG{__DIE__} = sub {
      $self->log ("err", $_[0]);
      die $_[0];
    };

    # Set up signal handlers to give us a clean exit.
    # Note that these are inherited if we fork.
    $SIG{PIPE} = sub {
      $self->log ("info", "client closed connection abruptly") if $self;
      exit;
    };
    $SIG{TERM} = sub {
      $self->log ("info", "exiting on TERM signal");
      $self->reply (421, "Manual shutdown from server");
      $self->_log_line ("[TERM RECEIVED]");
      exit;
    };
    $SIG{INT} = sub {
      $self->log ("info", "exiting on keyboard INT signal");
      exit;
    };
    $SIG{QUIT} = sub {
      $self->log ("info", "exiting on keyboard QUIT signal");
      exit;
    };
    $SIG{HUP} = sub {
      $self->log ("info", "exiting on HUP signal");
      exit;
    };
    $SIG{ALRM} = sub {
      $self->log ("info", "exiting on ALRM signal");
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
	if ($log_file =~ m%^([/\w\-\.]+)$%)
	  {
	    $self->{_log_file} = $log_file = $1;
	  }
	else
	  {
	    die "Refusing to create weird looking client log file: $log_file";
	  }

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
	      $self->log ("err", "site command: $filename: must return an anonymous subroutine when evaluated (skipping)");
	    }
	  }
	else
	  {
	    if ($!) {
	      $self->log ("err", "site command: $filename: $! (ignored)")
	    } else {
	      $self->log ("err", "site command: $filename: $@ (ignored)")
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
	  $self->log ("info", "shutting down daemon");
	  $self->_log_line ("[DAEMON Shutdown]");
	  exit;
	};

	local $SIG{HUP} = sub {
	  # Added 26 Feb 2001 by Rob Brown <rbrown@about-inc.com>

	  # Code to allow priviledged port bind()ing capability by
	  # unpriviledged user by reusing an already-bind()ed file
	  # descriptor.

	  # Duplicate bind()ed socket _ctrl_sock so the old one can be closed.
	  my $fake = new IO::Socket::INET;
	  $fake->fdopen (dup ($self->{_ctrl_sock}->fileno), "w");

	  # Make sure its FD_CLOEXEC bit is off so the exec'ed process
	  # can still use it.
	  $fake->fcntl (F_SETFD, my $flags = "");

	  # ENV will also be available to the exec'ed process.
	  $ENV{BIND} = $fake->fileno;

	  # Shutdown old _ctrl_sock to kick out of the blocking accept() call.
	  $self->{_ctrl_sock}->close;

	  # Preserve the new file descriptor until exec is called.
	  $self->{_hup} = $fake;

	  $self->log ("info", "received SIGHUP, Reloading configuration");
	  $self->_log_line ("[DAEMON Reloading configuration]");
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
		    $self->log ("info",
				   "IP-based virtual hosts: ".
				   "set site to $sitename");
		  }
		else
		  {
		    $self->log ("info",
				   "IP-based virtual hosts: ".
				   "no site found");
		  }
	      }
	  }
      }

    # Get the peername and other details of this socket.
    my ($peername, $peerport, $peeraddr, $peeraddrstring);

    if ( $peername = getpeername STDIN )
      {
	($peerport, $peeraddr) = unpack_sockaddr_in ($peername);
	$peeraddrstring = inet_ntoa ($peeraddr);
      }
    else
      {
	$peerport = 0;
	$peeraddr = inet_aton ( $peeraddrstring = "127.0.0.1" );
      }

    $self->_log_line ("[CONNECTION FROM $peeraddrstring:$peerport] \#".
		      (1 + $self->concurrent_connections));

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
	    $self->log ("err",
			   "cannot resolve address for connection from " .
			   "$peeraddrstring:$peerport");
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

	$self->log ("info", "connection from $peerinfodpy");

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

    # Implement Identification Protocol as explained in RFC 1413.
    # Some firewalls block the auth port which could make this
    # operation slow.  Wait until after the greeting is sent to the
    # client to signify that it is okay for commands to be sent while
    # the ident authentication is taking place.  This timeout is used
    # for both the connection and the "patience" desired for the
    # remote ident response.  Having a timeout also helps to avoid a
    # possible DoS on the FTP server.  There is no way to specify an
    # infinite timeout.  The directive "ident timeout: 0" will disable
    # this feature.

    my $ident_timeout = $self->config ("ident timeout");
    if (defined $ident_timeout && $ident_timeout > 0 &&
	defined $self->{peerport} && defined $self->{sockport} &&
	defined $self->{peeraddrstring})
      {
	my $got_bored = 0;
	my $ident;
	eval
	  {
	    local $SIG{__WARN__} = 'DEFAULT';
	    local $SIG{__DIE__}  = 'DEFAULT';
	    local $SIG{ALRM} = sub { $got_bored = 1; die "timed out"; };
	    alarm $ident_timeout;
	    $ident = new IO::Socket::INET
	      (PeerAddr  => $self->{peeraddrstring},
	       PeerPort  => "auth");
	  };

	if ($got_bored)
	  {
	    # Took too long to connect to remote auth port
	    # (probably because of a client-side firewall).
	    $self->_log_line ("[Ident auth failed: connection timed out]");
	    $self->log ("warning", "ident auth failed for $self->{peeraddrstring}: connection timed out");
	  }
	else
	  {
	    if (defined $ident)
	      {
		my $response;
		eval
		  {
		    local $SIG{__WARN__} = 'DEFAULT';
		    local $SIG{__DIE__}  = 'DEFAULT';
		    local $SIG{ALRM}
		      = sub { $got_bored = 1; die "timed out"; };
		    alarm $ident_timeout;
		    $ident->print ("$self->{peerport} , ",
				   "$self->{sockport}\r\n");
		    $response = $ident->getline;
		  };
		$ident->close;

		# Took too long to respond?
		if ($got_bored)
		  {
		    $self->_log_line ("[Ident auth failed: response timed out]");
		    $self->log ("warning", "ident auth failed for $self->{peeraddrstring}: response timed out");
		  }
		else
		  {
		    if ($response =~ /:\s*USERID\s*:\s*OTHER\s*:\s*(\S+)/)
		      {
			$self->{auth} = $1;
			$self->_log_line ("[IDENT AUTH VERIFIED: $self->{auth}\@$self->{peeraddrstring}]");
			$self->log ("info", "ident auth: $self->{auth}\@$self->{peeraddrstring}");
		      }
		    else
		      {
			$self->_log_line ("[Ident auth failed: invalid response]");
			$self->log ("warning", "ident auth failed for $self->{peeraddrstring}: invalid response");
		      }
		  }
	      }
	    else
	      {
		$self->_log_line ("[Ident auth failed: Connection refused]");
		$self->log ("warning", "ident auth failed for $self->{peeraddrstring}: Connection refused");
	      }
	  }
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

	# Immediately terminate if the parent died.
	# In standalone mode, this means the main daemon has terminated.
	# In inet mode, this means that inetd itself has terminated.
	# In either case, the system administrator may have new
	# configuration settings that need to be loaded so any current
	# FTP clients should not be able to run any new commands on the
	# old configuration for security reasons.
	if (getppid == 1)
	  {
	    $self->reply (421, "Manual Server Shutdown. Reconnect required.");
	    exit;
	  }

	# Restart alarm clock timer.
	alarm $self->{_idle_timeout};

	# When out-of-band data arrives (eg. when the client performs
	# an ABOR command), the client will send several telnet control
	# characters before the actual command. Drop those bytes now.
	s/^\377.// while m/^\377./;

	# Log client command if logging is enabled.
	$self->_log_line ($_)
	  unless /^PASS / && $self->config ("hide passwords in client log");

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
	    $self->log ("err",
			   "badly formed command received: %s", _escape($_));
	    $self->_log_line ("[Badly formed command]", _escape($_));
	    exit 0;
	  }

	my ($cmd, $rest) = (uc $1, $2);

	$self->log ("info", "command: (%s, %s)",
		       _escape($cmd), _escape($rest))
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
	    $self->log ("err",
			   "unknown command received: %s", _escape($_));
	    next;
	  }

	# Run the command.
	&{$self->{command_table}{$cmd}} ($self, $cmd, $rest);

	# Post-command hook.
	$self->post_command_hook;
      }

    $self->_log_line ("[ENDED BY CLIENT $self->{peeraddrstring}:$self->{peerport}]");
    $self->log ("info", "connection terminated normally");
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
    my $authenticated = $self->{authenticated} ? $self->{user} : "-";
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

	# Swap $VARIABLE with corresponding attribute (i.e., $hostname)
	$pidfile =~ s/\$(\w+)/$self->{$1}/g;
	if ($pidfile =~ m%^([/\w\-\.]+)$%)
	  {
	    $self->{_pidfile} = $1;
	    open (PID, ">$self->{_pidfile}")
	      or die "cannot write $pidfile: $!";
	    print PID "$$\n";
	    close PID;
	    eval "END {unlink('$1') if \$\$ == $$;}";
	  }
	else
	  {
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

    $self->log ("info", "forked into background");
  }

# Be a daemon (command line -s option).

sub _be_daemon
  {
    my $self = shift;

    $self->log ("info", "operating in daemon mode");
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

    # If existing socket already bind()ed, use that one
    if (exists $ENV{BIND} && $ENV{BIND} =~ /^(\d+)$/)
      {
	my $bind_fd = $1;
	$self->{_ctrl_sock} = new IO::Socket::INET;
	$self->{_ctrl_sock}->fdopen ($bind_fd, "w")
	  or die "socket: $!";
      }
    else
      {
	# Open a socket on the control port.
	$self->{_ctrl_sock} =
	  new IO::Socket::INET (@args)
	    or die "socket: $!";
      }

    # Set TCP keepalive?
    if (defined $self->config ("tcp keepalive"))
      {
	$self->{_ctrl_sock}->sockopt (SO_KEEPALIVE, 1)
	  or warn "setsockopt: SO_KEEPALIVE: $!";
      }

    # Initialize the children hash ref for max clients enforcement
    $self->{_children} = {};

    $self->post_bind_hook;

    # Automatically clean up zombie children.
    $SIG{CHLD} = sub
      {
	my $kid;
	while (($kid = waitpid (-1,WNOHANG)) > 0)
	  {
	    next unless ref $self->{_children};
	    # Client $kid just finished
	    delete $self->{_children}->{$kid};
	  }
	# Do not crash from attempting to dereference a number
	return unless ref $self->{_children};

	# Take care of a race condition where client B finishes
	# (causing another SIGCHLD) after client A finishes its
	# waitpid (de-zombied), but before reaching its delete.
	foreach (keys %{$self->{_children}})
	  {
	    # Quickly send a test signal to make sure all the
	    # _children processes are still running.  If not,
	    # remove it from the _children hash.
	    delete $self->{_children}->{$_} unless kill 0, $_;
	  }
      };

    # Accept new connections and fork off new process to handle it.
    for (;;)
      {
	$self->pre_accept_hook;
	if (!$self->{_ctrl_sock}->opened &&
	    !exists $self->{_hup})
	  {
	    die "control socket crashed somehow";
	  }

	# ACCEPT may be undefined if, for example, the TCP-level 3-way
	# handshake is not completed. If this happens, all we really want
	# to do is to retry the accept, not die. Thanks to
	# rbrown@about-inc.com for pointing this one out :-)

	my $sock;

	until (defined $sock)
	  {
	    $sock = $self->{_ctrl_sock}->accept
	      if $self->{_ctrl_sock}->opened;

	    # Received SIGHUP? Restart self.
	    if (exists $self->{_hup})
	      {
		exec ($0,@ARGV);
	      }

	    warn "accept: $!" unless defined $sock;
	  }

	if ($self->concurrent_connections >= $self->{_max_clients})
	  {
	    $sock->print ("500 ".
			  $self->_percent_substitutions ($self->{_max_clients_message}). 
			  "\r\n");
	    $sock->close;
	    warn "Max connections $self->{_max_clients} reached!";
	    $self->_log_line ("[Max connections $self->{_max_clients} reached]");
	    next;
	  }

	# Fork off a process to handle this connection.
	my $pid = fork;
	if (defined $pid)
	  {
	    if ($pid == 0)		# Child process.
	      {
		$self->log ("info", "starting child process")
		  if $self->{debug};

		# Don't handle SIGCHLD in the child process, in case the
		# personality tries to launch subprocesses.
		$SIG{CHLD} = "DEFAULT";

		# Wipe the hash within the child process to save memory
		$self->{_children} = $self->concurrent_connections;

		# Shutdown accepting file descriptor to allow successful
		# port bind() in case of a future daemon restart
		$self->{_ctrl_sock}->close;

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

	# A child has been successfully spawned.
	# So don't forget the kid's birthday!
	$self->{_children}->{$pid} = time;
      }				# End of for (;;) loop in ftpd parent process.
  }

sub concurrent_connections
  {
    my $self = shift;

    if (exists $self->{_children})
      {
	if (ref $self->{_children})
	  {
	    # Main Parent Server (exactly accurate)
	    return scalar keys %{$self->{_children}};
	  }
	else
	  {
	    # Child Process (slightly outdated count)
	    return $self->{_children};
	  }
      }
    else
      {
	# Not running as a daemon (eg. running from inetd). We don't
	# know the number of connections, but it's not likely to be
	# high, so just return 1.
	return 1;
      }
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
	    if ($sitename)
	      {
		die "$config_file:$lineno: cannot use <Include> inside a <Host> section. It will not do what you expect. See the Net::FTPServer(3) manual page for information.";
	      }

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

	# Special treatment: <Perl> sections.
	if (/^\s*<Perl>\s*$/i)
	  {
	    if ($sitename)
	      {
		die "$config_file:$lineno: cannot use <Perl> inside a <Host> section. It will not do what you expect. See the Net::FTPServer(3) manual page for information on the %host_config variable.";
	      }

	    # Suck in lines verbatim until we reach the end of this section.
	    my $perl_code = "";

	    while ($_ = $config->getline)
	      {
		$lineno++;
		last if /^\s*<\/Perl>\s*$/i;
		$perl_code .= $_;
	      }

	    unless ($_)
	      {
		die "$config_file:$lineno: unfinished <Perl> section";
	      }

	    # Untaint this code: it comes from a trusted source, namely
	    # the configuration file.
	    $perl_code =~ /(.*)/s;
	    $perl_code = $1;

#	    warn "executing perl code:\n$perl_code\n";

	    # Run it. It will write into local variables %config and
	    # %host_config.
	    my %config;
	    my %host_config;

	    eval $perl_code;
	    if ($@)
	      {
		die "$config_file:$lineno: $@";
	      }

	    # Examine what it's written into %config and %host_config
	    # and add those to the configuration.
	    foreach (keys %config)
	      {
		$self->_set_config ($_, $config{$_},
				    undef, $config_file, $lineno);
	      }

	    my $host;
	    foreach $host (keys %host_config)
	      {
		foreach (keys %{$host_config{$host}})
		  {
		    $self->_set_config ($_, $host_config{$host}{$_},
					$host, $config_file, $lineno);
		  }
	      }

	    next;
	  }

	if (/^\s*<\/Perl>\s*$/i)
	  {
	    die "$config_file:$lineno: unmatched </Perl>";
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

	$self->_set_config ($key, $value, $sitename, $config_file, $lineno);
      }
  }

sub _set_config
  {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    my $sitename = shift;
    my $config_file = shift;
    my $lineno = shift;

    # Convert the key to standard form so that small errors in the
    # FTP config file won't matter too much.
    $key = lc ($key);
    $key =~ tr/ / /s;

    # If the key is ``ip:'' then we treat it specially - adding it
    # to a hash from IP addresses to sites.
    if ($key eq "ip")
      {
	unless ($sitename)
	  {
	    die "$config_file:$lineno: ``ip:'' must only appear inside a <Host> section. See the Net::FTPServer(3) manual page for more information.";
	  }

	$self->{_config_ip_host}{$value} = $sitename;
      }

    # Prefix the sitename, if defined.
    $key = "$sitename:$key" if $sitename;

#    warn "configuration ($key, $value)";

    # Save this.
    $self->{_config}{$key} = [] unless exists $self->{_config}{$key};
    push @{$self->{_config}{$key}}, $value;
  }

# Before printing something received from the user to syslog, escape
# any strange characters using this function.

sub _escape
  {
    local $_ = shift;
    s/([^ -~])/sprintf ("\\x%02x", ord ($1))/ge;
    $_;
  }

=item $regex = $ftps->wildcard_to_regex ($wildcard)

This is a general library function shared between many of
the back-end database personalities. It converts a general
wildcard (eg. *.c) into a regular expression (eg. ^.*\.c$ ).

Thanks to: Terrence Monroe Brannon E<lt>terrence.brannon@oracle.comE<gt>.

=cut

sub wildcard_to_regex
  {
    my $self = shift;
    my $wildcard = shift;

    $wildcard =~ s,([^?*a-zA-Z0-9]),\\$1,g; # Escape punctuation.
    $wildcard =~ s,\*,.*,g; # Turn * into .*
    $wildcard =~ s,\?,.,g;  # Turn ? into .
    $wildcard = "^$wildcard\$"; # Bracket it.

    $wildcard;
}

=item $regex = $ftps->wildcard_to_sql_like ($wildcard)

This is a general library function shared between many of
the back-end database personalities. It converts a general
wildcard (eg. *.c) into the strange wildcardish format
used by SQL LIKE operator (eg. %.c).

=cut

sub wildcard_to_sql_like
  {
    my $self = shift;
    my $wildcard = shift;

    $wildcard =~ s/%/\\%/g;     # Escape any existing % and _.
    $wildcard =~ s/_/\\_/g;
    $wildcard =~ tr/*?/%_/;     # Translate to wierdo format.

    $wildcard;
}

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

    $self->log ("info", "reply: $code") if $self->{debug};
  }

=item $ftps->log ($level, $message, ...);

This function is identical to the normal C<syslog> function
to be found in C<Sys::Syslog>. However, it only uses syslog
if the C<enable syslog> configuration option is set to true.

Use this function instead of calling C<syslog> directly.

=cut

sub log
  {
    my $self = shift;

    Sys::Syslog::syslog @_ if $self->{_enable_syslog};
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
    else
      {
	delete $self->{user_is_anonymous};
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
	    $self->log ("notice", "repeated login attempts from %s:%d",
			   $self->{peeraddrstring},
			   $self->{peerport});

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

    # Set the timezone for responses.
    $ENV{TZ} = defined $self->config ("time zone")
      ? $self->config ("time zone")
      : "GMT";

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
	$self->log ("warning",
		       "no home directory for user: $self->{user}");
      }

  }

sub _percent_substitutions
  {
    my $self = shift;
    local $_ = shift;

    # See CONFIGURATION section on ``welcome text'' for a list of
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
    s/%x/$self->{_max_clients}/ge;
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

# Assuming we are running as root, drop privileges and change
# to user called $username who has uid $uid and gid $gid. There
# is no interface to initgroups, so we have to do that by
# hand -- yuck.
sub _drop_privs
  {
    my $self = shift;
    my $uid = shift;
    my $gid = shift;
    my $username = shift;

    # Get the list of extra groups to pass to setgroups(2).
    my @groups = ();

    my @g;
    while (@g = getgrent)
      {
	my ($gr_name, $gr_passwd, $gr_gid, $gr_members) = @g;
	my @members = split /\s+/, $gr_members;

	foreach (@members)
	  {
	    push @groups, $gr_gid if $_ eq $username;
	  }
      }

    setgrent;			# Rewind the pointer.

    # Set the effective GID/UID.
    $) = join (" ", $gid, $gid, @groups);
    $> = $uid;

    # Set the real GID/UID.
    $( = $gid;
    $< = $uid;
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

    if ($filename &&
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
    $self->log ("info", "connection terminated normally");

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

    # Access control.
    unless ($self->_eval_rule ("rename rule",
			       $dirh->pathname . $filename,
			       $filename, $dirh->pathname))
      {
	$self->reply (550, "RNFR command denied by server configuration.");
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

    if (!$dirh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Access control.
    unless ($self->_eval_rule ("rename rule",
			       $dirh->pathname . $filename,
			       $filename, $dirh->pathname))
      {
	$self->reply (550, "RNTO command denied by server configuration.");
	return;
      }

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

    if (!$dirh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

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
	  }

	my $r = $dirh->_list_status ($wildcard);

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
    # to respond to flags on the 'ls command line'.
    # Handle the "-l" flag by just calling LIST instead of NLST.
    # This is particularly an issue with ncftp 2.4.3,
    # emacs / Ange-ftp, commandline "ftp" on Windows Platform,
    # netftp, and some old versions of WSFTP.  I would think that if
    # the client wants a nice pretty listing, that they should use
    # the LIST command, but for some reasons they insist on trying
    # to pass arguments to NLST and expect them to work.
    # Examples:
    # NLST -al /.
    # NLST -AL *.htm
    return $self->_LIST_command ($cmd, $rest) if $rest =~ /^\-\w*l/i;
    $rest =~ s/^-\w+\s?//;

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

    if ($self->{type} eq 'A' && $fileh->can_read)
      {
	# ASCII mode: we have to count the characters by hand.
	if (my $file = $fileh->open ("r"))
	  {
	    $size = 0;
	    $size++ while (defined ($file->getc));
	    $file->close;
	  }
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
    my $fmt_time = strftime "%Y%m%d%H%M%S", localtime ($time);

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

	unless ($fileh)
	  {
	    $self->reply (550, "File or directory not found.");
	    return;
	  }
      }

    # Check access control.
    unless ($self->_eval_rule ("list rule",
			       undef, undef, $fileh->pathname))
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
	    my $fmt_time = strftime "%Y%m%d%H%M%S", localtime ($mtime);
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
	$path = "." if $path eq "";
      }

    # Parse the first elements of path until we find the appropriate
    # working directory.
    my @elems = split /\//, $path;
    my $filename = pop @elems;

    unless (defined $filename && length $filename)
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
    my $fileh =
      ($filename eq ".") ? $dirh :
	($filename eq "..") ? $dirh->parent :
	  $dirh->get($filename);

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

    my $fmt_time = strftime $fmt, localtime ($mtime);

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

Richard Jones (rich@annexia.org),
Rob Brown (rbrown at about-inc.com),
Azazel (azazel at azazel.net).

=head1 COPYRIGHT

Copyright (C) 2000 Biblio@Tech Ltd., Unit 2-3, 50 Carnwath Road,
London, SW6 3EG, UK

Copyright (C) 2000-2001 Richard Jones (rich@annexia.org).

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
