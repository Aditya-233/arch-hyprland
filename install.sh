#!/bin/bash

# Exit on any error
set -e

echo "=========================================="
echo "Installing binnewbs Hyprland Rice"
echo "=========================================="

# Step 1: Update system
echo "[1/9] Updating system..."
sudo pacman -S --needed --noconfirm git base-devel
sudo pacman -Syu --noconfirm

# Step 2: Install yay (AUR helper) if not present
echo "[2/9] Installing yay AUR helper..."
if ! command -v yay &> /dev/null; then
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
fi

# Step 3: Install core Hyprland dependencies
echo "[3/9] Installing Hyprland and core dependencies..."
sudo pacman -S --needed --noconfirm \
    hyprland \
    kitty \
    foot \
    waybar \
    rofi \
    swaync \
    grim \
    slurp \
    wl-clipboard \
    cliphist \
    polkit-kde-agent \
    xdg-desktop-portal-hyprland \
    qt5-wayland \
    qt6-wayland \
    pavucontrol \
    brightnessctl \
    bluez \
    bluez-utils \
    blueman \
    network-manager-applet \
    gvfs \
    thunar \
    nwg-look \
    playerctl \
    fastfetch \
    gtk3 gtk4 cava

# Step 4: Install fonts
echo "[4/9] Installing fonts..."
sudo pacman -S --needed --noconfirm \
    ttf-font-awesome \
    ttf-jetbrains-mono-nerd \
    noto-fonts \
    noto-fonts-emoji

# Step 5: Install Matugen (critical for this rice)
echo "[5/9] Installing Matugen..."
yay -S --needed --noconfirm --rebuild --nodiffmenu matugen-bin wlogout vesktop-bin

# Step 6: Backup existing configs
echo "[6/9] Backing up entire ~/.config directory..."
BACKUP_DIR=~/.config_backup_$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"
cp -r ~/.config/* "$BACKUP_DIR/" 2>/dev/null || true
echo "Backup saved to: $BACKUP_DIR"

# Step 7: Clone dotfiles repository with wallpapers
echo "[7/9] Cloning dotfiles repository with wallpapers..."
cd /tmp
rm -rf arch-hyprland
git clone https://github.com/binnewbs/arch-hyprland.git
cd arch-hyprland

# Step 8: Install dotfiles and wallpapers
echo "[8/9] Installing dotfiles and wallpapers..."

echo "Copying configuration files..."
cp -r .config/* ~/.config/

echo "Copying .zshrc to home directory..."
cp .zshrc ~/.zshrc

echo "Copying wallpapers to ~/Pictures/Wallpapers..."
mkdir -p ~/Pictures/Wallpapers
cp -r wallpapers/* ~/Pictures/Wallpapers/
echo "Wallpapers copied successfully!"

# Make scripts executable
echo "Making scripts executable..."
chmod +x ~/.config/hypr/scripts/* ~/.config/waybar/scripts/* 2>/dev/null || true

# Step 9: Generate initial color scheme with Matugen
echo "[9/9] Setting up color scheme and wallpaper..."

# Initialize swww daemon
swww init 2>/dev/null || swww-daemon &
sleep 2

# Find first wallpaper and apply it
FIRST_WALLPAPER=$(find ~/Pictures/Wallpapers -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | head -n 1)

echo "Generating color scheme from: $FIRST_WALLPAPER"
matugen image "$FIRST_WALLPAPER"

echo "Setting wallpaper..."
swww img "$FIRST_WALLPAPER" --transition-type fade --transition-duration 2

echo "✅ Color scheme and wallpaper applied successfully!"

echo ""
echo "=========================================="
echo "✓ Installation Complete!"
echo "=========================================="
echo ""
