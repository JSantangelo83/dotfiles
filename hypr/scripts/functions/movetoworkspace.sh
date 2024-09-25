#!/usr/bin/bash
source "$(dirname "$0")/calculatetmpworkspace.sh"

if [ -z "$1" ]; then
    echo "Usage: $0 <workspace_id>"
    exit 1
fi

goto_workspace=$1
silent=$2
active_workspace="$(hyprctl -j activeworkspace | jq -r .id)"

# If going to the same workspace, then look if there is a sub-workspace to go to
if [ "${active_workspace:0:1}" == "$goto_workspace" ]; then
    # Filtering only the current workspace data
    windows="$(hyprctl -j workspaces | jq "map(select(.id == "$active_workspace"))[0].windows")"
    
    # If it has more than 1 client, push it to the next sub-workspace, otherwise, push it to the previous one
    if [ $windows -gt 1 ]; then
        goto_workspace=$(next_subws $active_workspace)
    else
        goto_workspace=$(prev_subws $active_workspace)
    fi
    
fi

if [ "$silent" ]; then
    hyprctl dispatch movetoworkspacesilent "$goto_workspace"
else
    hyprctl dispatch movetoworkspace "$goto_workspace"
fi

