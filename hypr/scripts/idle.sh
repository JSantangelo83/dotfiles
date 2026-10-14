#!/bin/bash
# Run by hypridle (see hypridle.conf): "off" once the session has been idle,
# "on" at the first input afterwards. Turns the WLED strip and every monitor
# off, then puts back exactly what was on before.

WLED_IP=192.168.1.52
STATE="${XDG_RUNTIME_DIR:-/tmp}/idle-leds"

wled() {
    curl -sf -m 2 -X POST -H 'Content-Type: application/json' -d "$1" \
        "http://$WLED_IP/json/state" >/dev/null
}

case "$1" in
off)
    # Remember what was lit, so "on" doesn't light a strip that was off.
    if systemctl --user -q is-active ambilight; then
        echo ambilight > "$STATE"
    elif curl -sf -m 2 "http://$WLED_IP/json/state" | jq -e .on >/dev/null; then
        echo static > "$STATE"
    else
        rm -f "$STATE"
    fi
    # Stop the capture *before* the monitors go dark: Hyprland 0.56 segfaults
    # on a capture frame for an output that disappears. stop waits for exit.
    systemctl --user stop ambilight
    wled '{"on":false}'
    hyprctl dispatch 'hl.dsp.dpms({action = "off"})' >/dev/null
    ;;
on)
    hyprctl dispatch 'hl.dsp.dpms({action = "on"})' >/dev/null
    case "$(cat "$STATE" 2>/dev/null)" in
        ambilight) systemctl --user start ambilight ;;   # powers the strip on itself
        static)    wled '{"on":true}' ;;
    esac
    rm -f "$STATE"
    ;;
esac
