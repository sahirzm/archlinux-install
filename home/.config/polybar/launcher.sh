#!/usr/bin/env bash

# Add this script to your wm startup file.
DIR="$HOME/.config/polybar"

# Launch the bar
for m in $(polybar --list-monitors | cut -d":" -f1); do
  MONITOR=$m polybar -q --reload main -c "$DIR"/config.ini &
done
