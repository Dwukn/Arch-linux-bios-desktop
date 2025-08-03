#!/bin/bash

# ───────────────────────────────────────────────
# Colors & Styling
# ───────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD=$(tput bold)
RESET=$(tput sgr0)

# ───────────────────────────────────────────────
# Logging Helpers
# ───────────────────────────────────────────────
log()     { echo -e "${BLUE}[$(date +%T)]${NC} $1"; }
success() { echo -e "${GREEN}✔ $1${NC}"; }
error()   { echo -e "${RED}✖ $1${NC}" >&2; }
warn()    { echo -e "${YELLOW}⚠ $1${NC}"; }
confirm(){ gum confirm --prompt "${BOLD}$1${RESET}"; }

install_native() {
    log "Installing: $1"
    sudo pacman -S --noconfirm "${@:2}" && success "$1 installed" || error "Failed: $1"
}

install_aur() {
    log "Installing (AUR): $1"
    yay -S --noconfirm "${@:2}" && success "$1 installed" || error "Failed: $1"
}

# ───────────────────────────────────────────────
# Preliminary Checks
# ───────────────────────────────────────────────
[[ $EUID -eq 0 ]] && { error "Do not run script as root."; exit 1; }
for pkg in figlet gum; do
  command -v "$pkg" &>/dev/null || install_native "$pkg" "$pkg"
done

clear
figlet "VM Setup"
log "Starting virtual machine environment setup..."

command -v yay &>/dev/null || { error "yay not found. Run base.sh first."; exit 1; }

# Check virtualization support
if ! grep -E "(vmx|svm)" /proc/cpuinfo &>/dev/null; then
  error "CPU virtualization support not detected!"
  warn "Enable VT‑x / AMD‑V in BIOS/UEFI"
  exit 1
else
  success "Hardware virtualization support detected"
fi

# ───────────────────────────────────────────────
# Feature Functions
# ───────────────────────────────────────────────
setup_kvm_packages() {
  confirm "Install KVM/QEMU packages?" && install_native "KVM/QEMU stack" \
    qemu-full libvirt virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat ebtables iptables
}

setup_extra_tools() {
  confirm "Install additional virtualization tools?" && install_native "Virt tools" \
    spice-vdagent spice-gtk spice-protocol qemu-guest-agent virglrenderer
}

install_virtualbox() {
  confirm "Install VirtualBox (alternative)" && install_native "VirtualBox" \
    virtualbox virtualbox-host-modules-arch && sudo modprobe vboxdrv && success "VirtualBox module loaded"
}

install_vmware() {
  confirm "Install VMware Workstation (if desired)" && install_aur "VMware Workstation" vmware-workstation
}

setup_docker() {
  confirm "Install Docker for container use?" && {
    install_native "Docker & Compose" docker docker-compose
    sudo systemctl enable docker && success "Docker enabled"
    sudo usermod -aG docker "$USER"
    warn "Log out/in to apply Docker group changes"
  }
}

configure_libvirt_network() {
  confirm "Configure libvirt and default network?" && {
    sudo usermod -aG libvirt "$USER"
    sudo usermod -aG kvm "$USER"
    sudo systemctl enable --now libvirtd
    sudo virsh net-start default && sudo virsh net-autostart default
    success "libvirt network 'default' active"
  }
}

download_virtio_iso() {
  confirm "Download Windows virtio driver ISO?" && {
    mkdir -p ~/VMs/drivers &&
    wget -q --show-progress -O ~/VMs/drivers/virtio-win.iso \
      https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso &&
    success "virtio‑win.iso downloaded to ~/VMs/drivers"
  }
}

create_vm_dirs() {
  confirm "Create VM storage directories?" && {
    mkdir -p ~/VMs/{images,iso,snapshots}
    sudo mkdir -p /var/lib/libvirt/images
    sudo chown -R "$USER":"$USER" ~/VMs
    success "VM storage directories created"
  }
}

setup_vfio_passthrough() {
  confirm "Configure GPU passthrough (advanced)?" && {
    install_native "VFIO drivers" vfio-pci
    sudo sed -i 's/MODULES=()/MODULES=(vfio_pci vfio vfio_iommu_type1 vfio_virqfd)/' /etc/mkinitcpio.conf
    warn "Manual VFIO binding & BIOS IOMMU settings remain"
    success "VFIO configuration added (rebuild initramfs required)"
  }
}

