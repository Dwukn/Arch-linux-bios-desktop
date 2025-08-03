#!/bin/bash

# === Color Codes ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# === Ensure Required Tools ===
for tool in figlet gum; do
    if ! command -v "$tool" &>/dev/null; then
        echo -e "${YELLOW}Installing missing dependency: $tool${NC}"
        sudo pacman -S --noconfirm "$tool"
    fi
done

# === Display Header ===
clear
figlet "Script Info"
echo -e "${BLUE}📦 Arch Linux Post-Install Toolkit${NC}"
echo

# === Overview ===
echo -e "${GREEN}Toolkit Overview:${NC}"
echo -e "This toolkit is designed to simplify and accelerate post-installation configuration"
echo -e "of a fresh Arch Linux system. It includes modular scripts for different purposes:"
echo

# === Script Descriptions ===
echo -e "${GREEN}Included Setup Scripts:${NC}"
printf "  ${YELLOW}%-15s${NC} - %s\n" \
    "base.sh"     "🔧 Essential packages, aliases, shell, networking & reflector" \
    "dev.sh"      "💻 Dev tools: programming languages, code editors, Git config" \
    "general.sh"  "🖥️  GUI apps: web browsers, file managers, media tools, theming" \
    "gaming.sh"   "🎮 Gaming support: Steam, Wine, Lutris, performance tweaks" \
    "vm.sh"       "🖥️  Virtualization: KVM/QEMU, VirtualBox, Docker, bridges"

echo

# === Usage Instructions ===
echo -e "${GREEN}Quick Start Guide:${NC}"
echo -e "  ${CYAN}1.${NC} Clone the repository:"
echo -e "     ${CYAN}git clone https://github.com/Dwukn/Arch-linux-bios-desktop.git${NC}"
echo
echo -e "  ${CYAN}2.${NC} Navigate to the script directory:"
echo -e "     ${CYAN}cd Arch-linux-bios-desktop/scripts${NC}"
echo
echo -e "  ${CYAN}3.${NC} Make all scripts executable:"
echo -e "     ${CYAN}chmod +x *.sh${NC}"
echo
echo -e "  ${CYAN}4.${NC} Start the interactive setup:"
echo -e "     ${CYAN}./main.sh${NC}"
echo

# === Features ===
echo -e "${GREEN}Toolkit Features:${NC}"
echo -e "  • ${YELLOW}Interactive${NC} interface powered by ${CYAN}gum${NC}"
echo -e "  • ${YELLOW}Clean output${NC} using ${CYAN}figlet${NC} for script headers"
echo -e "  • ${YELLOW}Modular scripts${NC} for flexible usage (run only what you need)"
echo -e "  • ${YELLOW}System-safe${NC}: Avoids running as root, uses sudo as needed"
echo -e "  • ${YELLOW}Optimized${NC} for BIOS and UEFI setups"
echo -e "  • ${YELLOW}User-friendly${NC}: Commented, readable, and easily extendable"
echo

# === Recommendations ===
echo -e "${GREEN}Best Practices:${NC}"
echo -e "  • Run ${YELLOW}base.sh${NC} first to ensure all foundational tools are installed."
echo -e "  • Restart your system after major setups (especially kernel or group changes)."
echo -e "  • Always keep ${YELLOW}yay${NC} or ${YELLOW}paru${NC} installed for AUR support."
echo -e "  • Backup before applying GPU passthrough, Docker, or systemd modifications."
echo

# === Available Optional Add-ons ===
echo -e "${GREEN}Optional Future Add-ons:${NC}"
echo -e "  • Hyprland/i3 Setup Scripts"
echo -e "  • Dotfile management via Git"
echo -e "  • LUKS and BTRFS configuration automation"
echo -e "  • Secure boot & TPM tools integration"
echo

# === Return to Menu Prompt ===
if command -v gum &>/dev/null; then
    gum confirm "Return to main setup menu?" && exit 0 || exit 0
else
    echo -e "${YELLOW}Press any key to exit...${NC}"
    read -n 1 -s
    exit 0
fi
