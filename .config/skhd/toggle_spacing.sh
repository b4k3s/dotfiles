#!/bin/sh
STATE="$HOME/.cache/yabai_spacing_tight"
if [ -f "$STATE" ]; then
    yabai -m space --gap abs:16 --padding abs:18:18:19:19
    rm "$STATE"
else
    yabai -m space --gap abs:6 --padding abs:3:3:3:3
    touch "$STATE"
fi