apply_performance_tuning() {
  confirm "Apply VM performance optimizations?" && {
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
    echo 'vm.nr_hugepages=2048' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    success "Performance tuning applied"
  }
}

install_management_tools() {
  confirm "Install VM management tools?" && install_native "VM tools" cockpit cockpit-machines gnome-boxes \
    && sudo systemctl enable --now cockpit.socket
}

generate_quick_vm_script() {
  confirm "Create quick VM creation script?" && {
    cat > ~/create-vm.sh << 'EOF'
#!/bin/bash
echo "Quick VM Creator"
read -p "VM Name: " VM_NAME
read -p "RAM (GB): " RAM
read -p "Disk Size (GB): " DISK
read -p "ISO Path: " ISO
qemu-img create -f qcow2 ~/VMs/images/"$VM_NAME".qcow2 "${DISK}G"
virt-install --name="$VM_NAME" --ram=$((RAM*1024)) --vcpus=2 --disk path=~/VMs/images/"$VM_NAME".qcow2,format=qcow2 \
 --cdrom="$ISO" --network network=default --graphics spice --video qxl \
 --channel spicevmc --console pty,target_type=serial --boot hd,cdrom --accelerate --check-cpu \
 --os-variant detect=on,name=generic
echo "VM '$VM_NAME' created!"
EOF
    chmod +x ~/create-vm.sh
    success "Created ~/create-vm.sh"
  }
}

enable_nested_virtualization() {
  confirm "Enable nested virtualization?" && {
    grep -q GenuineIntel /proc/cpuinfo && echo 'options kvm_intel nested=1' | sudo tee /etc/modprobe.d/kvm_intel.conf
    grep -q AuthenticAMD /proc/cpuinfo && echo 'options kvm_amd nested=1' | sudo tee /etc/modprobe.d/kvm_amd.conf
    warn "Reboot required for nested virtualization to take effect"
  }
}

configure_bridge_network() {
  confirm "Setup network bridge (br0)?" && {
    install_native "bridge-utils" bridge-utils
    local xml=/tmp/br0.xml
    cat >"$xml" << 'EOF'
<network>
  <name>br0</name>
  <forward mode='nat'><nat><port start='1024' end='65535'/></nat></forward>
  <bridge name='br0' stp='on' delay='0'/>
  <ip address='192.168.100.1' netmask='255.255.255.0'>
    <dhcp><range start='192.168.100.2' end='192.168.100.254'/></dhcp>
  </ip>
</network>
EOF
    sudo virsh net-define "$xml"
    sudo virsh net-start br0
    sudo virsh net-autostart br0
    rm "$xml"
    success "Bridge network 'br0' created at 192.168.100.0/24"
  }
}

apply_security_settings() {
  confirm "Apply libvirt security defaults?" && {
    install_native "AppArmor" apparmor
    sudo systemctl enable --now apparmor
    sudo chmod 600 /etc/libvirt/qemu.conf
    success "Security policies applied"
  }
}

# ───────────────────────────────────────────────
# Execution Sequence
# ───────────────────────────────────────────────
setup_kvm_packages
setup_extra_tools
install_virtualbox
install_vmware
setup_docker
configure_libvirt_network
download_virtio_iso
create_vm_dirs
setup_vfio_passthrough
apply_performance_tuning
install_management_tools
generate_quick_vm_script
enable_nested_virtualization
configure_bridge_network
apply_security_settings

# ───────────────────────────────────────────────
# Final Summary
# ───────────────────────────────────────────────
echo
figlet "VMs Ready!"
success "Virtual machine environment configured!"
warn "Log out or reboot to apply group/module changes"

echo -e "${BLUE}Next steps:${NC}"
echo -e "  • Use virt‑manager or cockpit to manage your VMs"
echo -e "  • Run ~/create-vm.sh for quick VM creation"
echo -e "  • Default libvirt network: 192.168.122.0/24"
echo -e "  • br0 NAT bridge: 192.168.100.0/24"
echo -e "  • Access Cockpit at http://localhost:9090"
