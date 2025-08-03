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
        echo -e "${YELLOW}Installing missing package: $pkg${NC}"
        sudo pacman -S --noconfirm "$pkg"
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
            clear
            figlet "Script Info"
            echo -e "${BLUE}📦 Arch Linux Post-Install Toolkit${NC}"
            echo
            echo -e "${GREEN}Included Scripts:${NC}"
            printf "  ${YELLOW}%-15s${NC} - %s\n" \
                "base.sh"     "Essential system tweaks and tools" \
                "dev.sh"      "Programming languages and IDEs" \
                "general.sh"  "Daily desktop apps and UI tools" \
                "gaming.sh"   "Steam, Wine, emulators, tweaks" \
                "vm.sh"       "KVM/QEMU, VirtualBox, Docker setup"
            echo
            echo -e "${GREEN}How to Use:${NC}"
            echo -e "  ${CYAN}git clone <your-repo-url>${NC}"
            echo -e "  ${CYAN}cd arch-post-install && chmod +x *.sh${NC}"
            echo -e "  ${CYAN}./setup.sh${NC} to begin"
            echo
            echo -e "${GREEN}Features:${NC}"
            echo -e "  • Interactive selection with gum"
            echo -e "  • Color-coded logs and clean headers"
            echo -e "  • Automatic script chaining for full setup"
            echo
            gum confirm "Return to menu?" && continue
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
