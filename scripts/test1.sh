#!/bin/bash

## Enhanced SDDM Astronaut Theme Installer with Gum UI
## Based on original by Keyitdev https://github.com/Keyitdev/sddm-astronaut-theme
## Copyright (C) 2022-2025 Keyitdev
## Distributed under the GPLv3+ License https://www.gnu.org/licenses/gpl-3.0.html

set -euo pipefail

# Configuration
readonly THEME_REPO="https://github.com/keyitdev/sddm-astronaut-theme.git"
readonly THEME_NAME="sddm-astronaut-theme"
readonly THEMES_DIR="/usr/share/sddm/themes"
readonly SDDM_CONFIG="/etc/sddm.conf"
readonly VIRTUAL_KBD_CONFIG="/etc/sddm.conf.d/virtualkbd.conf"
readonly HOME_CLONE_PATH="$HOME"
readonly BACKUP_SUFFIX="_$(date +%s)"

# Available themes
readonly -a THEMES=(
    "astronaut"
    "black_hole"
    "cyberpunk"
    "hyprland_kath"
    "jake_the_dog"
    "japanese_aesthetic"
    "pixel_sakura"
    "pixel_sakura_static"
    "post-apocalyptic_hacker"
    "purple_leaves"
)

# Theme descriptions
readonly -A THEME_DESCRIPTIONS=(
    ["astronaut"]="🚀 Astronaut - Space explorer theme"
    ["black_hole"]="🌑 Black hole - Dark space theme"
    ["cyberpunk"]="🌆 Cyberpunk - Neon futuristic theme"
    ["hyprland_kath"]="✨ Hyprland Kath - Animated theme"
    ["jake_the_dog"]="🐕 Jake the dog - Animated Adventure Time theme"
    ["japanese_aesthetic"]="🏮 Japanese aesthetic - Minimalist Japanese theme"
    ["pixel_sakura"]="🌸 Pixel sakura - Animated pixel art theme"
    ["pixel_sakura_static"]="🖼️  Pixel sakura static - Static pixel art theme"
    ["post-apocalyptic_hacker"]="💻 Post-apocalyptic hacker - Dark hacker theme"
    ["purple_leaves"]="🍃 Purple leaves - Nature theme with purple accents"
)

# Utility functions (fallback for when gum is not available)
log_info() {
    if command -v gum &> /dev/null; then
        gum style --foreground="#00ff00" "✓ $*"
    else
        echo -e "\e[32m✓ $*\e[0m"
    fi
}

log_error() {
    if command -v gum &> /dev/null; then
        gum style --foreground="#ff0000" "✗ $*" >&2
    else
        echo -e "\e[31m✗ $*\e[0m" >&2
    fi
}

log_warning() {
    if command -v gum &> /dev/null; then
        gum style --foreground="#ffaa00" "⚠ $*"
    else
        echo -e "\e[33m⚠ $*\e[0m"
    fi
}

install_gum() {
    local pkg_manager
    pkg_manager=$(detect_package_manager)

    echo -e "\e[33mInstalling gum for better UI experience...\e[0m"

    case $pkg_manager in
        pacman)
            sudo pacman -S gum
            ;;
        xbps)
            sudo xbps-install -y gum
            ;;
        dnf)
            sudo dnf install -y gum
            ;;
        zypper)
            sudo zypper install -y gum
            ;;
        apt)
            # For apt, we need to add the charm repo
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
            echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
            sudo apt update && sudo apt install -y gum
            ;;
        *)
            echo -e "\e[31mCannot auto-install gum for this package manager.\e[0m"
            echo "Please install gum manually from: https://github.com/charmbracelet/gum"
            return 1
            ;;
    esac

    if command -v gum &> /dev/null; then
        echo -e "\e[32m✓ gum installed successfully\e[0m"
        return 0
    else
        echo -e "\e[31m✗ gum installation failed\e[0m"
        return 1
    fi
}

