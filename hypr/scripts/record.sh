#!/usr/bin/bash

wf-recorder_check() {
    if pgrep -x "wf-recorder" > /dev/null; then
        pkill -INT -x wf-recorder
        hyprshade off
        notify-send "Stopping all instances of wf-recorder" "$(cat /tmp/recording.txt)"
        wl-copy < "$(cat /tmp/recording.txt)"
        exit 0
    fi
}

VID="${HOME}/documents/clips/$(date +%Y-%m-%d_%H-%m-%s).mp4"

wf-recorder_check
echo "$VID" > /tmp/recording.txt
geometry="$(slurp)"
x=$(echo $geometry | cut -d' ' -f1 | cut -d',' -f1)
y=$(echo $geometry | cut -d' ' -f1 | cut -d',' -f2)
width=$(echo $geometry | cut -d' ' -f2 | cut -d'x' -f1)
height=$(echo $geometry | cut -d' ' -f2 | cut -d'x' -f2)

sed -i \
-e "s/float x =.*$/float x = $x.0;/g" \
-e "s/float y =.*$/float y = $y.0;/g" \
-e "s/float height =.*$/float height = $height.0;/g" \
-e "s/float width =.*$/float width = $width.0;/g" \
$HOME/.config/hypr/shaders/record.glsl

hyprshade on $HOME/.config/hypr/shaders/record.glsl
wf-recorder -a -g "$geometry" -f "$VID"


