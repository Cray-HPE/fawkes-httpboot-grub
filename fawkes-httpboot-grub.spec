#
# MIT License
#
# (C) Copyright 2022-2023 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
Name:          %(echo $GIT_REPO_NAME)
License:       GPLv2
Summary:       Grub binaries for http booting x86_64 and arm64
BuildArch:     noarch
Version:       %(echo $VERSION)
Release:       1
Source:        %{name}-%{version}.tar.bz2
Vendor:        Cray Inc.
Requires:      dnsmasq
BuildRequires: make
BuildRequires: bison
BuildRequires: flex
BuildRequires: autoconf
BuildRequires: automake

%define binx86_64 bootx64.efi
%define binarm64 bootaa64.efi
%define wwwbootdir /var/www/boot/

%description
Grub binaries for http booting x86_64 and arm64. Contents are installed into %{wwwbootdir} for serving via HTTP.

%prep
%setup -q

%install
%{__install} -m 755 -d %{buildroot}%{wwwbootdir}
%{__install} -m 644 %{_builddir}/%{binx86_64} %{buildroot}%{wwwbootdir}
%{__install} -m 644 %{_builddir}/%{binarm64} %{buildroot}%{wwwbootdir}

%files
%defattr(-,root,root)
%license LICENSE
%doc README.adoc
%dir %{wwwbootdir}
%attr(-,dnsmasq,tftp) %{wwwbootdir}%(basename %{binx86_64})
%attr(-,dnsmasq,tftp) %{wwwbootdir}%(basename %{binarm64})
