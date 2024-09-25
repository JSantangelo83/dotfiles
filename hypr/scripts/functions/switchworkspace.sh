#!/usr/bin/bash
source "$(dirname "$0")/calculatetmpworkspace.sh"

if [ -z "$1" ]; then
    echo "Usage: $0 <workspace_id>"
    exit 1
fi
goto_workspace=$1
active_workspace="$(hyprctl -j activeworkspace | jq -r .id)"

# If going to the same workspace, then look if there is a sub-workspace to go to
if [ "${active_workspace:0:1}" == "$goto_workspace" ]; then
    goto_workspace=$(next_subws $active_workspace)
    
    # Filtering only the current workspace data
    ws_data="$(hyprctl -j workspaces | jq "map(select(.id == "$goto_workspace"))")"
    
    # if it has no next sub-workspace, then move to the previous one
    if [ "$ws_data" = "[]" ]; then
        goto_workspace=$1
    fi

fi

hyprctl dispatch workspace "$goto_workspace" &>/dev/null

