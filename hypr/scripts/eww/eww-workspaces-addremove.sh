#!/usr/bin/bash

current_workspace="$(hyprctl activeworkspace -j | jq -r '.id')"
ratio="$1"

windows=$(hyprctl workspaces -j | jq -c '.[]' | grep "\"id\":$current_workspace" | jq -r '.windows')
windows=$((windows+ratio))
echo "windows=$windows" | socat - "unix-connect:/tmp/eww-$((current_workspace-1)).sock"