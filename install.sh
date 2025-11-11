#!/bin/bash

# ============================================================================
# Arch Hyprland Rice Installation Script
# ============================================================================
# Updated: November 2025
# Total packages: 45 (39 official + 6 AUR)
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
REPO_URL="https://github.com/Aditya-233/arch-hyprland.git"
REPO_NAME="arch-hyprland"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "\n${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

ask_confirmation() {
    while true; do
        read -p "$1 [y/N]: " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            "" ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# ============================================================================
# System Checks
# ============================================================================

check_system() {
    print_header "System Check"

    if [ ! -f /etc/arch-release ]; then
        print_error "This script is designed for Arch Linux only!"
        exit 1
    fi
    print_success "Arch Linux detected"

    if [ "$EUID" -eq 0 ]; then
        print_error "Please do not run this script as root!"
        exit 1
    fi
    print_success "Running as normal user"

    if ! command -v git &> /dev/null; then
        print_warning "Git not found. Installing..."
        sudo pacman -S --needed --noconfirm git
    fi
    print_success "Git available"
}

# ============================================================================
# Package Installation
# ============================================================================

install_yay() {
    print_header "Installing AUR Helper (yay)"

    if command -v yay &> /dev/null; then
        print_success "yay already installed"
        return
    fi

    print_info "Installing yay..."
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
    print_success "yay installed successfully"
}

install_packages() {
    print_header "Installing Required Packages"

    print_info "Updating system..."
    sudo pacman -Syu --noconfirm

    # Official repository packages (39 packages)
    OFFICIAL_PACKAGES=(
        # Core Hyprland
        hyprland
        hyprlock
        hypridle
        hyprpolkitagent
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk

        # Wayland support
        qt5-wayland
        qt6-wayland

        # Terminals
        foot
        kitty

        # Essential utilities
        nautilus
        rofi
        waybar

        # Network & Bluetooth
        networkmanager
        nm-applet
        bluez
        bluez-utils
        blueman

        # Audio
        pipewire
        pipewire-pulse
        pipewire-alsa
        wireplumber
        pamixer

        # System utilities
        brightnessctl
        grim
        slurp
        wl-clipboard
        cliphist
        rfkill
        libnotify

        # Fonts
        ttf-jetbrains-mono-nerd
        noto-fonts
        noto-fonts-emoji
        ttf-font-awesome

        # Icons & Themes
        papirus-icon-theme
        kvantum

        # Shell & Tools
        zsh
        fastfetch

        # Development
        base-devel
    )

    print_info "Installing ${#OFFICIAL_PACKAGES[@]} official packages..."
    sudo pacman -S --needed --noconfirm "${OFFICIAL_PACKAGES[@]}"
    print_success "Official packages installed"

    # AUR packages (6 packages)
    AUR_PACKAGES=(
        matugen
        swww
        swaync
        wlogout
        colloid-icon-theme-git
        vesktop-bin
    )

    print_info "Installing ${#AUR_PACKAGES[@]} AUR packages..."
    yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"
    print_success "AUR packages installed"

    print_success "Total 45 packages installed (39 official + 6 AUR)"
}

# ============================================================================
# Repository Cloning
# ============================================================================

clone_repository() {
    print_header "Cloning Repository"

    local clone_dir="$HOME/$REPO_NAME"

    if [ -d "$clone_dir" ]; then
        print_warning "Repository already exists at $clone_dir"
        if ask_confirmation "Do you want to remove it and re-clone?"; then
            rm -rf "$clone_dir"
        else
            print_info "Using existing repository"
            return
        fi
    fi

    print_info "Cloning repository to $clone_dir..."
    git clone "$REPO_URL" "$clone_dir"
    print_success "Repository cloned successfully"
}

# ============================================================================
# Configuration Backup & Deployment
# ============================================================================

backup_existing_configs() {
    print_header "Backing Up Existing Configurations"

    local configs_to_backup=(
        ".config/hypr"
        ".config/waybar"
        ".config/rofi"
        ".config/kitty"
        ".config/swaync"
        ".config/wlogout"
        ".config/fastfetch"
        ".config/matugen"
        ".zshrc"
    )

    local backup_needed=false
    for config in "${configs_to_backup[@]}"; do
        if [ -e "$HOME/$config" ]; then
            backup_needed=true
            break
        fi
    done

    if [ "$backup_needed" = false ]; then
        print_info "No existing configurations to backup"
        return
    fi

    print_info "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"

    for config in "${configs_to_backup[@]}"; do
        if [ -e "$HOME/$config" ]; then
            print_info "Backing up $config..."
            local parent_dir=$(dirname "$config")
            mkdir -p "$BACKUP_DIR/$parent_dir"
            cp -r "$HOME/$config" "$BACKUP_DIR/$config"
        fi
    done

    print_success "Backup created at: $BACKUP_DIR"
}

deploy_configs() {
    print_header "Deploying Configurations"

    local repo_dir="$HOME/$REPO_NAME"

    if [ ! -d "$repo_dir" ]; then
        print_error "Repository not found at $repo_dir"
        exit 1
    fi

    print_info "Creating config directories..."
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/Pictures/wallpapers"

    print_info "Copying configuration files..."
    cp -r "$repo_dir/.config/"* "$HOME/.config/"

    if [ -d "$repo_dir/wallpapers" ]; then
        print_info "Copying wallpapers..."
        cp -r "$repo_dir/wallpapers/"* "$HOME/Pictures/wallpapers/" 2>/dev/null || true
    fi

    if [ -f "$repo_dir/.zshrc" ]; then
        print_info "Copying .zshrc..."
        cp "$repo_dir/.zshrc" "$HOME/.zshrc"
    fi

    print_success "Configurations deployed"
}

set_permissions() {
    print_header "Setting Permissions"

    print_info "Making scripts executable..."
    find "$HOME/.config/hypr/scripts" -type f -name "*.sh" -exec chmod +x {} \;

    print_success "Permissions set"
}

# ============================================================================
# Post-Installation Setup
# ============================================================================

post_install_setup() {
    print_header "Post-Installation Setup"

    print_info "Enabling NetworkManager..."
    sudo systemctl enable --now NetworkManager

    print_info "Enabling Bluetooth..."
    sudo systemctl enable --now bluetooth

    if [ "$SHELL" != "$(which zsh)" ]; then
        print_info "Setting Zsh as default shell..."
        chsh -s $(which zsh)
        print_success "Default shell changed to Zsh (will take effect on next login)"
    fi

    if [ -f "$HOME/Pictures/wallpapers/37.jpg" ]; then
        print_info "Generating initial Material Design theme..."
        matugen image "$HOME/Pictures/wallpapers/37.jpg" 2>/dev/null || true

        print_info "Setting default wallpaper..."
        ln -sf "$HOME/Pictures/wallpapers/37.jpg" "$HOME/.config/hypr/current_wallpaper"
    fi

    print_success "Post-installation setup complete"
}

# ============================================================================
# Main Installation Flow
# ============================================================================

main() {
    print_header "Arch Hyprland Rice Installation"
    echo -e "${CYAN}This script will install and configure a complete Hyprland desktop environment${NC}"
    echo -e "${CYAN}with Material Design 3 theming powered by Matugen.${NC}\n"
    echo -e "${YELLOW}Total packages to install: 45 (39 official + 6 AUR)${NC}\n"

    check_system
    install_yay
    install_packages
    clone_repository
    backup_existing_configs
    deploy_configs
    set_permissions
    post_install_setup

    print_header "Installation Complete!"
    echo -e "${GREEN}Your Hyprland rice has been installed successfully!${NC}\n"
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "  1. ${YELLOW}Log out${NC} of your current session"
    echo -e "  2. Select ${YELLOW}Hyprland${NC} from your display manager"
    echo -e "  3. Log in to your new desktop environment"
    echo -e ""
    echo -e "${CYAN}Keybindings:${NC}"
    echo -e "  • ${YELLOW}SUPER + Q${NC} - Close window"
    echo -e "  • ${YELLOW}SUPER + ENTER${NC} - Terminal (foot)"
    echo -e "  • ${YELLOW}SUPER + E${NC} - File manager"
    echo -e "  • ${YELLOW}SUPER + R${NC} - Application launcher"
    echo -e "  • ${YELLOW}SUPER + L${NC} - Lock screen"
    echo -e "  • ${YELLOW}SUPER + [1-5]${NC} - Switch workspace"
    echo -e "  • ${YELLOW}SUPER + SHIFT + [1-5]${NC} - Move window to workspace"
    echo -e ""
    echo -e "${CYAN}Customization:${NC}"
    echo -e "  • Change wallpaper: ${YELLOW}SUPER + W${NC} (wallpaper picker)"
    echo -e "  • Waybar styles: ${YELLOW}SUPER + SHIFT + W${NC}"
    echo -e "  • Power menu: ${YELLOW}wlogout${NC}"
    echo -e ""
    if [ -n "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}Your old configs are backed up at:${NC}"
        echo -e "${BLUE}$BACKUP_DIR${NC}"
        echo -e ""
    fi
    echo -e "${GREEN}Enjoy your new desktop! 🎨${NC}\n"
}

main "$@"
