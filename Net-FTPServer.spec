# Automatically generated by Net-FTPServer.spec.PL

%define perlsitearch %(perl -e 'use Config; print $Config{installsitearch}, "\\n"')
%define perlsitelib %(perl -e 'use Config; print $Config{installsitelib}, "\\n"')
%define perlman1dir %(perl -e 'use Config; print $Config{installman1dir}, "\\n"')
%define perlman3dir %(perl -e 'use Config; print $Config{installman3dir}, "\\n"')
%define perlversion %(perl -e 'use Config; print $Config{version}, "\\n"')

Summary: Net::FTPServer - an extensible, secure FTP server
Name: Net-FTPServer
Version: 1.028
Release: 1
Copyright: GPL
Group: Applications/Internet
Source: %{name}-%{version}.tar.gz
BuildRoot: /var/tmp/%{name}-%{version}-root
Requires: Authen-PAM >= 0.12
Requires: BSD-Resource >= 1.08
Requires: IO-stringy >= 1.220
Requires: File-Sync >= 0.09
Requires: perl >= %{perlversion}
# The following packages are now provided by the core of perl.
#Requires: Digest-MD5
#Requires: Getopt-Long
#Requires: IO >= 1.20

%description


%prep
%setup -q


%build
perl Makefile.PL
make
make test


%install
rm -rf $RPM_BUILD_ROOT
make PREFIX=$RPM_BUILD_ROOT/usr install
find $RPM_BUILD_ROOT/usr -type f -print | perl -p -e "s@^$RPM_BUILD_ROOT(.*)@\$1*@g" | grep -v perllocal.pod > %{name}-filelist

%clean
rm -rf $RPM_BUILD_ROOT

%files -f %{name}-filelist
%defattr(-,root,root)

%changelog
* Tue Feb 15 2001 Rob Brown <rbrown@about-inc.com>
- Generalized files - works with Perl 5.6 as well as with Perl 5.005
* Tue Feb 08 2001 Richard Jones <rich@annexia.org>
- initial creation
