#!/usr/bin/bash

wf-recorder_check() {
    if pgrep -x "wf-recorder" > /dev/null; then
        pkill -INT -x wf-recorder
        hyprctl eval "hl.config({ decoration = { screen_shader = '' } })"
        notify-send "Recording stopped" "$(cat /tmp/recording.txt)"
        wl-copy < "$(cat /tmp/recording.txt)"
        exit 0
    fi
}

VID="${HOME}/videos/recordings/$(date +%Y-%m-%d_%H-%M-%S).mp4"

wf-recorder_check
echo "$VID" > /tmp/recording.txt

MONITOR_INFO=$(hyprctl monitors -j | jq -r '.[] | select(.focused)')
SCREEN_W=$(echo "$MONITOR_INFO" | jq -r '.width')
SCREEN_H=$(echo "$MONITOR_INFO" | jq -r '.height')
MONITOR_X=$(echo "$MONITOR_INFO" | jq -r '.x')
MONITOR_Y=$(echo "$MONITOR_INFO" | jq -r '.y')

geometry="$(slurp)"
[ -z "$geometry" ] && exit 1

gx=$(echo "$geometry" | cut -d' ' -f1 | cut -d',' -f1)
gy=$(echo "$geometry" | cut -d' ' -f1 | cut -d',' -f2)
width=$(echo "$geometry" | cut -d' ' -f2 | cut -d'x' -f1)
height=$(echo "$geometry" | cut -d' ' -f2 | cut -d'x' -f2)

local_x=$((gx - MONITOR_X))
local_y=$((gy - MONITOR_Y))

sed -i \
    -e "s/float x =.*$/float x = ${local_x}.0;/g" \
    -e "s/float y =.*$/float y = ${local_y}.0;/g" \
    -e "s/float width =.*$/float width = ${width}.0;/g" \
    -e "s/float height =.*$/float height = ${height}.0;/g" \
    -e "s/vec2 screen_size =.*$/vec2 screen_size = vec2(${SCREEN_W}.0, ${SCREEN_H}.0);/g" \
    "$HOME/.config/hypr/shaders/record.glsl"

SHADER_TMP="/tmp/record_shader_$$.glsl"
cp "$HOME/.config/hypr/shaders/record.glsl" "$SHADER_TMP"

mkdir -p "$(dirname "$VID")"
hyprctl eval "hl.config({ decoration = { screen_shader = '' } })"
hyprctl eval "hl.config({ decoration = { screen_shader = '$SHADER_TMP' } })"
wf-recorder -a -g "$geometry" -f "$VID"
rm -f "$SHADER_TMP"
