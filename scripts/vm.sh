#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}This script should not be run as root${NC}"
   exit 1
fi

# Install figlet and gum if not present
if ! command -v figlet &> /dev/null || ! command -v gum &> /dev/null; then
    echo -e "${YELLOW}Installing figlet and gum...${NC}"
    sudo pacman -S --noconfirm figlet gum
fi

clear
figlet "VM Setup"
echo -e "${BLUE}Virtual Machine environment with KVM/QEMU${NC}"
echo

# Check for yay
if ! command -v yay &> /dev/null; then
    echo -e "${RED}yay not found. Please run base.sh first.${NC}"
    exit 1
fi

# Check for virtualization support
echo -e "${BLUE}Checking for virtualization support...${NC}"
if ! grep -E "(vmx|svm)" /proc/cpuinfo > /dev/null; then
    echo -e "${RED}Hardware virtualization not supported or not enabled${NC}"
    echo -e "${YELLOW}Please enable VT-x/AMD-V in BIOS/UEFI settings${NC}"
    exit 1
else
    echo -e "${GREEN}Hardware virtualization support detected${NC}"
fi

# KVM/QEMU packages
KVM_PACKAGES=(
    "qemu-full"
    "libvirt"
    "virt-manager"
    "virt-viewer"
    "dnsmasq"
    "vde2"
    "bridge-utils"
    "openbsd-netcat"
    "ebtables"
    "iptables"
)

gum confirm "Install KVM/QEMU packages?" && {
    echo -e "${GREEN}Installing KVM/QEMU packages...${NC}"
    sudo pacman -S --noconfirm "${KVM_PACKAGES[@]}"
}

# Additional virtualization tools
ADDITIONAL_TOOLS=(
    "spice-vdagent"
    "spice-gtk"
    "spice-protocol"
    "qemu-guest-agent"
    "virglrenderer"
)

gum confirm "Install additional virtualization tools?" && {
    echo -e "${GREEN}Installing additional tools...${NC}"
    sudo pacman -S --noconfirm "${ADDITIONAL_TOOLS[@]}"
}

# VirtualBox (alternative)
gum confirm "Install VirtualBox as alternative?" && {
    echo -e "${GREEN}Installing VirtualBox...${NC}"
    sudo pacman -S --noconfirm virtualbox virtualbox-host-modules-arch
    sudo modprobe vboxdrv
}

# VMware Workstation support
gum confirm "Install VMware Workstation?" && {
    echo -e "${GREEN}Installing VMware Workstation...${NC}"
    yay -S --noconfirm vmware-workstation
}

# Docker (containerization)
gum confirm "Install Docker for containerization?" && {
    echo -e "${GREEN}Installing Docker...${NC}"
    sudo pacman -S --noconfirm docker docker-compose
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
}

# Configure KVM/QEMU
gum confirm "Configure KVM/QEMU?" && {
    echo -e "${GREEN}Configuring KVM/QEMU...${NC}"

    # Add user to libvirt group
    sudo usermod -aG libvirt $USER
    sudo usermod -aG kvm $USER

    # Enable and start libvirt service
    sudo systemctl enable libvirtd
    sudo systemctl start libvirtd

    # Configure libvirt network
    sudo virsh net-start default
    sudo virsh net-autostart default

    echo -e "${GREEN}KVM/QEMU configuration completed${NC}"
}

# Install Windows virtio drivers
gum confirm "Download Windows virtio drivers for better VM performance?" && {
    echo -e "${GREEN}Downloading Windows virtio drivers...${NC}"
    mkdir -p ~/VMs/drivers
    cd ~/VMs/drivers
    wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
    echo -e "${GREEN}Virtio drivers downloaded to ~/VMs/drivers/${NC}"
}

# Create VM storage directory
gum confirm "Create VM storage directories?" && {
    echo -e "${GREEN}Creating VM directories...${NC}"
    mkdir -p ~/VMs/{images,iso,snapshots}
    sudo mkdir -p /var/lib/libvirt/images
    sudo chown -R $USER:$USER ~/VMs
}

# GPU passthrough setup (advanced)
gum confirm "Configure GPU passthrough (VFIO) - Advanced users only?" && {
    echo -e "${YELLOW}Setting up GPU passthrough...${NC}"

    # Install VFIO packages
    sudo pacman -S --noconfirm vfio-pci

    # Add VFIO modules to mkinitcpio
    sudo sed -i 's/MODULES=()/MODULES=(vfio_pci vfio vfio_iommu_type1 vfio_virqfd)/' /etc/mkinitcpio.conf

    echo -e "${RED}WARNING: GPU passthrough requires additional manual configuration!${NC}"
    echo -e "${YELLOW}You need to:${NC}"
    echo -e "  1. Enable IOMMU in BIOS/UEFI"
    echo -e "  2. Add intel_iommu=on or amd_iommu=on to kernel parameters"
    echo -e "  3. Identify and bind your GPU to VFIO driver"
    echo -e "  4. Rebuild initramfs: sudo mkinitcpio -p linux"
    echo -e "${BLUE}Refer to Arch Wiki for detailed GPU passthrough guide${NC}"
}

