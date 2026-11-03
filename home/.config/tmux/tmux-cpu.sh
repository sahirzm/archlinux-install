#!/bin/sh
# CPU load for the tmux status bar, replacing tmux-plugins/tmux-cpu.
#
# Prints the catppuccin cpu module text: the load percentage, coloured by the
# same thresholds the plugin used (@cpu_medium_thresh 30, @cpu_high_thresh 80).
#
# Why the cache: tmux re-runs every #() in the status line whenever the status
# line is redrawn -- any pane output, any command -- throttled to once a second,
# regardless of status-interval. The plugin sampled CPU on every call with a 2
# second cache, so the module repainted (value, fg and bg colours) every 2
# seconds and its trailing segments shifted with it. Here a reading is kept for
# 30 seconds, and it is the load averaged since the previous reading, so the
# number no longer jitters either.
#
# No tmux(1) calls: the colours and thresholds are constants below, so a run
# costs one /proc/stat read.
export LC_ALL=C

ttl=${CPU_TTL:-30}
high_thresh=80

cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/tmux
value_file=$cache_dir/cpu
sample_file=$cache_dir/cpu-sample

# catppuccin mocha, as @cpu_low_*_color / @cpu_high_*_color resolved to: below
# the high threshold the text sits on the module background, above it inverts to
# crust on red.
fg_low='#cdd6f4'
bg_low='#313244'
fg_high='#11111b'
bg_high='#f38ba8'

# Print the total and idle jiffies of the first (aggregate) line of /proc/stat.
read_sample() {
	set -- $(sed -n '1{s/^cpu  *//;p;}' /proc/stat)
	echo $(( $1 + $2 + $3 + $4 + $5 + $6 + $7 + $8 )) $(( $4 + $5 ))
}

render() { # $1 = percentage in tenths
	whole=$(( $1 / 10 ))
	frac=$(( $1 % 10 ))
	if [ "$whole" -ge "$high_thresh" ]; then
		fg=$fg_high bg=$bg_high
	else
		fg=$fg_low bg=$bg_low
	fi
	[ "$whole" -lt 10 ] && whole=" $whole"
	printf '#[fg=%s,bg=%s] %s.%s%%#[fg=%s]' "$fg" "$bg" "$whole" "$frac" "$bg"
}

now=$(date +%s)
if [ -f "$value_file" ]; then
	ts=$(sed -n '1p' "$value_file")
	if [ -n "$ts" ] && [ $(( now - ts )) -lt "$ttl" ]; then
		sed -n '2p' "$value_file"
		exit 0
	fi
fi

set -- $(read_sample)
ctotal=$1 cidle=$2
ptotal='' pidle=''
if [ -f "$sample_file" ]; then
	read ptotal pidle <"$sample_file"
fi
printf '%s %s\n' "$ctotal" "$cidle" >"$sample_file.$$" && mv -f "$sample_file.$$" "$sample_file"

if [ -n "$ptotal" ]; then
	dtotal=$(( ctotal - ptotal ))
	dilde=$(( cidle - pidle ))
else
	# Nothing to diff against yet (fresh boot, wiped cache): take a short
	# sample now so the module is not blank until the next reading. Retry a
	# few times because an idle machine can add no jiffies in 200ms.
	for _ in 1 2 3 4 5; do
		sleep 0.2
		set -- $(read_sample)
		dtotal=$(( $1 - ctotal ))
		dilde=$(( $2 - cidle ))
		[ "$dtotal" -gt 0 ] && break
	done
	printf '%s %s\n' "$1" "$2" >"$sample_file.$$" && mv -f "$sample_file.$$" "$sample_file"
fi
[ "$dtotal" -gt 0 ] || exit 0

text=$(render $(( (dtotal - dilde) * 1000 / dtotal )))
[ -n "$text" ] || exit 0
mkdir -p "$cache_dir" || exit 0
{
	printf '%s\n' "$now"
	printf '%s\n' "$text"
} >"$value_file.$$" && mv -f "$value_file.$$" "$value_file"
printf '%s\n' "$text"
