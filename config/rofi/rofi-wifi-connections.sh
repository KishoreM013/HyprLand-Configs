#!/usr/bin/env bash

# Rofi Wi-Fi Menu using nmcli
#
# Author: Gemini
# Depends on: rofi, nmcli, notify-send, and a Nerd Font for icons

# --- Configuration ---
# You can try to auto-detect the Wi-Fi interface, or set it manually
WIFI_INTERFACE=$(nmcli -t -f DEVICE,TYPE dev | grep ':wifi$' | cut -d':' -f1 | head -n1)
# If the above fails or you want to set it manually, uncomment and edit the line below:
# WIFI_INTERFACE="wlan0"

# Check if a Wi-Fi interface was found
if [ -z "$WIFI_INTERFACE" ]; then
    rofi -e "No Wi-Fi interface found. Please check your configuration."
    exit 1
fi

# --- Icons (Nerd Fonts Recommended) ---
ICON_WIFI_CONNECTED="󰖩" # nf-mdi-wifi
ICON_WIFI_DISCONNECTED="󰖨" # nf-mdi-wifi_off
ICON_WIFI_DISABLED="󰖨"
ICON_WIFI_SCANNING=" स्कैनिंग..." # nf-mdi-wifi_sync (modified with text)
ICON_SECURE="" # nf-fa-lock
ICON_OPEN="" # nf-fa-unlock_alt (or use empty string for no icon)
ICON_SIGNAL_GOOD="󰤥" # nf-mdi-wifi_strength_4
ICON_SIGNAL_MEDIUM="󰤢" # nf-mdi-wifi_strength_3
ICON_SIGNAL_FAIR="󰤟" # nf-mdi-wifi_strength_2
ICON_SIGNAL_WEAK="󰤯" # nf-mdi-wifi_strength_1
ICON_TOGGLE_ON="toggle_on" # nf-mdi-toggle_switch
ICON_TOGGLE_OFF="toggle_off" # nf-mdi-toggle_switch_off_outline
ICON_RESCAN="" # nf-fa-refresh
ICON_DISCONNECT="disconnect" # nf-mdi-lan_disconnect or similar

# --- Helper Functions ---

# Get current connection status and SSID
get_current_status() {
    local status
    if nmcli -t -f WIFI radio | grep -q "enabled"; then
        ACTIVE_CONNECTION=$(nmcli -t -f ACTIVE,SSID dev wifi list ifname "$WIFI_INTERFACE" | grep '^yes:' | cut -d':' -f2)
        if [[ -n "$ACTIVE_CONNECTION" ]]; then
            status="$ICON_WIFI_CONNECTED Connected: $ACTIVE_CONNECTION"
        else
            status="$ICON_WIFI_DISCONNECTED Disconnected"
        fi
    else
        status="$ICON_WIFI_DISABLED Wi-Fi Disabled"
    fi
    echo "$status"
}

# Get signal strength icon
get_signal_icon() {
    local strength=$1
    if (( strength > 75 )); then
        echo "$ICON_SIGNAL_GOOD"
    elif (( strength > 50 )); then
        echo "$ICON_SIGNAL_MEDIUM"
    elif (( strength > 25 )); then
        echo "$ICON_SIGNAL_FAIR"
    else
        echo "$ICON_SIGNAL_WEAK"
    fi
}

# Generate Rofi menu options
generate_options() {
    echo "$(get_current_status)"

    if nmcli -t -f WIFI radio | grep -q "enabled"; then
        echo "$ICON_TOGGLE_OFF Turn Wi-Fi Off"
        echo "$ICON_RESCAN Rescan Networks"
        if [[ -n "$ACTIVE_CONNECTION" ]]; then
            echo "$ICON_DISCONNECT Disconnect from $ACTIVE_CONNECTION"
        fi

        # List available Wi-Fi networks
        # Using BSSID to differentiate networks with same SSID
        # Fields: BSSID,SSID,CHAN,RATE,SIGNAL,BARS,SECURITY,ACTIVE
        # We use SSID, SIGNAL, SECURITY, ACTIVE
        # Using awk to format. If SSID is empty, it means it's a hidden network or an issue, skip.
        nmcli -t -f SSID,SIGNAL,SECURITY,ACTIVE dev wifi list ifname "$WIFI_INTERFACE" --rescan auto | awk -F: -v secure_icon="$ICON_SECURE" -v open_icon="$ICON_OPEN" '
            BEGIN { OFS=" "; }
            $1 != "" { # If SSID is not empty
                ssid = $1;
                signal_strength = $2;
                security = $3;
                active = $4;

                # Determine signal icon (crude mapping from signal value)
                sig_icon = "";
                if (signal_strength > 75) sig_icon = "'"$ICON_SIGNAL_GOOD"'";
                else if (signal_strength > 50) sig_icon = "'"$ICON_SIGNAL_MEDIUM"'";
                else if (signal_strength > 25) sig_icon = "'"$ICON_SIGNAL_FAIR"'";
                else sig_icon = "'"$ICON_SIGNAL_WEAK"'";

                sec_icon = (security ~ /(WPA|WEP|RSN)/ ? secure_icon : open_icon);
                if (security == "") sec_icon = open_icon; # Explicitly for open networks

                # Mark active connection
                active_marker = (active == "yes" ? "*" : " ");

                print sig_icon active_marker ssid " (" sec_icon " " signal_strength "%)";
            }
        '
    else
        echo "$ICON_TOGGLE_ON Turn Wi-Fi On"
    fi
}