check_dependencies() {
    local missing_deps=()

    # Check for git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "\e[31m✗ Missing dependencies: ${missing_deps[*]}\e[0m"
        echo -e "\e[31mPlease install the missing dependencies:\e[0m"
        echo "• git: install via your package manager"
        exit 1
    fi

    # Check for gum separately (optional but recommended)
    if ! command -v gum &> /dev/null; then
        echo -e "\e[33m⚠ gum not found - this provides a better UI experience\e[0m"
        echo -n "Would you like to install gum? (y/N): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            if install_gum; then
                echo -e "\e[32m✓ Restarting script with gum support...\e[0m"
                exec "$0" "$@"
            else
                echo -e "\e[33m⚠ Continuing without gum...\e[0m"
            fi
        else
            echo -e "\e[33m⚠ Continuing without gum (using fallback UI)\e[0m"
        fi
    fi
}

detect_package_manager() {
    if command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v xbps-install &> /dev/null; then
        echo "xbps"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    elif command -v apt &> /dev/null; then
        echo "apt"
    else
        echo "unknown"
    fi
}

confirm_action() {
    local prompt="$1"
    if command -v gum &> /dev/null; then
        gum confirm "$prompt"
    else
        echo -n "$prompt (y/N): "
        read -r response
        [[ "$response" =~ ^[Yy]$ ]]
    fi
}

show_spinner() {
    local title="$1"
    local cmd="$2"
    if command -v gum &> /dev/null; then
        gum spin --spinner="dot" --title="$title" -- $cmd
    else
        echo "$title"
        $cmd
    fi
}

install_dependencies() {
    local pkg_manager
    pkg_manager=$(detect_package_manager)

    show_spinner "Detecting package manager..." "sleep 1"
    log_info "Detected package manager: $pkg_manager"

    case $pkg_manager in
        pacman)
            log_info "Installing packages using pacman..."
            if confirm_action "Install SDDM dependencies with pacman?"; then
                # Use --needed to avoid conflicts with existing packages
                sudo pacman --needed -S sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg
                log_info "Packages installed successfully"
            fi
            ;;
        xbps)
            log_info "Installing packages using xbps-install..."
            if confirm_action "Install SDDM dependencies with xbps-install?"; then
                sudo xbps-install -y sddm qt6-svg qt6-virtualkeyboard qt6-multimedia
                log_info "Packages installed successfully"
            fi
            ;;
        dnf)
            log_info "Installing packages using dnf..."
            if confirm_action "Install SDDM dependencies with dnf?"; then
                sudo dnf install -y sddm qt6-qtsvg qt6-qtvirtualkeyboard qt6-qtmultimedia
                log_info "Packages installed successfully"
            fi
            ;;
        zypper)
            log_info "Installing packages using zypper..."
            if confirm_action "Install SDDM dependencies with zypper?"; then
                sudo zypper install -y sddm libQt6Svg6 qt6-virtualkeyboard qt6-multimedia
                log_info "Packages installed successfully"
            fi
            ;;
        apt)
            log_info "Installing packages using apt..."
            if confirm_action "Install SDDM dependencies with apt?"; then
                sudo apt update && sudo apt install -y sddm qt6-svg-dev qml6-module-qtquick-virtualkeyboard qt6-multimedia-dev
                log_info "Packages installed successfully"
            fi
            ;;
        *)
            log_error "Package manager not supported"
            echo -e "\e[33mPlease manually install the following dependencies:\e[0m"
            echo "• sddm"
            echo "• qt6-svg (or equivalent)"
            echo "• qt6-virtualkeyboard (or equivalent)"
            echo "• qt6-multimedia (or equivalent)"
            if ! confirm_action "Continue anyway?"; then
                exit 1
            fi
            ;;
    esac
}

backup_existing() {
    local path="$1"
    local backup_path="${path}${BACKUP_SUFFIX}"

    if [[ -d "$path" ]]; then
        log_warning "Existing installation found at $path"
        if confirm_action "Backup existing installation?"; then
            sudo mv "$path" "$backup_path"
            log_info "Backed up to $backup_path"
        else
            sudo rm -rf "$path"
            log_info "Removed existing installation"
        fi
    fi
}

