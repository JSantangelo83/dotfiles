#!/usr/bin/bash

sudo pkill dunst;

# Run dunst and manage declared hooks
dunst -print | while read -r line; do 
lower_line=$(echo "$line" | tr '[:upper:]' '[:lower:]')
if [[ \
  "$lower_line" == *"joa"* || \
  "$lower_line" == *"fran"* \
  ]]; then
  
  while ! [[ -f /tmp/stopalarm ]] ; do
    pw-play --volume 15 $HOME/documents/audio/siren.mp3
  done
fi
done
