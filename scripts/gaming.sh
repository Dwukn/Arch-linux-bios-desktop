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
figlet "Gaming Setup"
echo -e "${BLUE}Complete gaming environment configuration${NC}"
echo

# Check for yay
if ! command -v yay &> /dev/null; then
    echo -e "${RED}yay not found. Please run base.sh first.${NC}"
    exit 1
fi

# Gaming platforms
GAMING_PLATFORMS=(
    "steam"
    "lutris"
    "heroic-games-launcher-bin"
    "bottles"
    "itch"
    "minecraft-launcher"
    "prismlauncher"
)

gum confirm "Install gaming platforms?" && {
    echo -e "${GREEN}Installing gaming platforms...${NC}"
    yay -S --noconfirm "${GAMING_PLATFORMS[@]}"
}

# Wine and compatibility
WINE_PACKAGES=(
    "wine"
    "winetricks"
    "wine-gecko"
    "wine-mono"
    "lib32-mesa"
    "lib32-vulkan-radeon"
    "lib32-vulkan-intel"
    "lib32-nvidia-utils"
)

gum confirm "Install Wine and compatibility layers?" && {
    echo -e "${GREEN}Installing Wine...${NC}"
    sudo pacman -S --noconfirm "${WINE_PACKAGES[@]}"
}

# Gaming utilities
GAMING_UTILS=(
    "gamemode"
    "gamescope"
    "mangohud"
    "lib32-mangohud"
    "goverlay"
    "corectrl"
    "discord"
    "discord-rpc"
)

gum confirm "Install gaming utilities (GameMode, MangoHUD, etc.)?" && {
    echo -e "${GREEN}Installing gaming utilities...${NC}"
    yay -S --noconfirm "${GAMING_UTILS[@]}"
}

# Detect GPU and install appropriate drivers
GPU_VENDOR=$(lspci | grep -E "VGA|3D" | head -n1)

echo -e "${BLUE}Detected GPU: ${GPU_VENDOR}${NC}"

if echo "$GPU_VENDOR" | grep -i nvidia; then
    gum confirm "Install NVIDIA drivers?" && {
        echo -e "${GREEN}Installing NVIDIA drivers...${NC}"
        sudo pacman -S --noconfirm nvidia nvidia-utils lib32-nvidia-utils nvidia-settings
    }
elif echo "$GPU_VENDOR" | grep -i amd; then
    gum confirm "Install AMD drivers?" && {
        echo -e "${GREEN}Installing AMD drivers...${NC}"
        sudo pacman -S --noconfirm mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
    }
elif echo "$GPU_VENDOR" | grep -i intel; then
    gum confirm "Install Intel drivers?" && {
        echo -e "${GREEN}Installing Intel drivers...${NC}"
        sudo pacman -S --noconfirm mesa lib32-mesa vulkan-intel lib32-vulkan-intel
    }
fi

# Game development tools
GAMEDEV_PACKAGES=(
    "godot"
    "unity-editor"
    "blender"
    "krita"
    "audacity"
    "aseprite"
)

gum confirm "Install game development tools?" && {
    echo -e "${GREEN}Installing game development tools...${NC}"
    yay -S --noconfirm "${GAMEDEV_PACKAGES[@]}"
}

# Emulators
EMULATORS=(
    "retroarch"
    "dolphin-emu"
    "pcsx2"
    "ppsspp"
    "desmume"
    "snes9x-gtk"
    "mupen64plus"
)

gum confirm "Install emulators?" && {
    echo -e "${GREEN}Installing emulators...${NC}"
    yay -S --noconfirm "${EMULATORS[@]}"
}

# Gaming controllers support
gum confirm "Install gaming controller support?" && {
    echo -e "${GREEN}Installing controller support...${NC}"
    sudo pacman -S --noconfirm xboxdrv xpadneo-dkms
    yay -S --noconfirm ds4drv
}

# Enable multilib repository (for 32-bit support)
gum confirm "Enable multilib repository for 32-bit game support?" && {
    echo -e "${GREEN}Enabling multilib repository...${NC}"
    sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
    sudo pacman -Sy
}

# Configure Steam for optimal performance
gum confirm "Configure Steam for optimal performance?" && {
    echo -e "${GREEN}Configuring Steam...${NC}"

    # Create Steam launch options directory
    mkdir -p ~/.steam/steam/config

    # Add gamemode to Steam games by default
    echo -e "${YELLOW}Add 'gamemoderun %command%' to your Steam game launch options for better performance${NC}"

    # Enable Steam Play for all titles
    echo -e "${YELLOW}Enable Steam Play (Proton) for all titles in Steam Settings > Steam Play${NC}"
}

# Configure MangoHUD
gum confirm "Configure MangoHUD for performance monitoring?" && {
    echo -e "${GREEN}Configuring MangoHUD...${NC}"
    mkdir -p ~/.config/MangoHud
    cat > ~/.config/MangoHud/MangoHud.conf << 'EOF'
fps
frametime
cpu_temp
gpu_temp
cpu_load_change
gpu_load_change
ram
vram
position=top-left
background_alpha=0.4
font_size=16
EOF
}

# Gaming-specific optimizations
gum confirm "Apply gaming optimizations?" && {
    echo -e "${GREEN}Applying gaming optimizations...${NC}"

    # Add user to gamemode group
    sudo usermod -aG gamemode $USER

    # Configure GameMode
    sudo mkdir -p /etc/gamemode
    sudo tee /etc/gamemode/gamemode.ini > /dev/null << 'EOF'
[general]
renice=10
desiredgov=performance
softrealtime=on

[gpu]
apply_gpu_optimisations=accept-responsibility

[custom]
start=notify-send "GameMode started"
end=notify-send "GameMode ended"
EOF
}

echo
figlet "Game On!"
echo -e "${GREEN}Gaming setup completed successfully!${NC}"
echo -e "${YELLOW}Recommended: Reboot to ensure all drivers are loaded properly${NC}"
echo -e "${BLUE}Don't forget to:${NC}"
echo -e "  • Enable Steam Play in Steam settings"
echo -e "  • Add 'gamemoderun %command%' to game launch options"
echo -e "  • Configure GPU-specific settings in your GPU control panel"
