#!/bin/bash


#!/bin/bash

# Get current brightness
current=$(brightnessctl get)
max=$(brightnessctl max)
percent=$((current * 100 / max))

# Choose icon based on brightness level
if [ $percent -ge 80 ]; then
    icon=""
elif [ $percent -ge 60 ]; then
    icon=""
elif [ $percent -ge 40 ]; then
    icon=""
elif [ $percent -ge 20 ]; then
    icon=""
else
    icon=""
fi

# Output JSON for Waybar
echo "{\"text\": \"$icon $percent%\", \"percentage\": $percent, \"class\": \"brightness-$((percent/20))\"}"
