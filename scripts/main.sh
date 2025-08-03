#!/bin/bash

# ───── Colors ─────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ───── Prevent Root ─────
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}This script should NOT be run as root.${NC}"
    exit 1
fi

# ───── Install Requirements ─────
for pkg in figlet gum; do
    if ! command -v "$pkg" &>/dev/null; then
        echo -e "${YELLOW}Missing package: ${pkg}${NC}"
        read -p "Do you want to install ${pkg}? [Y/n]: " choice
        choice=${choice:-Y}
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            echo -e "${GREEN}Installing ${pkg}...${NC}"
            sudo pacman -S --noconfirm "$pkg"
        else
            echo -e "${RED}${pkg} is required. Exiting.${NC}"
            exit 1
        fi
    fi
done

# ───── Header ─────
clear
figlet "Arch Setup"
echo -e "${CYAN}Choose your Arch Linux post-install setup${NC}"
echo

# ───── Script Runner ─────
run_script() {
    local script="$1"
    if [[ -f "./$script" ]]; then
        echo -e "${GREEN}Executing $script...${NC}"
        chmod +x "./$script"
        "./$script"
        echo -e "${GREEN}$script completed successfully!${NC}"
    else
        echo -e "${RED}$script not found in current directory.${NC}"
    fi
}

# ───── Main Menu ─────
SETUP_OPTIONS=(
    "🔧 Base Setup"
    "💻 Development Environment"
    "🖥️  General Applications"
    "🎮 Gaming Setup"
    "🖥️  Virtual Machines"
    "🚀 Complete Setup"
    "ℹ️  Script Information"
    "❌ Exit"
)

while true; do
    echo -e "${BLUE}Select a setup option:${NC}"
    CHOICE=$(gum choose "${SETUP_OPTIONS[@]}")

    case "$CHOICE" in
        *"Base Setup"*)
            run_script "base.sh"
            ;;
        *"Development Environment"*)
            run_script "dev.sh"
            ;;
        *"General Applications"*)
            run_script "general.sh"
            ;;
        *"Gaming Setup"*)
            run_script "gaming.sh"
            ;;
        *"Virtual Machines"*)
            run_script "vm.sh"
            ;;
        *"Complete Setup"*)
            echo -e "${PURPLE}Running all setup scripts...${NC}"
            for s in base.sh dev.sh general.sh gaming.sh vm.sh; do
                echo -e "${CYAN}→ $s${NC}"
                run_script "$s"
                echo
            done
            echo -e "${GREEN}✅ Complete setup finished!${NC}"
            ;;
        *"Script Information"*)
        run_script "info.sh"
            ;;
        *"Exit"*)
            echo -e "${GREEN}Thanks for using Arch Setup! 👋${NC}"
            break
            ;;
        *)
            echo -e "${RED}Invalid selection. Try again.${NC}"
            ;;
    esac

    echo
    gum confirm "Return to main menu?" || break
    clear
    figlet "Arch Setup"
    echo -e "${CYAN}Choose your Arch Linux post-install setup${NC}"
done
