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
figlet "Dev Setup"
echo -e "${BLUE}Developer workstation configuration${NC}"
echo

# Check for yay
if ! command -v yay &> /dev/null; then
    echo -e "${RED}yay not found. Please run base.sh first.${NC}"
    exit 1
fi

# Common dev tools
COMMON_DEV_TOOLS=(
    "code"
    "git"
    "github-cli"
    "docker"
    "docker-compose"
    "nodejs"
    "npm"
    "postman-bin"
    "dbeaver"
    "sublime-text-4"
    "ghostty"
)

gum confirm "Install common development tools?" && {
    echo -e "${GREEN}Installing common dev tools...${NC}"
    yay -S --noconfirm "${COMMON_DEV_TOOLS[@]}"
}

# Programming languages selection
echo -e "${BLUE}Select programming languages to install:${NC}"

LANGUAGES=(
    "Python (python, pip, pipenv)"
    "JavaScript/Node.js (nodejs, npm, yarn)"
    "Java (jdk-openjdk, maven, gradle)"
    "C/C++ (gcc, make, cmake, gdb)"
    "Rust (rustup, cargo)"
    "Go (go, go-tools)"
    "PHP (php, composer)"
    "Ruby (ruby, rubygems)"
    "Kotlin (kotlin)"
    "C# (.NET Core)"
)

SELECTED_LANGUAGES=$(gum choose --multiple "${LANGUAGES[@]}")

# Install selected languages
if [[ -n "$SELECTED_LANGUAGES" ]]; then
    echo -e "${GREEN}Installing selected programming languages...${NC}"

    if echo "$SELECTED_LANGUAGES" | grep -q "Python"; then
        echo -e "${YELLOW}Installing Python...${NC}"
        sudo pacman -S --noconfirm python python-pip python-pipenv python-virtualenv
        pip install --user pylint black flake8
    fi

    if echo "$SELECTED_LANGUAGES" | grep -q "JavaScript"; then
        echo -e "${YELLOW}Installing JavaScript/Node.js...${NC}"
        sudo pacman -S --noconfirm nodejs npm
        sudo npm install -g yarn typescript @angular/cli create-react-app
    fi

    if echo "$SELECTED_LANGUAGES" | grep -q "Java"; then
        echo -e "${YELLOW}Installing Java...${NC}"
        sudo pacman -S --noconfirm jdk-openjdk maven gradle
    fi

    if echo "$SELECTED_LANGUAGES" | grep -q "C/C++"; then
        echo -e "${YELLOW}Installing C/C++...${NC}"
        sudo pacman -S --noconfirm gcc make cmake gdb valgrind
    fi

    if echo "$SELECTED_LANGUAGES" | grep -q "Rust"; then
        echo -e "${YELLOW}Installing Rust...${NC}"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source ~/.cargo/env
    fi

    if echo "$SELECTED_LANGUAGES" | grep -q "Go"; then
        echo -e "${YELLOW}Installing Go...${NC}"
        sudo pacman -S --noconfirm go go-tools
    fi

    if echo "$SELECTED_LANGUAGES" | grep -q "PHP"; then
        echo -e "${YELLOW}Installing PHP...${NC}"
        sudo pacman -S --noconfirm php composer
    fi

    if echo "$SELECTED_LANGUAGES" | grep -q "Ruby"; then
        echo -e "${YELLOW}Installing Ruby...${NC}"
        sudo pacman -S --noconfirm ruby rubygems
        gem install bundler
    fi

    if echo "$SELECTED_LANGUAGES" | grep -q "Kotlin"; then
        echo -e "${YELLOW}Installing Kotlin...${NC}"
        yay -S --noconfirm kotlin
    fi

    if echo "$SELECTED_LANGUAGES" | grep -q "C#"; then
        echo -e "${YELLOW}Installing .NET Core...${NC}"
        yay -S --noconfirm dotnet-sdk
    fi
fi

# IDEs and Editors
echo -e "${BLUE}Select IDEs and editors:${NC}"

EDITORS=(
    "VS Code (already included)"
    "IntelliJ IDEA Community"
    "PyCharm Community"
    "Android Studio"
    "Vim/Neovim"
    "Emacs"
)

SELECTED_EDITORS=$(gum choose --multiple "${EDITORS[@]}")

if [[ -n "$SELECTED_EDITORS" ]]; then
    if echo "$SELECTED_EDITORS" | grep -q "IntelliJ"; then
        yay -S --noconfirm intellij-idea-community-edition
    fi

    if echo "$SELECTED_EDITORS" | grep -q "PyCharm"; then
        yay -S --noconfirm pycharm-community-edition
    fi

    if echo "$SELECTED_EDITORS" | grep -q "Android Studio"; then
        yay -S --noconfirm android-studio
    fi

    if echo "$SELECTED_EDITORS" | grep -q "Vim/Neovim"; then
        sudo pacman -S --noconfirm neovim
    fi

    if echo "$SELECTED_EDITORS" | grep -q "Emacs"; then
        sudo pacman -S --noconfirm emacs
    fi
fi

# Database tools
gum confirm "Install database tools (PostgreSQL, MySQL, Redis)?" && {
    echo -e "${GREEN}Installing database tools...${NC}"
    sudo pacman -S --noconfirm postgresql mysql redis
    sudo systemctl enable postgresql
    sudo systemctl enable mysqld
    sudo systemctl enable redis
}

# Docker setup
gum confirm "Setup Docker?" && {
    echo -e "${GREEN}Setting up Docker...${NC}"
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    echo -e "${YELLOW}You need to log out and back in for Docker group changes to take effect${NC}"
}

# Development directories
gum confirm "Create development directories?" && {
    echo -e "${GREEN}Creating development directories...${NC}"
    mkdir -p ~/Development/{projects,scripts,temp}
    mkdir -p ~/Development/projects/{personal,work,learning}
}

echo
figlet "Dev Ready!"
echo -e "${GREEN}Development environment setup completed!${NC}"
echo -e "${YELLOW}Some changes may require a reboot or re-login${NC}"