# Performance tuning
gum confirm "Apply VM performance optimizations?" && {
    echo -e "${GREEN}Applying performance optimizations...${NC}"

    # Increase vm.swappiness for better VM performance
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf

    # Configure huge pages
    echo 'vm.nr_hugepages=2048' | sudo tee -a /etc/sysctl.conf

    # Apply immediately
    sudo sysctl -p

    echo -e "${GREEN}Performance optimizations applied${NC}"
}

# Install management tools
MANAGEMENT_TOOLS=(
    "cockpit"
    "cockpit-machines"
    "gnome-boxes"
)

gum confirm "Install VM management tools (Cockpit, GNOME Boxes)?" && {
    echo -e "${GREEN}Installing management tools...${NC}"
    yay -S --noconfirm "${MANAGEMENT_TOOLS[@]}"
    sudo systemctl enable --now cockpit.socket
}

# Quick Start VMs script
gum confirm "Create quick VM creation script?" && {
    echo -e "${GREEN}Creating quick VM script...${NC}"

    cat > ~/create-vm.sh << 'EOF'
#!/bin/bash

# Quick VM creation script
echo "Quick VM Creator"
echo "=================="

read -p "VM Name: " VM_NAME
read -p "RAM (GB): " RAM_GB
read -p "Disk Size (GB): " DISK_GB
read -p "ISO Path: " ISO_PATH

RAM_MB=$((RAM_GB * 1024))
DISK_PATH="$HOME/VMs/images/${VM_NAME}.qcow2"

# Create disk image
qemu-img create -f qcow2 "$DISK_PATH" "${DISK_GB}G"

# Create VM
virt-install \
    --name="$VM_NAME" \
    --ram="$RAM_MB" \
    --vcpus=2 \
    --disk path="$DISK_PATH",format=qcow2 \
    --cdrom="$ISO_PATH" \
    --network network=default \
    --graphics spice \
    --video qxl \
    --channel spicevmc \
    --console pty,target_type=serial \
    --boot hd,cdrom \
    --accelerate \
    --check-cpu \
    --os-variant detect=on,name=generic

echo "VM '$VM_NAME' created successfully!"
EOF

    chmod +x ~/create-vm.sh
    echo -e "${GREEN}Quick VM creation script created at ~/create-vm.sh${NC}"
}

# Nested virtualization
gum confirm "Enable nested virtualization?" && {
    echo -e "${GREEN}Enabling nested virtualization...${NC}"

    # For Intel
    if grep -q "GenuineIntel" /proc/cpuinfo; then
        echo 'options kvm_intel nested=1' | sudo tee /etc/modprobe.d/kvm_intel.conf
    fi

    # For AMD
    if grep -q "AuthenticAMD" /proc/cpuinfo; then
        echo 'options kvm_amd nested=1' | sudo tee /etc/modprobe.d/kvm_amd.conf
    fi

    echo -e "${YELLOW}Reboot required for nested virtualization to take effect${NC}"
}

# Network bridge setup
gum confirm "Setup network bridge for VMs?" && {
    echo -e "${GREEN}Setting up network bridge...${NC}"

    # Install bridge utilities
    sudo pacman -S --noconfirm bridge-utils

    cat > /tmp/br0.xml << 'EOF'
<network>
  <name>br0</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='br0' stp='on' delay='0'/>
  <ip address='192.168.100.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.100.2' end='192.168.100.254'/>
    </dhcp>
  </ip>
</network>
EOF

    sudo virsh net-define /tmp/br0.xml
    sudo virsh net-start br0
    sudo virsh net-autostart br0
    rm /tmp/br0.xml

    echo -e "${GREEN}Network bridge 'br0' created${NC}"
}

# Security configurations
gum confirm "Apply security configurations?" && {
    echo -e "${GREEN}Applying security configurations...${NC}"

    # Configure AppArmor for libvirt
    sudo pacman -S --noconfirm apparmor
    sudo systemctl enable apparmor

    # Set proper permissions
    sudo chmod 600 /etc/libvirt/qemu.conf

    echo -e "${GREEN}Security configurations applied${NC}"
}

echo
figlet "VMs Ready!"
echo -e "${GREEN}Virtual Machine environment setup completed!${NC}"
echo -e "${YELLOW}Important notes:${NC}"
echo -e "  • You need to log out and log back in for group changes to take effect"
echo -e "  • Use 'virt-manager' to manage VMs graphically"
echo -e "  • Use '~/create-vm.sh' for quick VM creation"
echo -e "  • Default network is available at 192.168.122.0/24"
echo -e "  • Bridge network is available at 192.168.100.0/24"
echo -e "${BLUE}Access Cockpit web interface at: http://localhost:9090${NC}"
