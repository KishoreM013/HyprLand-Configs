#!/bin/bash

# Check if wofi is available and working
if ! command -v wofi &> /dev/null; then
    notify-send "Error" "wofi not found"
    exit 1
fi

# Power menu options with icons
options="🔒 Lock
🚪 Logout
🔄 Reboot
⏻ Shutdown
💤 Suspend"

# Run wofi with explicit dimensions and error handling
selected=$(echo "$options" | wofi \
    --dmenu \
    --prompt "Power Menu" \
    --width 250 \
    --height 200 \
    --xpos 0 \
    --ypos 0 \
    --location center \
    --no-actions \
    --insensitive \
    --cache-file /dev/null \
    2>/dev/null)

# Handle the selection
case $selected in
    "🔒 Lock")
        if command -v hyprlock &> /dev/null; then
            hyprlock
        elif command -v swaylock &> /dev/null; then
            swaylock
        else
            notify-send "Error" "No lock screen available"
        fi
        ;;
    "🚪 Logout")
        hyprctl dispatch exit
        ;;
    "🔄 Reboot")
        systemctl reboot
        ;;
    "⏻ Shutdown")
        systemctl poweroff
        ;;
    "💤 Suspend")
        systemctl suspend
        ;;
esac
