#!/bin/bash
# Adjusts screen and keyboard backlight when power source changes.
# Started by power-brightness.service, which is triggered by udev.
SAVE_FILE=/var/cache/power-brightness.save

ONLINE=$(cat /sys/class/power_supply/AC/online)

if [ "$ONLINE" = "0" ]; then
    /usr/bin/brightnessctl get > "$SAVE_FILE"
    /usr/bin/brightnessctl set 50%
    /usr/bin/brightnessctl --device='tpacpi::kbd_backlight' set 0
else
    if [ -f "$SAVE_FILE" ]; then
        /usr/bin/brightnessctl set "$(cat "$SAVE_FILE")"
        rm -f "$SAVE_FILE"
    else
        /usr/bin/brightnessctl set 80%
    fi
    /usr/bin/brightnessctl --device='tpacpi::kbd_backlight' set 1
fi
