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
log()      { echo -e "${BLUE}[$(date +%T)]${NC} $1"; }
success()  { echo -e "${GREEN}✔ $1${NC}"; }
error()    { echo -e "${RED}✖ $1${NC}" >&2; }
warn()     { echo -e "${YELLOW}⚠ $1${NC}"; }
confirm()  { gum confirm --prompt "${BOLD}$1${RESET}"; }

install_packages() {
    local label="$1"
    shift
    local packages=("$@")

    log "Installing $label..."
    yay -S --noconfirm "${packages[@]}" && success "$label installed"
}

install_native_packages() {
    local label="$1"
    shift
    local packages=("$@")

    log "Installing $label..."
    sudo pacman -S --noconfirm "${packages[@]}" && success "$label installed"
}

# ───────────────────────────────
# Sanity Checks
# ───────────────────────────────
[[ $EUID -eq 0 ]] && { error "Do not run this script as root."; exit 1; }

for pkg in figlet gum; do
    if ! command -v "$pkg" &> /dev/null; then
        warn "$pkg not found. Installing..."
        sudo pacman -S --noconfirm "$pkg" || { error "Failed to install $pkg"; exit 1; }
        success "$pkg installed"
    fi
done

clear
figlet "Gaming Setup"
log "Initializing complete gaming environment setup..."
echo

if ! command -v yay &> /dev/null; then
    error "yay is not installed. Please run base.sh first."
    exit 1
fi

# ───────────────────────────────
# Gaming Components
# ───────────────────────────────
install_gaming_platforms() {
    local GAMING_PLATFORMS=(steam lutris heroic-games-launcher-bin bottles itch minecraft-launcher prismlauncher)
    confirm "Install gaming platforms (Steam, Lutris, etc.)?" && install_packages "Gaming Platforms" "${GAMING_PLATFORMS[@]}"
}

install_wine_stack() {
    local WINE_PACKAGES=(wine winetricks wine-gecko wine-mono lib32-mesa lib32-vulkan-radeon lib32-vulkan-intel lib32-nvidia-utils)
    confirm "Install Wine and 32-bit compatibility layers?" && install_native_packages "Wine & Compatibility Layers" "${WINE_PACKAGES[@]}"
}

install_gaming_utilities() {
    local GAMING_UTILS=(gamemode gamescope mangohud lib32-mangohud goverlay corectrl discord discord-rpc)
    confirm "Install gaming utilities (GameMode, MangoHUD, etc.)?" && install_packages "Gaming Utilities" "${GAMING_UTILS[@]}"
}

install_gpu_drivers() {
    local GPU_VENDOR
    GPU_VENDOR=$(lspci | grep -E "VGA|3D" | head -n1)
    echo -e "${BLUE}Detected GPU: ${GPU_VENDOR}${NC}"

    if echo "$GPU_VENDOR" | grep -iq nvidia; then
        confirm "Install NVIDIA drivers?" && install_native_packages "NVIDIA Drivers" nvidia nvidia-utils lib32-nvidia-utils nvidia-settings
    elif echo "$GPU_VENDOR" | grep -iq amd; then
        confirm "Install AMD drivers?" && install_native_packages "AMD Drivers" mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
    elif echo "$GPU_VENDOR" | grep -iq intel; then
        confirm "Install Intel drivers?" && install_native_packages "Intel Drivers" mesa lib32-mesa vulkan-intel lib32-vulkan-intel
    else
        warn "Unknown GPU. Skipping driver installation."
    fi
}

install_gamedev_tools() {
    local GAMEDEV_PACKAGES=(godot unity-editor blender krita audacity aseprite)
    confirm "Install game development tools?" && install_packages "Game Development Tools" "${GAMEDEV_PACKAGES[@]}"
}

install_emulators() {
    local EMULATORS=(retroarch dolphin-emu pcsx2 ppsspp desmume snes9x-gtk mupen64plus)
    confirm "Install game emulators?" && install_packages "Emulators" "${EMULATORS[@]}"
}

install_controller_support() {
    confirm "Install controller drivers (Xbox, PlayStation)?" && {
        install_native_packages "Controller Support" xboxdrv xpadneo-dkms
        install_packages "DS4 Driver" ds4drv
    }
}

enable_multilib_repo() {
    confirm "Enable multilib repository for 32-bit game support?" && {
        sudo sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
        sudo pacman -Sy && success "Multilib repo enabled"
    }
}

configure_steam() {
    confirm "Configure Steam for optimal performance?" && {
        mkdir -p ~/.steam/steam/config
        log "Reminder:"
        echo -e "  ${YELLOW}• Enable Steam Play (Proton) for all titles${NC}"
        echo -e "  ${YELLOW}• Use 'gamemoderun %command%' in game launch options${NC}"
    }
}

configure_mangohud() {
    confirm "Configure MangoHUD for FPS/performance overlay?" && {
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
        success "MangoHUD configuration applied"
    }
}

apply_gaming_optimizations() {
    confirm "Apply GameMode and performance tweaks?" && {
        sudo usermod -aG gamemode $USER
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
        success "GameMode configuration applied"
    }
}

# ───────────────────────────────
# Execution
# ───────────────────────────────
install_gaming_platforms
install_wine_stack
install_gaming_utilities
install_gpu_drivers
install_gamedev_tools
install_emulators
install_controller_support
enable_multilib_repo
configure_steam
configure_mangohud
apply_gaming_optimizations

# ───────────────────────────────
# Final Message
# ───────────────────────────────
echo
figlet "Game On!"
success "Gaming setup completed successfully!"
warn "Reboot is recommended to apply all driver and group changes."
echo -e "${BLUE}Post-Setup Checklist:${NC}"
echo -e "  • ✅ Enable Steam Play in Steam Settings"
echo -e "  • ✅ Use 'gamemoderun %command%' in game launch options"
echo -e "  • ✅ Configure your GPU via control panel if needed"
