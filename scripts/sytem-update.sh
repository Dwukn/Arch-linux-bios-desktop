#!/bin/bash
# Script was inspired by on ml4w update script
# Arch Linux System Update Script
# Streamlined update script specifically for Arch Linux
set -euo pipefail

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
CONFIG_DIR="$HOME/.config/arch-updater"
CONFIG_FILE="$CONFIG_DIR/config"

# Check if command exists
_commandExists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if package is installed
_isInstalled() {
    local package="$1"
    pacman -Qi "$package" &>/dev/null
}

# Load configuration
_loadConfig() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
}

# Save configuration
_saveConfig() {
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" << EOF
# Arch Updater Configuration
AUR_HELPER="$AUR_HELPER"
AUTO_SNAPSHOT=${AUTO_SNAPSHOT:-false}
UPDATE_FLATPAK=${UPDATE_FLATPAK:-true}
PARALLEL_DOWNLOADS=${PARALLEL_DOWNLOADS:-5}
EOF
}

# Detect available AUR helpers
_detectAURHelpers() {
    local helpers=("yay" "paru")
    local available=()

    for helper in "${helpers[@]}"; do
        if _commandExists "$helper"; then
            available+=("$helper")
        fi
    done

    echo "${available[@]}"
}

# Select AUR helper
_selectAURHelper() {
    local available
    IFS=' ' read -ra available <<< "$(_detectAURHelpers)"

    if [[ ${#available[@]} -eq 0 ]]; then
        echo -e "${YELLOW}:: No AUR helpers found${NC}"
        echo -e "${CYAN}:: Available AUR helpers: yay, paru, pikaur, trizen, aurman${NC}"
        if gum confirm "Install yay (recommended)?"; then
            echo -e "${BLUE}:: Installing yay...${NC}"
            git clone https://aur.archlinux.org/yay.git /tmp/yay
            cd /tmp/yay && makepkg -si
            rm -rf /tmp/yay
            AUR_HELPER="yay"
            return 0
        else
            echo -e "${YELLOW}:: Continuing with pacman only${NC}"
            AUR_HELPER="pacman"
            return 0
        fi
    fi

    if [[ -n "$AUR_HELPER" ]] && _commandExists "$AUR_HELPER"; then
        echo -e "${GREEN}:: Using configured AUR helper: $AUR_HELPER${NC}"
        return 0
    fi

    if [[ ${#available[@]} -eq 1 ]]; then
        AUR_HELPER="${available[0]}"
        echo -e "${GREEN}:: Using detected AUR helper: $AUR_HELPER${NC}"
        return 0
    fi

    echo -e "${CYAN}:: Multiple AUR helpers detected:${NC}"
    if _commandExists "gum"; then
        AUR_HELPER=$(printf '%s\n' "${available[@]}" "pacman-only" | gum choose --header "Select AUR helper:")
    else
        for i in "${!available[@]}"; do
            echo "$((i+1)). ${available[i]}"
        done
        echo "$((${#available[@]}+1)). pacman-only"

        while true; do
            read -p "Enter your choice (1-$((${#available[@]}+1))): " choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le $((${#available[@]}+1)) ]]; then
                if [[ "$choice" -eq $((${#available[@]}+1)) ]]; then
                    AUR_HELPER="pacman"
                else
                    AUR_HELPER="${available[$((choice-1))]}"
                fi
                break
            else
                echo -e "${RED}:: Invalid choice. Please try again.${NC}"
            fi
        done
    fi

    if [[ "$AUR_HELPER" == "pacman-only" ]]; then
        AUR_HELPER="pacman"
    fi

    echo -e "${GREEN}:: AUR helper set to: $AUR_HELPER${NC}"
}

# Create system snapshot with timeshift
_createSnapshot() {
    if ! _isInstalled "timeshift"; then
        if gum confirm "Timeshift not installed. Install it for system snapshots?"; then
            sudo pacman -S timeshift
        else
            echo -e "${YELLOW}:: Skipping snapshot creation${NC}"
            return 0
        fi
    fi

    echo
    local create_snapshot=false

    if [[ "$AUTO_SNAPSHOT" == "true" ]]; then
        create_snapshot=true
        echo -e "${BLUE}:: Auto-snapshot enabled${NC}"
    else
        if _commandExists "gum"; then
            gum confirm "Create a system snapshot before updating?" && create_snapshot=true
        else
            read -p "Create a system snapshot before updating? (y/N): " confirm
            [[ "$confirm" =~ ^[Yy]$ ]] && create_snapshot=true
        fi
    fi

    if [[ "$create_snapshot" == "true" ]]; then
        local comment="Pre-update snapshot $(date '+%Y-%m-%d %H:%M')"

        if _commandExists "gum" && [[ "$AUTO_SNAPSHOT" != "true" ]]; then
            local user_comment
            user_comment=$(gum input --placeholder "Snapshot comment (optional)..." --value "$comment")
            [[ -n "$user_comment" ]] && comment="$user_comment"
        fi

        echo -e "${BLUE}:: Creating snapshot: '$comment'${NC}"
        if sudo timeshift --create --comments "$comment" --scripted; then
            echo -e "${GREEN}:: Snapshot created successfully${NC}"

            if gum confirm "Update GRUB to include new snapshot?"; then
                echo -e "${BLUE}:: Updating GRUB configuration...${NC}"
                sudo grub-mkconfig -o /boot/grub/grub.cfg
            fi
        else
            echo -e "${RED}:: Failed to create snapshot${NC}"
            if ! gum confirm "Continue update without snapshot?"; then
                echo -e "${YELLOW}:: Update aborted${NC}"
                exit 1
            fi
        fi
    else
        echo -e "${YELLOW}:: Snapshot creation skipped${NC}"
    fi
}

# Update mirrorlist
_updateMirrorlist() {
    if _commandExists "reflector" && gum confirm "Update mirrorlist with reflector?"; then
        echo -e "${BLUE}:: Updating mirrorlist...${NC}"
        sudo reflector --country "$(curl -s ipinfo.io/country)" --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
        echo -e "${GREEN}:: Mirrorlist updated${NC}"
    fi
}

# Perform system update
_performUpdate() {
    local update_failed=false

    echo -e "${BOLD}${BLUE}:: Starting system update...${NC}"
    echo

    # Update package databases
    echo -e "${BLUE}:: Syncing package databases...${NC}"
    sudo pacman -Sy

    # Check for updates
    local updates
    updates=$(pacman -Qu 2>/dev/null | wc -l)

    if [[ "$updates" -eq 0 ]]; then
        echo -e "${GREEN}:: System is already up to date${NC}"
    else
        echo -e "${CYAN}:: Found $updates package(s) to update${NC}"

        # Show what will be updated
        if gum confirm "Show packages to be updated?"; then
            echo -e "${CYAN}:: Packages to be updated:${NC}"
            pacman -Qu
            echo
        fi

        # Perform update based on AUR helper
        case "$AUR_HELPER" in
            "pacman")
                echo -e "${BLUE}:: Updating official packages...${NC}"
                sudo pacman -Syyu --noconfirm
                ;;
            *)
                echo -e "${BLUE}:: Updating system with $AUR_HELPER...${NC}"
                $AUR_HELPER -Syu
                ;;
        esac

        [[ $? -ne 0 ]] && update_failed=true
    fi

    # Update Flatpak if enabled and installed
    if [[ "$UPDATE_FLATPAK" == "true" ]] && _commandExists "flatpak"; then
        echo -e "${BLUE}:: Updating Flatpak applications...${NC}"
        flatpak update -y
        [[ $? -ne 0 ]] && update_failed=true
    fi

    # Clean package cache
    # if gum confirm "Clean package cache?"; then
    #     echo -e "${BLUE}:: Cleaning package cache...${NC}"
    #     if [[ "$AUR_HELPER" == "pacman" ]]; then
    #         sudo pacman -Sc
    #     else
    #         $AUR_HELPER -Sc
    #     fi
    # fi

    # Check for orphaned packages
    # local orphans
    # orphans=$(pacman -Qtdq 2>/dev/null)
    # if [[ -n "$orphans" ]]; then
    #     echo -e "${YELLOW}:: Found orphaned packages:${NC}"
    #     echo "$orphans"
    #     if gum confirm "Remove orphaned packages?"; then
    #         echo "$orphans" | sudo pacman -Rns -
    #     fi
    # fi

    # if [[ "$update_failed" == "true" ]]; then
    #     return 1
    # else
    #     return 0
    # fi
}

# Show system information
_showSystemInfo() {
    echo -e "${BOLD}${CYAN}:: System Information${NC}"
    echo -e "${BLUE}Kernel:${NC} $(uname -r)"
    echo -e "${BLUE}Uptime:${NC} $(uptime -p)"
    echo -e "${BLUE}Packages:${NC} $(pacman -Q | wc -l) installed"

    if _commandExists "neofetch"; then
        echo
        neofetch --stdout --config none --disable title underline
    fi
    echo
}

# Main execution
main() {
    # Check if running on Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        echo -e "${RED}:: This script is designed for Arch Linux only${NC}"
        exit 1
    fi

    # Check for root
    if [[ $EUID -eq 0 ]]; then
        echo -e "${RED}:: Don't run this script as root${NC}"
        exit 1
    fi

    # Load configuration
    _loadConfig

    # Clear screen and show header
    clear

    if _commandExists "figlet"; then
        figlet -f slant "Arch Update" 2>/dev/null
    else
        echo -e "${BOLD}${CYAN}=== ARCH LINUX UPDATER ===${NC}"
    fi

    echo
    _showSystemInfo

    # Confirm start
    if _commandExists "gum"; then
        if ! gum confirm "Start system update?"; then
            echo -e "${YELLOW}:: Update cancelled${NC}"
            exit 0
        fi
    else
        read -p "Start system update? (Y/n): " confirm
        if [[ "$confirm" =~ ^[Nn]$ ]]; then
            echo -e "${YELLOW}:: Update cancelled${NC}"
            exit 0
        fi
    fi

    echo
    echo -e "${GREEN}:: Update process started${NC}"
    echo

    # Select AUR helper
    _selectAURHelper

    # Update mirrorlist
    _updateMirrorlist

    # Create snapshot
    _createSnapshot

    # Perform update
    echo
    _performUpdate
    update_result=$?

    # Save configuration
    _saveConfig

    # Post-update actions
    echo
    if [[ $update_result -eq 0 ]]; then
        echo -e "${BOLD}${GREEN}:: Update completed successfully!${NC}"

        # Notify if available
        if _commandExists "notify-send"; then
            notify-send "Arch Update" "System update completed successfully" --icon=software-update-available
        fi

        # Refresh waybar if running
        if pgrep -x waybar >/dev/null; then
            pkill -RTMIN+1 waybar
            echo -e "${BLUE}:: Waybar refreshed${NC}"
        fi

        # Check if reboot is needed
        if [[ -f /var/run/reboot-required ]] || _commandExists "needrestart"; then
            echo -e "${YELLOW}:: System reboot may be required${NC}"
            if gum confirm "Reboot now?"; then
                sudo reboot
            fi
        fi

    else
        echo -e "${BOLD}${RED}:: Update completed with errors${NC}"
        if _commandExists "notify-send"; then
            notify-send "Arch Update" "System update completed with errors" --icon=dialog-error
        fi
    fi

    echo
    echo -e "${CYAN}:: Update process finished${NC}"
    read -p "Press [ENTER] to exit..."
}

# Handle interrupts gracefully
trap 'echo -e "\n${YELLOW}:: Update interrupted${NC}"; exit 130' INT TERM

# Run main function
main "$@"
