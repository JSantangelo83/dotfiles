#!/usr/bin/bash
current_workspace="$1"

if [ -n "$current_workspace" ]; then
  # Updating the eww current workspace
  eww update "screen-0=$current_workspace"
fi