# --- Main Logic ---

# Get options and display Rofi menu
ROFI_OPTIONS=$(generate_options)
CHOSEN_OPTION=$(echo -e "$ROFI_OPTIONS" | rofi -dmenu -p " Wi-Fi" -i -markup-rows -theme-str 'listview {lines: 8;}') # Adjust lines as needed

# Handle selection
if [[ -n "$CHOSEN_OPTION" ]]; then
    # Extract the core part of the option (SSID or command)
    # Remove icons and markers for easier parsing
    CLEAN_OPTION=$(echo "$CHOSEN_OPTION" | sed -e 's/^[[:space:]]*[^{[:alnum:]}]*[[:space:]]*//' -e 's/[[:space:]]*(.*//' -e 's/^[[:space:]]*\*//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//') # More robust cleaning

    if echo "$CHOSEN_OPTION" | grep -q "Turn Wi-Fi Off"; then
        nmcli radio wifi off && notify-send "Wi-Fi" "Turned Off" -i dialog-information
    elif echo "$CHOSEN_OPTION" | grep -q "Turn Wi-Fi On"; then
        nmcli radio wifi on && notify-send "Wi-Fi" "Turned On" -i dialog-information
    elif echo "$CHOSEN_OPTION" | grep -q "Rescan Networks"; then
        notify-send "Wi-Fi" "Rescanning networks..." -i dialog-information
        # Rescan is often automatic with list, but an explicit trigger can be useful
        nmcli dev wifi rescan ifname "$WIFI_INTERFACE" > /dev/null
        # Re-launch the script to show updated list
        "$0"
        exit 0
    elif echo "$CHOSEN_OPTION" | grep -q "^$ICON_DISCONNECT Disconnect from"; then
        ACTIVE_CONNECTION_TO_DISCONNECT=$(nmcli -t -f ACTIVE,SSID dev wifi list ifname "$WIFI_INTERFACE" | grep '^yes:' | cut -d':' -f2)
        if [ -n "$ACTIVE_CONNECTION_TO_DISCONNECT" ]; then
            nmcli con down "$ACTIVE_CONNECTION_TO_DISCONNECT" && notify-send "Wi-Fi" "Disconnected from $ACTIVE_CONNECTION_TO_DISCONNECT" -i dialog-information
        else
            # Fallback if specific connection name isn't found, try generic disconnect
            nmcli dev disconnect "$WIFI_INTERFACE" && notify-send "Wi-Fi" "Disconnected" -i dialog-information
        fi
    elif echo "$CHOSEN_OPTION" | grep -q "Connected:"; then
        # Do nothing if already connected option is chosen, or open network settings
        # Example: xdg-open nm-connection-editor
        notify-send "Wi-Fi" "Already connected to $(echo $CLEAN_OPTION | sed 's/Connected: //')" -i dialog-information
    elif echo "$CHOSEN_OPTION" | grep -q "Disconnected"; then
        # Do nothing if "Disconnected" status line is chosen
        :
    elif echo "$CHOSEN_OPTION" | grep -q "Wi-Fi Disabled"; then
        # Do nothing if "Wi-Fi Disabled" status line is chosen
        :
    else
        # Attempt to connect to the selected SSID
        # Extract SSID from the chosen option (e.g., "SSID_NAME ( 75%)")
        SSID_TO_CONNECT=$CLEAN_OPTION

        if [[ -n "$SSID_TO_CONNECT" ]]; then
            # Check if network is secure and needs a password
            # This is a bit tricky as we only have the icon.
            # A more robust way would be to get security details again for the specific SSID.
            # For simplicity, we'll try to connect. nmcli will ask for password if needed via agent,
            # or we can prompt with Rofi.

            # Check if already known connection or if it requires password
            # If it's a known connection, `nmcli con up "$SSID_TO_CONNECT"` might work.
            # For a general approach:
            notify-send "Wi-Fi" "Attempting to connect to $SSID_TO_CONNECT..." -i dialog-information

            # Try connecting directly. If it's a known network, it might just connect.
            # If it's new and secured, it might fail or an agent might pop up.
            # To force a Rofi password prompt for secured networks:
            if echo "$CHOSEN_OPTION" | grep -q "$ICON_SECURE"; then
                PASSWORD=$(rofi -dmenu -p "Password for $SSID_TO_CONNECT" -password -lines 0)
                if [[ -n "$PASSWORD" ]]; then
                    nmcli dev wifi connect "$SSID_TO_CONNECT" password "$PASSWORD" ifname "$WIFI_INTERFACE"
                    if [ $? -eq 0 ]; then
                        notify-send "Wi-Fi" "Successfully connected to $SSID_TO_CONNECT" -i dialog-information
                    else
                        notify-send -u critical "Wi-Fi" "Failed to connect to $SSID_TO_CONNECT" -i dialog-error
                    fi
                else
                    notify-send "Wi-Fi" "Connection cancelled: No password provided." -i dialog-warning
                fi
            else # Open network
                nmcli dev wifi connect "$SSID_TO_CONNECT" ifname "$WIFI_INTERFACE"
                if [ $? -eq 0 ]; then
                    notify-send "Wi-Fi" "Successfully connected to $SSID_TO_CONNECT" -i dialog-information
                else
                    notify-send -u critical "Wi-Fi" "Failed to connect to $SSID_TO_CONNECT" -i dialog-error
                fi
            fi
        fi
    fi
fi

exit 0
