# OZO Virt-Install Installation, Configuration, and Usage
## Overview
This script assists with virtual server deployment using `virt-install` to define and start a guest (domain) on a Linux KVM host. It requires the path to a file containing guest configuration information. Results are written to the system log (typically `/var/log/messages` or `/var/log/syslog`).

## Prerequisites
Install the required Linux KVM packages and start the required services.

### AlmaLinux 10, Red Hat Enterprise Linux 10, Rocky Linux 10
```bash
dnf -y install libvirt libvirt-client virt-install
systemctl enable --now libvirtd
```
### Debian
PENDING.

## Installation
To install this script on your Linux KVM system, you must first register the One Zero One repository.

### AlmaLinux 10, Red Hat Enterprise Linux 10, Rocky Linux 10 (RPM)
```bash
rpm -Uvh https://repositories.onezeroone.dev/el/10/noarch/ozo-rdiff-backup-1.0.0-1.el10.noarch.rpm
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-ONEZEROONE
dnf repolist
dnf -y install ozo-virt-install
```

### Debian (DEB)
PENDING.

## Configuration
Using `/etc/ozo-virt-install.conf.d/ozo-virt-install-guest-example.conf` as a template, create a configuration file that represents your desired VM.

## Usage
```
ozo-virt-install
    <String>
```

## Examples
```bash
ozo-virt-install.sh /etc/ozo-virt-install.conf.d/ozo-virt-install-guest-example.conf
```

## Notes
Please visit [One Zero One](https://onezeroone.dev) to learn more about my other work.