git_clone() {
    local clone_path="$HOME_CLONE_PATH/$THEME_NAME"

    log_info "Cloning theme repository..."

    backup_existing "$clone_path"

    show_spinner "Cloning from GitHub..." \
        "git clone -b master --depth 1 '$THEME_REPO' '$clone_path'"

    log_info "Theme cloned to $clone_path"
}

copy_files() {
    local source_path="$HOME_CLONE_PATH/$THEME_NAME"
    local dest_path="$THEMES_DIR/$THEME_NAME"

    if [[ ! -d "$source_path" ]]; then
        log_error "Source directory not found: $source_path"
        log_info "Please run the clone operation first"
        return 1
    fi

    log_info "Installing theme files..."

    backup_existing "$dest_path"

    # Create destination directory
    sudo mkdir -p "$dest_path"

    # Copy theme files
    show_spinner "Copying theme files..." \
        "sudo cp -r '$source_path'/* '$dest_path'/"

    # Install fonts
    if [[ -d "$dest_path/Fonts" ]]; then
        show_spinner "Installing fonts..." \
            "sudo cp -r '$dest_path/Fonts'/* /usr/share/fonts/"
        log_info "Fonts installed"
    fi

    log_info "Theme files copied successfully"
}

configure_sddm() {
    log_info "Configuring SDDM..."

    # Main SDDM configuration
    echo "[Theme]
Current=$THEME_NAME" | sudo tee "$SDDM_CONFIG" > /dev/null

    # Virtual keyboard configuration
    sudo mkdir -p "$(dirname "$VIRTUAL_KBD_CONFIG")"
    echo "[General]
InputMethod=qtvirtualkeyboard" | sudo tee "$VIRTUAL_KBD_CONFIG" > /dev/null

    log_info "SDDM configured"
}

choose_option() {
    local prompt="$1"
    shift
    local options=("$@")

    if command -v gum &> /dev/null; then
        gum choose "${options[@]}"
    else
        echo "$prompt"
        select opt in "${options[@]}"; do
            [[ -n "$opt" ]] && { echo "$opt"; break; }
        done
    fi
}

get_input() {
    local prompt="$1"
    local placeholder="$2"

    if command -v gum &> /dev/null; then
        gum input --placeholder="$placeholder"
    else
        echo -n "$prompt: "
        read -r input
        echo "$input"
    fi
}

select_theme() {
    local metadata_path="$THEMES_DIR/$THEME_NAME/metadata.desktop"

    if [[ ! -f "$metadata_path" ]]; then
        log_error "Theme metadata not found: $metadata_path"
        log_info "Please install the theme files first"
        return 1
    fi

    if command -v gum &> /dev/null; then
        gum style --foreground="#00ffff" "🎨 Select Theme Variant"
    else
        echo -e "\e[36m🎨 Select Theme Variant\e[0m"
    fi

    # Create options array with descriptions
    local options=()
    for theme in "${THEMES[@]}"; do
        options+=("${THEME_DESCRIPTIONS[$theme]}")
    done
    options+=("🛠️  Custom theme (specify your own)")

    local selected_option
    selected_option=$(choose_option "Choose a theme:" "${options[@]}")

    local selected_theme
    if [[ "$selected_option" == "🛠️  Custom theme (specify your own)" ]]; then
        selected_theme=$(get_input "Enter custom theme name" "theme name (without .conf)")
        if [[ -z "$selected_theme" ]]; then
            log_error "Theme name cannot be empty"
            return 1
        fi
    else
        # Extract theme name from the selected option
        for theme in "${THEMES[@]}"; do
            if [[ "$selected_option" == "${THEME_DESCRIPTIONS[$theme]}" ]]; then
                selected_theme="$theme"
                break
            fi
        done
    fi

    log_info "Selected theme: $selected_theme"

    # Update metadata file
    local config_line="ConfigFile=Themes/${selected_theme}.conf"
    sudo sed -i "s|^ConfigFile=.*|$config_line|" "$metadata_path"

    log_info "Theme variant configured: $selected_theme"
}

