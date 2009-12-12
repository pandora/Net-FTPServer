#!/usr/bin/perl -w

# $Id: 350filters.t,v 1.3 2001/10/28 16:31:14 rich Exp $

use strict;
use Test;
use POSIX qw(dup2);
use IO::Handle;
use FileHandle;

BEGIN {
  plan tests => 13;
}

use Net::FTPServer::InMem::Server;

pipe INFD0, OUTFD0 or die "pipe: $!";
pipe INFD1, OUTFD1 or die "pipe: $!";
my $pid = fork ();
die unless defined $pid;
unless ($pid) {			# Child process (the server).
  POSIX::dup2 (fileno INFD0, 0);
  POSIX::dup2 (fileno OUTFD1, 1);
  close INFD0;
  close OUTFD0;
  close INFD1;
  close OUTFD1;
  my $ftps = Net::FTPServer::InMem::Server->run
    (['--test', '-d', '-C', '/dev/null',
      '-o', 'limit memory=-1',
      '-o', 'limit nr processes=-1',
      '-o', 'limit nr files=-1']);
  exit;
}

# Parent process (the test script).
close INFD0;
close OUTFD1;
OUTFD0->autoflush (1);

$_ = <INFD1>;
print OUTFD0 "USER rich\r\n";
$_ = <INFD1>;
ok (/^331/);

print OUTFD0 "PASS 123456\r\n";
$_ = <INFD1>;
ok (/^230 Welcome rich\./);

# Use binary mode.
print OUTFD0 "TYPE I\r\n";
$_ = <INFD1>;
ok (/^200/);

# Enter passive mode and get a port number.
print OUTFD0 "PASV\r\n";
$_ = <INFD1>;
ok (/^227 Entering Passive Mode \(127,0,0,1,(.*),(.*)\)/);

my $port = $1 * 256 + $2;

# Generate a file containing some textual data.
my $tmpfile = ".350filters.t.$$";
open TMP, ">$tmpfile" or die "$tmpfile: $!";
print TMP <<EOT;
Linux is a Unix clone written from scratch by Linus Torvalds with
assistance from a loosely-knit team of hackers across the Net.  It
aims towards POSIX compliance.  It has all the features you would
expect in a modern fully-fledged Unix, including true multitasking,
virtual memory, shared libraries, demand loading, shared copy-on-write
executables, proper memory management and TCP/IP networking.  It is
distributed under the GNU General Public License - see the
accompanying COPYING file for more details.
EOT
close TMP;

# Upload files.
ok (upload_file ($tmpfile));

# Download and check files.
ok (download_file ($tmpfile, "$tmpfile.a"));
ok (compare_files ($tmpfile, "$tmpfile.a"));

ok (download_file ("$tmpfile.Z", "$tmpfile.a"));
system ("compress -cd $tmpfile.a > $tmpfile.b") == 0 or die "compress: $!";
ok (compare_files ($tmpfile, "$tmpfile.b"));

ok (download_file ("$tmpfile.gz", "$tmpfile.a"));
system ("gzip -cd $tmpfile.a > $tmpfile.b") == 0 or die "gzip: $!";
ok (compare_files ($tmpfile, "$tmpfile.b"));

ok (download_file ("$tmpfile.gz.uue", "$tmpfile.a"));
system ("uudecode -o $tmpfile.b < $tmpfile.a") == 0 or die "uudecode: $!";
system ("gzip -cd $tmpfile.b > $tmpfile.a") == 0 or die "gzip: $!";
ok (compare_files ($tmpfile, "$tmpfile.a"));

unlink $tmpfile;
unlink "$tmpfile.a";
unlink "$tmpfile.b";

print OUTFD0 "QUIT\r\n";
$_ = <INFD1>;

exit;

# This function uploads a file to the server.

sub upload_file
  {
    my $filename = shift;

    # Snarf the local file.
    open UPLOAD, "<$filename" or die "$filename: $!";
    my $buffer;
    {
      local $/ = undef;
      $buffer = <UPLOAD>;
    }
    close UPLOAD;

    # Send the STOR command.
    print OUTFD0 "STOR $filename\r\n";
    $_ = <INFD1>;
    return 0 unless /^150/;

    # Connect to the passive mode port.
    my $sock = new IO::Socket::INET
      (PeerAddr => "127.0.0.1:$port",
       Proto => "tcp")
	or die "socket: $!";

    # Write to socket.
    $sock->print ($buffer);
    $sock->close;

    # Check return code.
    $_ = <INFD1>;
    return /^226/;
  }

# Download a file from the server into a local file.

sub download_file
  {
    my $remote_filename = shift;
    my $local_filename = shift;

    # Send the RETR command.
    print OUTFD0 "RETR $remote_filename\r\n";
    $_ = <INFD1>;
    return 0 unless /^150/;

    # Connect to the passive mode port.
    my $sock = new IO::Socket::INET
      (PeerAddr => "127.0.0.1:$port",
       Proto => "tcp")
	or die "socket: $!";

    # Read all the data into a buffer.
    my $buffer = "";
    my $posn = 0;
    my $r;
    while (($r = $sock->read ($buffer, 65536, $posn)) > 0) {
      $posn += $r;
    }
    $sock->close;

    # Check return code.
    $_ = <INFD1>;
    return 0 unless /^226/;

    # Save to load file.
    open DOWNLOAD, ">$local_filename" or die "$local_filename: $!";
    print DOWNLOAD $buffer;
    close DOWNLOAD;

    # OK!
    return 1;
  }

# Compare two local files.

sub compare_files
  {
    my $filename1 = shift;
    my $filename2 = shift;

    system ("cmp $filename1 $filename2") == 0
      or return 0;

    return 1;
  }
