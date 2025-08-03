#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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
figlet "Arch Setup"
echo -e "${CYAN}Choose your Arch Linux post-install setup${NC}"
echo

# Main menu
SETUP_OPTIONS=(
    "🔧 Base Setup - Essential system configuration"
    "💻 Development Environment - Programming tools and IDEs"
    "🖥️  General Applications - Daily desktop apps"
    "🎮 Gaming Setup - Steam, Wine, emulators, and more"
    "🖥️  Virtual Machines - KVM/QEMU/VirtualBox setup"
    "🚀 Complete Setup - Run all scripts in order"
    "ℹ️  Show script information"
    "❌ Exit"
)

while true; do
    echo -e "${BLUE}Select setup option:${NC}"
    CHOICE=$(gum choose "${SETUP_OPTIONS[@]}")

    case "$CHOICE" in
        *"Base Setup"*)
            if [[ -f "./base.sh" ]]; then
                echo -e "${GREEN}Running base setup...${NC}"
                chmod +x ./base.sh
                ./base.sh
            else
                echo -e "${RED}base.sh not found in current directory${NC}"
            fi
            ;;
        *"Development Environment"*)
            if [[ -f "./dev.sh" ]]; then
                echo -e "${GREEN}Running development setup...${NC}"
                chmod +x ./dev.sh
                ./dev.sh
            else
                echo -e "${RED}dev.sh not found in current directory${NC}"
            fi
            ;;
        *"General Applications"*)
            if [[ -f "./general.sh" ]]; then
                echo -e "${GREEN}Running general applications setup...${NC}"
                chmod +x ./general.sh
                ./general.sh
            else
                echo -e "${RED}general.sh not found in current directory${NC}"
            fi
            ;;
        *"Gaming Setup"*)
            if [[ -f "./gaming.sh" ]]; then
                echo -e "${GREEN}Running gaming setup...${NC}"
                chmod +x ./gaming.sh
                ./gaming.sh
            else
                echo -e "${RED}gaming.sh not found in current directory${NC}"
            fi
            ;;
        *"Virtual Machines"*)
            if [[ -f "./vm.sh" ]]; then
                echo -e "${GREEN}Running VM setup...${NC}"
                chmod +x ./vm.sh
                ./vm.sh
            else
                echo -e "${RED}vm.sh not found in current directory${NC}"
            fi
            ;;
        *"Complete Setup"*)
            echo -e "${PURPLE}Running complete setup...${NC}"
            for script in base.sh dev.sh general.sh gaming.sh vm.sh; do
                if [[ -f "./$script" ]]; then
                    echo -e "${CYAN}Running $script...${NC}"
                    chmod +x ./$script
                    ./$script
                    echo -e "${GREEN}$script completed${NC}"
                    echo
                else
                    echo -e "${YELLOW}$script not found, skipping...${NC}"
                fi
            done
            echo -e "${GREEN}Complete setup finished!${NC}"
            ;;
        *"Show script information"*)
            clear
            figlet "Script Info"
            echo -e "${BLUE}Arch Linux Post-Install Scripts${NC}"
            echo
            echo -e "${GREEN}📁 Available Scripts:${NC}"
            echo -e "  ${YELLOW}base.sh${NC}     - Essential system tweaks and configuration"
            echo -e "  ${YELLOW}dev.sh${NC}      - Development environment with language selection"
            echo -e "  ${YELLOW}general.sh${NC}  - Daily desktop applications and utilities"
            echo -e "  ${YELLOW}gaming.sh${NC}   - Complete gaming setup with Steam, Wine, etc."
            echo -e "  ${YELLOW}vm.sh${NC}       - Virtual machine environment (KVM/QEMU)"
            echo
            echo -e "${GREEN}🚀 Usage:${NC}"
            echo -e "  1. Download all scripts to the same directory"
            echo -e "  2. Run: ${CYAN}chmod +x *.sh${NC}"
            echo -e "  3. Run: ${CYAN}./setup.sh${NC} (this script) or individual scripts"
            echo
            echo -e "${GREEN}📋 Features:${NC}"
            echo -e "  • Interactive selection with gum"
            echo -e "  • Clean figlet headers"
            echo -e "  • Automatic dependency checking"
            echo -e "  • User-friendly prompts"
            echo -e "  • No over-complication"
            echo
            echo -e "${GREEN}⚡ Quick Start:${NC}"
            echo -e "  ${CYAN}git clone <your-repo>${NC}"
            echo -e "  ${CYAN}cd arch-post-install${NC}"
            echo -e "  ${CYAN}chmod +x *.sh${NC}"
            echo -e "  ${CYAN}./setup.sh${NC}"
            echo
            gum confirm "Return to main menu?" && continue
            ;;
        *"Exit"*)
            echo -e "${GREEN}Thanks for using Arch Setup! 🎉${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac

    echo
    gum confirm "Return to main menu?" || break
    clear
    figlet "Arch Setup"
    echo -e "${CYAN}Choose your Arch Linux post-install setup${NC}"
    echo
done