preview_theme() {
    local theme_path="$THEMES_DIR/$THEME_NAME"

    if [[ ! -d "$theme_path" ]]; then
        log_error "Theme not found: $theme_path"
        log_info "Please install the theme first"
        return 1
    fi

    if ! command -v sddm-greeter-qt6 &> /dev/null && ! command -v sddm-greeter &> /dev/null; then
        log_error "SDDM greeter not found"
        log_info "Please install SDDM first"
        return 1
    fi

    log_info "Starting theme preview..."
    log_warning "Press Ctrl+C to exit preview"

    if command -v sddm-greeter-qt6 &> /dev/null; then
        sddm-greeter-qt6 --test-mode --theme "$theme_path"
    else
        sddm-greeter --test-mode --theme "$theme_path"
    fi
}

enable_sddm() {
    log_info "Configuring display manager..."

    # Check if systemd is available
    if ! command -v systemctl &> /dev/null; then
        log_error "systemctl not found. Cannot enable SDDM service."
        return 1
    fi

    # Show current display manager status
    local current_dm=""
    if systemctl is-enabled display-manager.service &> /dev/null; then
        current_dm=$(systemctl status display-manager.service --no-pager -l | grep -o "loaded (/.*" | cut -d'/' -f2- | cut -d'.' -f1 | head -1)
    fi

    if [[ -n "$current_dm" ]]; then
        log_warning "Current display manager: $current_dm"
        if ! confirm_action "Disable $current_dm and enable SDDM?"; then
            log_info "Keeping current display manager"
            return 0
        fi
    fi

    # Disable current display manager and enable SDDM
    show_spinner "Configuring display manager..." \
        "sudo systemctl disable display-manager.service 2>/dev/null || true; sudo systemctl enable sddm.service"

    log_info "SDDM enabled as display manager"
    log_warning "Reboot required to apply changes"
}

wait_for_input() {
    if command -v gum &> /dev/null; then
        gum input --placeholder="Press Enter to continue..."
    else
        echo -n "Press Enter to continue..."
        read -r
    fi
}

main_menu() {
    local options=(
        "🚀 Complete Installation (All steps)"
        "📦 Install Dependencies"
        "📥 Clone Theme Repository"
        "📂 Install Theme Files"
        "🎨 Select Theme Variant"
        "👀 Preview Theme"
        "⚙️  Enable SDDM Service"
        "❌ Exit"
    )

    while true; do
        echo

        if command -v gum &> /dev/null; then
            gum style --foreground="#00ffff" "🎯 Choose an option:"
        else
            echo -e "\e[36m🎯 Choose an option:\e[0m"
        fi

        local choice
        choice=$(choose_option "Select:" "${options[@]}")

        case "$choice" in
            "🚀 Complete Installation (All steps)")
                install_dependencies
                git_clone
                copy_files
                configure_sddm
                select_theme
                enable_sddm
                log_info "Complete installation finished!"
                if command -v gum &> /dev/null; then
                    gum style --foreground="#00ff00" --border="rounded" --padding="1" \
                        "🎉 Installation Complete!" \
                        "" \
                        "Please reboot your system to use SDDM with the new theme."
                else
                    echo -e "\e[32m🎉 Installation Complete!\e[0m"
                    echo
                    echo "Please reboot your system to use SDDM with the new theme."
                fi
                if confirm_action "Exit installer?"; then
                    exit 0
                fi
                ;;
            "📦 Install Dependencies")
                install_dependencies
                ;;
            "📥 Clone Theme Repository")
                git_clone
                ;;
            "📂 Install Theme Files")
                copy_files
                configure_sddm
                ;;
            "🎨 Select Theme Variant")
                select_theme
                ;;
            "👀 Preview Theme")
                preview_theme
                ;;
            "⚙️  Enable SDDM Service")
                enable_sddm
                ;;
            "❌ Exit")
                log_info "Goodbye!"
                exit 0
                ;;
        esac

        echo
        wait_for_input
    done
}

# Main execution
main() {
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        exit 1
    fi

    check_dependencies
    main_menu
}

# Handle interrupts gracefully
trap 'echo; log_info "Installation cancelled by user"; exit 130' INT TERM

main "$@"
