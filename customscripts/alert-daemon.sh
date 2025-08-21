#!/usr/bin/bash

sudo pkill dunst;

# Run dunst and manage declared hooks
dunst -print | while read -r line; do 
lower_line=$(echo "$line" | tr '[:upper:]' '[:lower:]')
if [[ \
  "$lower_line" == *"estefano"* || \
  "$lower_line" == *"naranjujeli"* || \
  # "$lower_line" == *"abuaf"* || \
  "$lower_line" == *"francobonda"* || \
  # "$lower_line" == *"leandro"* || \
  "$lower_line" == *"alejandro"* || \
  "$lower_line" == *"fede"* || \
  "$lower_line" == *"juana"* || \
  "$lower_line" == *"matimed"* || \
  "$lower_line" == *"youshallwakeup"* || \
  "$lower_line" == *"mention"* || \
  "$lower_line" == *"joa"* || \
  "$lower_line" == *"daniel"* \
  ]]; then
  
  while ! [[ -f /tmp/stopalarm ]] ; do
    pw-play --volume 15 $HOME/documents/audio/siren.mp3
  done
fi
done
