#!/usr/bin/bash

# The first digit is the workspace number, the second digit is the sub-workspace number
# 7 - 7th workspace
# 71 - 7th workspace, 1st sub-workspace
# 72 - 7th workspace, 2nd sub-workspace
# Etc...

function get_data() {
    workspace_id=$1
    workspace_number=${workspace_id:0:1}
    sub_workspace_number=$((${workspace_id:1:1} + 1 - 1))
}

function next_subws() {
    [ -z "$1" ] && exit 1
    get_data $1
    
    # Handle max sub-workspace number (9)
    if [ $sub_workspace_number -eq 9 ]; then
        echo $workspace_number
        exit 0
    fi
    
    next_workspace_id="$workspace_number$((sub_workspace_number + 1))"
    echo $next_workspace_id
}

function prev_subws() {
    [ -z "$1" ] && exit 1
    get_data $1

    prev_workspace_id="$workspace_number$((sub_workspace_number - 1))"
    
    if [ $sub_workspace_number -eq 0 ] || [ $sub_workspace_number -eq 1 ]; then
        prev_workspace_id=$workspace_number
    fi
    
    echo $prev_workspace_id
}