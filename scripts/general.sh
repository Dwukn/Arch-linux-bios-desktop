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
figlet "General Apps"
echo -e "${BLUE}Daily desktop applications setup${NC}"
echo

# Check for yay
if ! command -v yay &> /dev/null; then
    echo -e "${RED}yay not found. Please run base.sh first.${NC}"
    exit 1
fi

# Media and Graphics
MEDIA_PACKAGES=(
    "vlc"
    "gimp"
    "inkscape"
    "blender"
    "obs-studio"
    "audacity"
    "shotcut"
    "krita"
    "darktable"
)

gum confirm "Install media and graphics applications?" && {
    echo -e "${GREEN}Installing media applications...${NC}"
    yay -S --noconfirm "${MEDIA_PACKAGES[@]}"
}

# Office and Productivity
OFFICE_PACKAGES=(
    "libreoffice-fresh"
    "thunderbird"
    "notion-app"
    "obsidian"
    "typora"
    "calibre"
    "pdf-arranger"
    "okular"
)

gum confirm "Install office and productivity applications?" && {
    echo -e "${GREEN}Installing office applications...${NC}"
    yay -S --noconfirm "${OFFICE_PACKAGES[@]}"
}

# Internet and Communication
INTERNET_PACKAGES=(
    "firefox"
    "chromium"
    "discord"
    "telegram-desktop"
    "skypeforlinux-stable-bin"
    "zoom"
    "slack-desktop"
    "whatsapp-for-linux"
)

gum confirm "Install internet and communication applications?" && {
    echo -e "${GREEN}Installing internet applications...${NC}"
    yay -S --noconfirm "${INTERNET_PACKAGES[@]}"
}

# System Utilities
UTILITY_PACKAGES=(
    "gparted"
    "bleachbit"
    "filelight"
    "baobab"
    "timeshift"
    "flameshot"
    "copyq"
    "albert"
    "syncthing"
    "keepassxc"
)

gum confirm "Install system utilities?" && {
    echo -e "${GREEN}Installing system utilities...${NC}"
    yay -S --noconfirm "${UTILITY_PACKAGES[@]}"
}

# Multimedia Codecs
gum confirm "Install multimedia codecs?" && {
    echo -e "${GREEN}Installing multimedia codecs...${NC}"
    sudo pacman -S --noconfirm gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav
}

# Fonts
FONT_PACKAGES=(
    "ttf-dejavu"
    "ttf-liberation"
    "noto-fonts"
    "noto-fonts-emoji"
    "ttf-roboto"
    "ttf-opensans"
    "nerd-fonts-complete"
)

gum confirm "Install additional fonts?" && {
    echo -e "${GREEN}Installing fonts...${NC}"
    yay -S --noconfirm "${FONT_PACKAGES[@]}"
}

# Gaming (basic)
GAMING_PACKAGES=(
    "steam"
    "lutris"
    "gamemode"
)

gum confirm "Install basic gaming support?" && {
    echo -e "${GREEN}Installing basic gaming packages...${NC}"
    yay -S --noconfirm "${GAMING_PACKAGES[@]}"
    echo -e "${YELLOW}For full gaming setup, run gaming.sh${NC}"
}

# Flatpak
gum confirm "Install Flatpak support?" && {
    echo -e "${GREEN}Installing Flatpak...${NC}"
    sudo pacman -S --noconfirm flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

# Configure firewall
gum confirm "Configure UFW firewall?" && {
    echo -e "${GREEN}Setting up UFW firewall...${NC}"
    sudo pacman -S --noconfirm ufw
    sudo ufw enable
    sudo systemctl enable ufw
}

# Create user directories
gum confirm "Create user directories (Documents, Downloads, etc.)?" && {
    echo -e "${GREEN}Creating user directories...${NC}"
    xdg-user-dirs-update
}

echo
figlet "All Set!"
echo -e "${GREEN}General applications setup completed!${NC}"
echo -e "${YELLOW}Some applications may require a reboot to work properly${NC}"
