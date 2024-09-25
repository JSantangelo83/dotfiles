#!/bin/bash

function handle {
  if [[ ${1:0:10} == "openwindow" ]] ; then
    /home/js/.config/hypr/scripts/eww/eww-workspaces-addremove.sh 0
  elif [[ ${1:0:11} == "closewindow" ]] ; then
    /home/js/.config/hypr/scripts/eww/eww-workspaces-addremove.sh 0
  fi

}

socat - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done
