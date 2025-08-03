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
figlet "Arch Base Setup"
echo -e "${BLUE}Essential system configuration and tweaks${NC}"
echo

# Update system
gum confirm "Update system packages?" && {
    echo -e "${GREEN}Updating system...${NC}"
    sudo pacman -Syu --noconfirm
}

# Ask for AUR helper of choice and install it
if ! command -v yay &> /dev/null && ! command -v paru &> /dev/null; then
    AUR_HELPER=$(gum choose "yay" "paru" --header="Select AUR helper to install:")
    if [[ "$AUR_HELPER" == "yay" || "$AUR_HELPER" == "paru" ]]; then
        gum confirm "Install $AUR_HELPER AUR helper?" && {
            echo -e "${GREEN}Installing $AUR_HELPER...${NC}"
            git clone "https://aur.archlinux.org/$AUR_HELPER.git" /tmp/$AUR_HELPER
            cd /tmp/$AUR_HELPER
            makepkg -si --noconfirm
            cd -
            rm -rf /tmp/$AUR_HELPER
        }
    else
        echo -e "${YELLOW}No valid AUR helper selected. Skipping...${NC}"
    fi
fi


# Essential packages
ESSENTIAL_PACKAGES=(
    "base-devel"
    "git"
    "wget"
    "curl"
    "unzip"
    "htop"
    "fastfetch"
    "tree"
    "vim"
    "nano"
    "bash-completion"
    "man-db"
    "man-pages"
    "reflector"
    "networkmanager"
    "openssh"
)

gum confirm "Install essential packages?" && {
    echo -e "${GREEN}Installing essential packages...${NC}"
    sudo pacman -S --noconfirm "${ESSENTIAL_PACKAGES[@]}"
}

# Configure reflector for faster mirrors
gum confirm "Configure reflector for faster mirrors?" && {
    echo -e "${GREEN}Configuring reflector...${NC}"
    UserCountry=$(gum input --placeholder "Enter your country (e.g. United States)")
    if [[ -n "$UserCountry" ]]; then
        sudo reflector --country "$UserCountry" --age 6 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
        echo -e "${GREEN}Mirrorlist updated for $UserCountry${NC}"
    else
        echo -e "${RED}No country provided. Skipping reflector configuration.${NC}"
    fi
}


# Enable services
gum confirm "Enable NetworkManager and SSH?" && {
    echo -e "${GREEN}Enabling services...${NC}"
    sudo systemctl enable NetworkManager
    sudo systemctl enable sshd
}

# Configure Git (if not already configured)
if ! git config --global user.name &> /dev/null; then
    gum confirm "Configure Git?" && {
        NAME=$(gum input --placeholder "Enter your full name")
        EMAIL=$(gum input --placeholder "Enter your email")
        git config --global user.name "$NAME"
        git config --global user.email "$EMAIL"
        echo -e "${GREEN}Git configured successfully${NC}"
    }
fi

# Add aliases to .bashrc
gum confirm "Add useful aliases to .bashrc?" && {
    echo -e "${GREEN}Adding aliases...${NC}"
    cat >> ~/.bashrc << 'EOF'

# Custom aliases
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
}

# Configure vim
gum confirm "Create basic vim configuration?" && {
    echo -e "${GREEN}Configuring vim...${NC}"
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
}

echo
figlet "Complete!"
echo -e "${GREEN}Base setup completed successfully!${NC}"
echo -e "${YELLOW}Don't forget to reboot if kernel was updated${NC}"
