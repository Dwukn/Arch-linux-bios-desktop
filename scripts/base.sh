#!/bin/bash

# ───────────────────────────────────────────────
# Color & Output Styling
# ───────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BOLD=$(tput bold)
RESET=$(tput sgr0)

# ───────────────────────────────────────────────
# Logging Functions
# ───────────────────────────────────────────────
log()     { echo -e "${BLUE}[$(date +%T)]${NC} $1"; }
success() { echo -e "${GREEN}✔ $1${NC}"; }
error()   { echo -e "${RED}✖ $1${NC}" >&2; }
warn()    { echo -e "${YELLOW}⚠ $1${NC}"; }
confirm() { gum confirm --prompt "${BOLD}$1${RESET}"; }

# ───────────────────────────────────────────────
# Root Check
# ───────────────────────────────────────────────
[[ $EUID -eq 0 ]] && { error "This script should not be run as root."; exit 1; }

# ───────────────────────────────────────────────
# Dependency Check: figlet & gum
# ───────────────────────────────────────────────
for pkg in figlet gum; do
    if ! command -v "$pkg" &>/dev/null; then
        log "Installing missing package: $pkg"
        sudo pacman -S --noconfirm "$pkg"
    fi
done

clear
figlet "Arch Base Setup"
log "Starting essential Arch Linux system configuration..."

# ───────────────────────────────────────────────
# Functions
# ───────────────────────────────────────────────

choose_aur_helper() {
    if ! command -v yay &>/dev/null && ! command -v paru &>/dev/null; then
        AUR_HELPER=$(gum choose yay paru --header="Select AUR helper to install:")
        confirm "Install AUR helper: $AUR_HELPER?" && {
            log "Installing $AUR_HELPER..."
            git clone https://aur.archlinux.org/$AUR_HELPER.git /tmp/$AUR_HELPER &&
            cd /tmp/$AUR_HELPER &&
            makepkg -si --noconfirm &&
            cd - && rm -rf /tmp/$AUR_HELPER &&
            success "$AUR_HELPER installed"
        }
    else
        success "AUR helper already present"
    fi
}

configure_reflector() {
    confirm "Configure reflector for fast mirrors?" && {
        local country=$(gum input --placeholder "Enter your country (e.g. United States)")
        if [[ -n "$country" ]]; then
            log "Optimizing mirrors for $country"
            sudo reflector --country "$country" --age 6 --protocol https --sort rate --save /etc/pacman.d/mirrorlist &&
            success "Reflector configured"
        else
            warn "No country provided. Skipping reflector."
        fi
    }
}

install_essential_packages() {
    ESSENTIALS=(
        base-devel git wget curl unzip htop fastfetch tree vim nano
        bash-completion man-db man-pages reflector networkmanager openssh
    )
    confirm "Install essential packages?" && {
        printf "%s\n" "${ESSENTIALS[@]}"
        confirm "Proceed with above list?" &&
        sudo pacman -S --noconfirm "${ESSENTIALS[@]}" &&
        success "Essential packages installed"
    }
}

install_additional_packages() {
    confirm "Install additional packages?" && {
        local extra=$(gum input --placeholder "e.g. neofetch zsh flatpak")
        [[ -n "$extra" ]] && sudo pacman -S --noconfirm $extra && success "Additional packages installed"
    }
}

enable_services() {
    confirm "Enable NetworkManager and SSH?" && {
        sudo systemctl enable NetworkManager sshd &&
        success "Services enabled"
    }
}

configure_git() {
    confirm "Configure global Git username & email?" && {
        local name=$(gum input --placeholder "Git username")
        local email=$(gum input --placeholder "Git email")
        if [[ -n "$name" && -n "$email" ]]; then
            git config --global user.name "$name"
            git config --global user.email "$email"
            success "Git configured"
        else
            warn "Git name or email not provided. Skipping."
        fi
    }
}

add_aliases() {
    confirm "Add useful aliases to .bashrc?" && {
        ALIAS_BLOCK=$(cat << 'EOF'

# ───── Custom Aliases ─────
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias search='pacman -Ss'
alias remove='sudo pacman -R'
alias autoremove='sudo pacman -Rns $(pacman -Qtdq)'
EOF
)
        if ! grep -q "Custom Aliases" ~/.bashrc; then
            echo "$ALIAS_BLOCK" >> ~/.bashrc
            success "Aliases added"
        else
            warn "Aliases already exist in .bashrc"
        fi
    }
}

configure_vim() {
    confirm "Create basic vimrc config?" && {
        cat > ~/.vimrc << 'EOF'
set number
set relativenumber
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
set hlsearch
set incsearch
syntax on
set background=dark
EOF
        success ".vimrc configured"
    }
}

update_system() {
    confirm "Update system packages?" && {
        sudo pacman -Syu --noconfirm && success "System updated"
    }
}

# ───────────────────────────────────────────────
# Main Execution
# ───────────────────────────────────────────────
update_system
choose_aur_helper
install_essential_packages
install_additional_packages
configure_reflector
enable_services
configure_git
add_aliases
configure_vim

# ───────────────────────────────────────────────
# Summary
# ───────────────────────────────────────────────
echo
figlet "Complete!"
success "Base setup finished!"
warn "Reboot recommended if kernel or major packages were updated."
