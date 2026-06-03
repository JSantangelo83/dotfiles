#!/bin/bash
current=$(hyprctl getoption general:layout -j | jq -r '.str')
if [ "$current" = "lua:columns" ]; then
    hyprctl eval "hl.config({ general = { layout = 'lua:monocle' } })"
else
    hyprctl eval "hl.config({ general = { layout = 'lua:columns' } })"
fi
