#!/bin/bash
set -euox pipefail

# Dumps details about the instance running the CI job.
CPUS=$(nproc)
MEM=$(free -m | grep -oP '\d+' | head -n 1)
DISK=$(df --output=size -h / | sed '1d;s/[^0-9]//g')
HOSTNAME=$(uname -n)
USER=$(whoami)
ARCH=$(uname -m)
KERNEL=$(uname -r)

echo -e "\033[0;36m"
cat << EOF
------------------------------------------------------------------------------
CI MACHINE SPECS
------------------------------------------------------------------------------
     Hostname: ${HOSTNAME}
         User: ${USER}
         CPUs: ${CPUS}
          RAM: ${MEM} MB
         DISK: ${DISK} GB
         ARCH: ${ARCH}
       KERNEL: ${KERNEL}
------------------------------------------------------------------------------
EOF
echo "CPU info"
lscpu
echo -e "\033[0m"

# Colorful output.
function greenprint {
    echo -e "\033[1;32m${1}\033[0m"
}

# Install required packages
greenprint "Install required packages"
sudo dnf install -y --nogpgcheck podman skopeo wget firewalld lorax xorriso curl jq qemu-img qemu-kvm libvirt-client libvirt-daemon-kvm libvirt-daemon virt-install ansible-core
ansible-galaxy collection install community.general

# Start firewalld
greenprint "Start firewalld"
sudo systemctl enable --now firewalld

# Start libvirtd and test it.
greenprint "🚀 Starting libvirt daemon"
sudo systemctl start libvirtd
sudo virsh list --all > /dev/null

# Set a customized dnsmasq configuration for libvirt so we always get the
# same address on bootup.
greenprint "💡 Setup libvirt network"
sudo tee /tmp/integration.xml > /dev/null << EOF
<network xmlns:dnsmasq='http://libvirt.org/schemas/network/dnsmasq/1.0'>
  <name>integration</name>
  <uuid>1c8fe98c-b53a-4ca4-bbdb-deb0f26b3579</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='integration' zone='trusted' stp='on' delay='0'/>
  <mac address='52:54:00:36:46:ef'/>
  <ip address='192.168.100.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.100.2' end='192.168.100.254'/>
      <host mac='34:49:22:B0:83:30' name='vm-1' ip='192.168.100.50'/>
      <host mac='34:49:22:B0:83:31' name='vm-2' ip='192.168.100.51'/>
      <host mac='34:49:22:B0:83:32' name='vm-3' ip='192.168.100.52'/>
    </dhcp>
  </ip>
  <dnsmasq:options>
    <dnsmasq:option value='dhcp-vendorclass=set:efi-http,HTTPClient:Arch:00016'/>
    <dnsmasq:option value='dhcp-option-force=tag:efi-http,60,HTTPClient'/>
    <dnsmasq:option value='dhcp-boot=tag:efi-http,&quot;http://192.168.100.1/httpboot/EFI/BOOT/BOOTX64.EFI&quot;'/>
  </dnsmasq:options>
</network>
EOF
if ! sudo virsh net-info integration > /dev/null 2>&1; then
    sudo virsh net-define /tmp/integration.xml
fi
if [[ $(sudo virsh net-info integration | grep 'Active' | awk '{print $2}') == 'no' ]]; then
    sudo virsh net-start integration
fi
