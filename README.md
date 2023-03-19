# OZO Virt-Install

## Overview
This script assists with virtual server deployment using `virt-install` to define and start a guest (domain) on a Linux KVM host. It requires the path to a file containing guest configuration information. Results are written to the system log (typically `/var/log/messages` or `/var/log/syslog`).

Please visit https://onezeroone.dev to learn more about this script and my other work.

## Setup and Configuration

Install the KVM packages e.g., for RedHat-style distributions:

```
# dnf install qemu-kvm libvirt virt-install
```

Enable and start the Libvirt services e.g., for RedHat-style distributions:

```
# systemctl enable --now virtqemud
# systemctl enable --now virtnetworkd
# systemctl enable --now virtnodedevd
# systemctl enable --now virtsecretd
# systemctl enable --now virtstoraged
# systemctl enable --now virtinterfaced
```

### Clone the Repository and Copy Files

Clone this repository to a temporary directory. Then (as `root`):

- Copy `ozo-virt-install.sh` to `/usr/local/sbin/` and set permissions to `rwx------` (`0700`)
- Copy `ozo-virt-install-guest-example.conf` to any convenient location and modify to suit your needs:

  |Variable|Example Value|Required|Description|
  |--------|-------------|--------|-----------|
  |OS_LOCATION|`"http://repo.almalinux.org/almalinux/9.1/BaseOS/x86_64/os/"`|TRUE|Path to AlmaLinux repository containing `initrd`, `vmlinuz`, and installation packages|
  |OS_KICKSTART|`"https://server.example.com/ks/guest.onezeroone.dev-ks.cfg"`|TRUE|Path to the guest kickstrt|
  KVM_NETWORK|`"bridge"`|TRUE|KVM network to use for the guest network connection|
  |KVM_NETDEV_MODEL|`"virtio"`|TRUE|KVM network device model to use for the guest network connection|
  |VM_HOSTNAME|`"guest.onezeroone.dev"`|TRUE|Guest hostname|
  |VM_MEMORY|`1024`E|Guest memory in MB|
  |VM_CPUS|`2`|TRUE|Guest CPU count|
  |VM_DISK|`"/dev/server-vg/guest-lv"`|TRUE|Block device to use as the guest disk (appears to the guest as `/dev/vda`)|
  |VM_IP|`"10.0.0.10"`|TRUE|Guest IP address|
  |VM_GATEWAY|`"10.0.0.1"`|TRUE|Guest IP gateway|
  |VM_NETMASK|`"255.255.255.0"`|TRUE|Guest IP subnet mask|
  |VM_NAMESERVER|`"1.1.1.1"`|TRUE|Guest DNS server address|
  |VM_NETDEV|`"enp1s0"`|TRUE|Guest network device name|
  |VM_MAC|`"52:54:00:01:01:01"`|FALSE|Guest MAC address|
  
## Usage

```
# ozo-virt-install.sh /path/to/guest.conf
```

If the script executes successfully, you can `virsh list --all` to see your \[now\] running VM and you can `virsh console [VM_HOSTNAME]` to supervise the installation and interact with the VM.
