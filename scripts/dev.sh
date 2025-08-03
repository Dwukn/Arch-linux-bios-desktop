#!/bin/bash

# ───────────────────────────────
# Colors and Styling
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
log() {
    echo -e "${BLUE}[$(date +"%T")]${NC} $1"
}

success() {
    echo -e "${GREEN}✔ $1${NC}"
}

error() {
    echo -e "${RED}✖ $1${NC}" >&2
}

warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

confirm() {
    gum confirm --prompt "${BOLD}$1${RESET}"
}

# ───────────────────────────────
# Initial Checks
# ───────────────────────────────
if [[ $EUID -eq 0 ]]; then
    error "This script should NOT be run as root."
    exit 1
fi

for pkg in figlet gum; do
    if ! command -v $pkg &> /dev/null; then
        warn "$pkg not found. Installing..."
        sudo pacman -S --noconfirm $pkg || { error "Failed to install $pkg"; exit 1; }
        success "$pkg installed"
    fi
done

clear
figlet "Dev Setup"
log "${BOLD}Starting developer workstation configuration...${RESET}"
echo

# ───────────────────────────────
# Check yay
# ───────────────────────────────
if ! command -v yay &> /dev/null; then
    error "yay is not installed. Please run base.sh first."
    exit 1
fi

# ───────────────────────────────
# Install Common Dev Tools
# ───────────────────────────────
install_common_dev_tools() {
    local tools=(
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
        "terminal"
    )
    confirm "Install common development tools?" && {
        log "Installing common development tools..."
        yay -S --noconfirm "${tools[@]}" && success "Common tools installed"
    }
}

# ───────────────────────────────
# Install Selected Languages
# ───────────────────────────────
install_languages() {
    local languages=(
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

    log "Prompting for language selection..."
    SELECTED_LANGUAGES=$(gum choose --no-limit --header "Select programming languages to install:" "${languages[@]}")

    [[ -z "$SELECTED_LANGUAGES" ]] && return

    for lang in "${languages[@]}"; do
        if echo "$SELECTED_LANGUAGES" | grep -q "$lang"; then
            case $lang in
                *Python*) log "Installing Python..."; sudo pacman -S --noconfirm python python-pip python-pipenv python-virtualenv; pip install --user pylint black flake8;;
                *JavaScript*) log "Installing Node.js & JS tools..."; sudo pacman -S --noconfirm nodejs npm; sudo npm install -g yarn typescript @angular/cli create-react-app;;
                *Java*) log "Installing Java..."; sudo pacman -S --noconfirm jdk-openjdk maven gradle;;
                *C/C++*) log "Installing C/C++..."; sudo pacman -S --noconfirm gcc make cmake gdb valgrind;;
                *Rust*) log "Installing Rust..."; curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; source "$HOME/.cargo/env";;
                *Go*) log "Installing Go..."; sudo pacman -S --noconfirm go go-tools;;
                *PHP*) log "Installing PHP..."; sudo pacman -S --noconfirm php composer;;
                *Ruby*) log "Installing Ruby..."; sudo pacman -S --noconfirm ruby rubygems; gem install bundler;;
                *Kotlin*) log "Installing Kotlin..."; yay -S --noconfirm kotlin;;
                *C#*) log "Installing .NET Core..."; yay -S --noconfirm dotnet-sdk;;
            esac
            success "$lang installed"
        fi
    done
}

# ───────────────────────────────
# Install IDEs
# ───────────────────────────────
install_editors() {
    local editors=(
        "VS Code (already included)"
        "IntelliJ IDEA Community"
        "PyCharm Community"
        "Android Studio"
        "Vim/Neovim"
        "Emacs"
    )

    SELECTED_EDITORS=$(gum choose --no-limit --header "Choose editors/IDEs to install:" "${editors[@]}")
    [[ -z "$SELECTED_EDITORS" ]] && return

    for editor in "${editors[@]}"; do
        case $editor in
            *IntelliJ*) yay -S --noconfirm intellij-idea-community-edition;;
            *PyCharm*) yay -S --noconfirm pycharm-community-edition;;
            *Android*) yay -S --noconfirm android-studio;;
            *Vim*) sudo pacman -S --noconfirm neovim;;
            *Emacs*) sudo pacman -S --noconfirm emacs;;
        esac
        success "$editor installed"
    done
}

# ───────────────────────────────
# Database Tools
# ───────────────────────────────
install_databases() {
    confirm "Install database tools (PostgreSQL, MySQL, Redis)?" && {
        log "Installing database servers..."
        sudo pacman -S --noconfirm postgresql mysql redis
        sudo systemctl enable postgresql
        sudo systemctl enable mysqld
        sudo systemctl enable redis
        success "Database tools installed and enabled"
    }
}

# ───────────────────────────────
# Docker Setup
# ───────────────────────────────
setup_docker() {
    confirm "Setup Docker service and permissions?" && {
        log "Configuring Docker..."
        sudo systemctl enable docker
        sudo usermod -aG docker "$USER"
        success "Docker enabled. Log out and back in for group changes to take effect"
    }
}

# ───────────────────────────────
# Create Development Directories
# ───────────────────────────────
create_dev_dirs() {
    confirm "Create standard development directories?" && {
        log "Creating development directories..."
        mkdir -p ~/Development/{projects/{personal,work,learning},scripts,temp}
        success "Directories created at ~/Development"
    }
}

# ───────────────────────────────
# Git Configuration
# ───────────────────────────────
configure_git() {
    if ! git config --global user.name &> /dev/null; then
        confirm "Do you want to configure Git?" && {
            NAME=$(gum input --placeholder "Enter your full name")
            EMAIL=$(gum input --placeholder "Enter your email")
            git config --global user.name "$NAME"
            git config --global user.email "$EMAIL"
            success "Git configured with $NAME <$EMAIL>"
        }
    else
        log "Git is already configured"
    fi
}

# ───────────────────────────────
# Run Setup Steps
# ───────────────────────────────
install_common_dev_tools
install_languages
install_editors
install_databases
setup_docker
create_dev_dirs
configure_git

# ───────────────────────────────
# Completion Message
# ───────────────────────────────
echo
figlet "Dev Ready!"
success "Your development environment is fully configured!"
warn "Please reboot or re-login to apply group changes (e.g., Docker)"
