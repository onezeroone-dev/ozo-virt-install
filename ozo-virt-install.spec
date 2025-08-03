Name:      ozo-virt-install
Version:   1.0.1
Release:   1%{?dist}
Summary:   Assists with virtual server deployment using virt-install
BuildArch: noarch

License:   GPL
Source0:   %{name}-%{version}.tar.gz

Requires:  bash

%description
This script assists with virtual server deployment using virt-install to define and start a guest (domain) on a Linux KVM host.

%prep
%setup -q

%install
rm -rf $RPM_BUILD_ROOT

mkdir -p $RPM_BUILD_ROOT/etc/ozo-virt-install.conf.d
cp ozo-virt-install-guest-example.conf $RPM_BUILD_ROOT/etc/ozo-virt-install.conf.d

mkdir -p $RPM_BUILD_ROOT/usr/sbin
cp ozo-virt-install.sh $RPM_BUILD_ROOT/usr/sbin

%files
%attr (0644,root,root) /etc/ozo-virt-install.conf.d/ozo-virt-install-guest-example.conf
%attr (0700,root,root) /usr/sbin/ozo-virt-install.sh

%changelog
* Sat Aug 02 2025 One Zero One RPM Manager <repositories@onezeroone.dev> - 1.0.1-1
- Corrected message label in ozo-log function
* Sun Mar 19 2023 One Zero One RPM Manager <repositories@onezeroone.dev> - 1.0.0-1
- Initial release
