#!/bin/bash
# Pause mpvpaper when any window goes fullscreen, resume when it leaves
MPV_SOCKET=/tmp/mpv-socket

send_mpv() {
    echo "$1" | socat - "$MPV_SOCKET" 2>/dev/null
}

handle_event() {
    case "$1" in
        fullscreen>>1)
            send_mpv "set pause yes"
            ;;
        fullscreen>>0)
            send_mpv "set pause no"
            ;;
    esac
}

socat -U - UNIX-CONNECT:/tmp/hypr/"$HYPRLAND_INSTANCE_SIGNATURE"/.socket2.sock | while read -r line; do
    handle_event "$line"
done
