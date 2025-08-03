#!/bin/bash

# ───────────────────────────────
# Colors & Styling
# ───────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD=$(tput bold)
RESET=$(tput sgr0)

# ───────────────────────────────
# Utility Functions
# ───────────────────────────────
log() {
    echo -e "${BLUE}[$(date +"%T")]${NC} $1"
}

success() {
    echo -e "${GREEN}✔ $1${NC}"
}

error() {
    echo -e "${RED}✖ $1${NC}" >&2
}

warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

confirm() {
    gum confirm --prompt "${BOLD}$1${RESET}"
}

install_packages() {
    local name="$1"
    shift
    local packages=("$@")

    log "Installing $name..."
    yay -S --noconfirm "${packages[@]}" && success "$name installed"
}

# ───────────────────────────────
# Check & Setup
# ───────────────────────────────
if [[ $EUID -eq 0 ]]; then
    error "This script should NOT be run as root."
    exit 1
fi

for pkg in figlet gum; do
    if ! command -v $pkg &> /dev/null; then
        warn "$pkg not found. Installing..."
        sudo pacman -S --noconfirm $pkg || { error "Failed to install $pkg"; exit 1; }
        success "$pkg installed"
    fi
done

clear
figlet "General Apps"
log "${BOLD}Starting setup of daily desktop applications...${RESET}"
echo

if ! command -v yay &> /dev/null; then
    error "yay is not installed. Please run base.sh first."
    exit 1
fi

# ───────────────────────────────
# App Installation Sections
# ───────────────────────────────

install_media_apps() {
    MEDIA_PACKAGES=(vlc gimp inkscape blender obs-studio audacity shotcut krita darktable)
    confirm "Install media and graphics applications?" && install_packages "Media & Graphics Apps" "${MEDIA_PACKAGES[@]}"
}

install_office_apps() {
    OFFICE_PACKAGES=(libreoffice-fresh thunderbird notion-app obsidian typora calibre pdf-arranger okular)
    confirm "Install office and productivity applications?" && install_packages "Office & Productivity Apps" "${OFFICE_PACKAGES[@]}"
}

install_internet_apps() {
    INTERNET_PACKAGES=(firefox chromium discord telegram-desktop skypeforlinux-stable-bin zoom slack-desktop whatsapp-for-linux)
    confirm "Install internet and communication applications?" && install_packages "Internet & Communication Apps" "${INTERNET_PACKAGES[@]}"
}

install_utilities() {
    UTILITY_PACKAGES=(gparted bleachbit filelight baobab timeshift flameshot copyq albert syncthing keepassxc)
    confirm "Install system utilities?" && install_packages "System Utilities" "${UTILITY_PACKAGES[@]}"
}

install_codecs() {
    confirm "Install multimedia codecs?" && {
        log "Installing multimedia codecs..."
        sudo pacman -S --noconfirm gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav
        success "Multimedia codecs installed"
    }
}

install_fonts() {
    FONT_PACKAGES=(ttf-dejavu ttf-liberation noto-fonts noto-fonts-emoji ttf-roboto ttf-opensans nerd-fonts-complete)
    confirm "Install additional fonts?" && install_packages "Fonts" "${FONT_PACKAGES[@]}"
}

install_gaming() {
    GAMING_PACKAGES=(steam lutris gamemode)
    confirm "Install basic gaming support?" && {
        install_packages "Gaming Packages" "${GAMING_PACKAGES[@]}"
        warn "For full gaming setup, run gaming.sh"
    }
}

install_flatpak() {
    confirm "Install Flatpak support?" && {
        log "Installing Flatpak..."
        sudo pacman -S --noconfirm flatpak
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        success "Flatpak installed and configured"
    }
}

configure_firewall() {
    confirm "Configure UFW firewall?" && {
        log "Installing and enabling UFW..."
        sudo pacman -S --noconfirm ufw
        sudo ufw enable
        sudo systemctl enable ufw
        success "Firewall (UFW) configured"
    }
}

create_user_dirs() {
    confirm "Create user directories (Documents, Downloads, etc.)?" && {
        log "Creating XDG user directories..."
        xdg-user-dirs-update
        success "User directories updated"
    }
}

# ───────────────────────────────
# Execute Sections
# ───────────────────────────────
install_media_apps
install_office_apps
install_internet_apps
install_utilities
install_codecs
install_fonts
install_gaming
install_flatpak
configure_firewall
create_user_dirs

# ───────────────────────────────
# Wrap-Up
# ───────────────────────────────
echo
figlet "All Set!"
success "General applications setup completed!"
warn "Some apps may require a reboot or re-login to work properly."
