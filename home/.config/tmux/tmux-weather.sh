#!/bin/sh
# Current temperature for the tmux status bar, from Open-Meteo (no API key).
# Usage: tmux-weather.sh LATITUDE LONGITUDE [celsius|fahrenheit]
#
# A reading is cached for 15 minutes. After a failed fetch the last reading
# stays on screen and the fetch is retried after 5 minutes. Nothing is printed
# until the first successful fetch.
export LC_ALL=C

lat=${1:-30.27}
lon=${2:--97.74}
unit=${3:-celsius}

cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/tmux
value_file=$cache_dir/weather-$lat,$lon,$unit
attempt_file=$value_file.attempt

# True if file $1 exists and was modified less than $2 minutes ago.
fresh() { [ -n "$(find "$1" -mmin "-$2" 2>/dev/null)" ]; }

if ! fresh "$value_file" 15 && ! fresh "$attempt_file" 5; then
  mkdir -p "$cache_dir" && touch "$attempt_file"
  temp=$(curl -fsS --max-time 10 \
    "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m&temperature_unit=$unit" 2>/dev/null |
    sed -n 's/.*"current":{[^}]*"temperature_2m":\(-\{0,1\}[0-9.]*\).*/\1/p')
  if [ -n "$temp" ]; then
    symbol=°C
    [ "$unit" = fahrenheit ] && symbol=°F
    printf '%.0f%s\n' "$temp" "$symbol" >"$value_file.$$" && mv "$value_file.$$" "$value_file"
  fi
fi

[ -f "$value_file" ] && cat "$value_file"
exit 0
