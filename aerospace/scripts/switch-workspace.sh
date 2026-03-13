#!/usr/bin/env bash
TARGET="$1"

# Check if the target workspace is already visible on any monitor
VISIBLE=$(aerospace list-workspaces --monitor all --visible | grep -x "$TARGET")

if [ -n "$VISIBLE" ]; then
    aerospace workspace "$TARGET"   # it's visible → focus that monitor (native behavior)
else
    aerospace summon-workspace "$TARGET"  # not visible → bring it here
fi