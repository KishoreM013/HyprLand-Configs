#!/usr/bin/env bash

# Bash script to install a full Hyprland rice environment with notifications,
# status bar, screenshot tools, lockscreen, and essential utilities.

echo "Starting installation of Hyprland desktop dependencies..."

# 0. Update system first (recommended)
sudo pacman -Syu --noconfirm

# 1. HYPRLAND and basics
sudo pacman -S --noconfirm hyprland hyprctl

# 2. Terminal (Alacritty)
sudo pacman -S --noconfirm alacritty

# 3. App launcher (Wofi)
sudo pacman -S --noconfirm wofi

# 4. Notification daemon (Dunst)
sudo pacman -S --noconfirm dunst

# 5. Screenshot tool (Hyprshot)
sudo pacman -S --noconfirm hyprshot

# 6. Lockscreen (Hyprlock)
sudo pacman -S --noconfirm hyprlock

# 7. Status bar (Waybar)
sudo pacman -S --noconfirm waybar

# 8. Wallpaper setter (Hyprpaper)
sudo pacman -S --noconfirm hyprpaper

# 9. System tray support (often provided by Waybar, but just in case)
sudo pacman -S --noconfirm xdg-desktop-portal xdg-desktop-portal-hyprland

# 10. Audio controls (pipewire, pavucontrol, pamixer, playerctl)
sudo pacman -S --noconfirm pipewire wireplumber pipewire-pulse pipewire-alsa pipewire-jack \
pavucontrol pamixer playerctl

# 11. Notification sending utility (libnotify, for 'notify-send')
sudo pacman -S --noconfirm libnotify

# 12. Nerd Fonts (for bar and icon glyphs)
sudo pacman -S --noconfirm ttf-jetbrains-mono-nerd ttf-firacode-nerd

# 13. Power management
sudo pacman -S --noconfirm wl-logout

# 14. Additional tools/tools for dotfiles (rofi, neovim, git, etc.)
sudo pacman -S --noconfirm rofi neovim git network-manager-applet blueman

# 15. Media support / thumbnailers (optional but recommended)
sudo pacman -S --noconfirm ffmpegthumbnailer tumbler

# 16. GNOME polkit agent (for authentication prompts in Wayland)
sudo pacman -S --noconfirm polkit-gnome

# 17. Clipboard manager
sudo pacman -S --noconfirm wl-clipboard cliphist

echo "All core dependencies for a Hyprland rice have been installed!"
echo "You may need to log out and back in — or reboot — for PipeWire and Hyprland to take full effect."
echo "Check your ~/.config files for further customization, copy your wallpapers/fonts as needed."
