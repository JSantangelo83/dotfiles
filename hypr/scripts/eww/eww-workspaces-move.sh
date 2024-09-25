#!/usr/bin/bash

to_update_workspaces="$(expr "$(hyprctl activeworkspace -j | jq -r '.id')")\n$1"
echo -e "$to_update_workspaces" | while read workspace; do
    windows=$(hyprctl workspaces -j | jq -c '.[]' | grep "\"id\":$workspace" | jq -r '.windows')
    echo "windows=$windows" | socat - "unix-connect:/tmp/eww-$((workspace-1)).sock"
done
