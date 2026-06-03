#!/bin/bash
# Usage: nav.sh <left|right|up|down>
# In monocle: left/down = prev, up/right = next
# In other layouts: directional focus
direction=$1
layout=$(hyprctl getoption general:layout -j | jq -r '.str')

if [ "$layout" = "lua:monocle" ]; then
    case "$direction" in
        left|down) hyprctl eval "hl.dispatch(hl.dsp.window.cycle_next({ prev = true }))" ;;
        up|right)  hyprctl eval "hl.dispatch(hl.dsp.window.cycle_next())" ;;
    esac
else
    hyprctl eval "hl.dispatch(hl.dsp.focus({ direction = '$direction' }))"
fi
