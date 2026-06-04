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
    
    # From the main workspace (single-digit id), always allow moving to first tmp regardless of window count
    if [ ${#active_workspace} -eq 1 ] || [ $windows -gt 1 ]; then
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

