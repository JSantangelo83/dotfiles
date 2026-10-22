#!/bin/bash
# Pause the mpvpaper wallpaper while any window is fullscreen (e.g. a game),
# resume it once nothing is fullscreen anymore. Pausing stops video decoding,
# so it frees CPU/GPU without unloading the wallpaper (instant resume).
#
# Multi-monitor safe: instead of counting fullscreen enter/exit events (which
# desyncs when several windows go fullscreen across outputs), we recompute the
# real state from hyprctl on every fullscreen event.

MPV_SOCKET=/tmp/mpv-socket

# Single instance: bail if another copy is already running.
exec 9>"/tmp/mpvpaper-pause-fullscreen.lock"
flock -n 9 || exit 0

EVENT_SOCKET="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
# Fallback for older Hyprland that used /tmp/hypr
[ -S "$EVENT_SOCKET" ] || EVENT_SOCKET="/tmp/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

send_mpv() {
    echo "$1" | socat - "$MPV_SOCKET" 2>/dev/null
}

# Pause if any client is really fullscreen, otherwise resume. Hyprland reports
# fullscreen as a bitmask (1 = maximized, 2 = fullscreen); maximized windows
# must not pause the wallpaper.
sync_pause_state() {
    if [ "$(hyprctl clients -j 2>/dev/null | jq 'any(.[]; .fullscreen >= 2)')" = "true" ]; then
        send_mpv "set pause yes"
    else
        send_mpv "set pause no"
    fi
}

# Apply correct state at startup (e.g. if launched while a game is already up).
sync_pause_state

socat -U - "UNIX-CONNECT:${EVENT_SOCKET}" | while read -r line; do
    case "$line" in
        fullscreen\>\>*) sync_pause_state ;;
    esac
done
