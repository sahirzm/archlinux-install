#!/usr/bin/env bash
# Launch waybar so a bar appears on every connected output.
#
# The waybar config sets "output": ["*"], so a single waybar process creates
# one bar per connected monitor (and shares one tray host). With no "output"
# key waybar v0.15 only draws the bar on a single output, which is why a bar
# showed up on just one monitor.
#
# This script also guards against the startup race where sway runs it (via
# exec_always) before all monitors are active: it waits for the set of active
# outputs to stabilise before the first launch, and relaunches waybar
# (debounced) whenever that set later changes (docking / undocking / lid).

set -u

WAYBAR_BIN="${WAYBAR_BIN:-waybar}"

kill_waybar() {
	killall -q waybar 2>/dev/null
	while pgrep -x waybar >/dev/null 2>&1; do sleep 0.1; done
}

launch_waybar() {
	kill_waybar
	"$WAYBAR_BIN" >/dev/null 2>&1 &
}

# Sorted, de-duplicated signature of currently *active* outputs. Using
# active outputs (not merely connected names) means we relaunch only when a
# monitor actually turns on/off — e.g. a docked display finishing its enable
# sequence, or the laptop lid closing.
active_fingerprint() {
	swaymsg -t get_outputs -r 2>/dev/null |
		jq -r '[.[] | select(.active) | .name] | sort | join(",")' 2>/dev/null
}

# 1) Wait for the active-output set to stabilise before the first launch.
last=""
stable=0
for _ in $( # up to ~10s
	seq 1 50
); do
	cur="$(active_fingerprint)"
	if [ "$cur" = "$last" ] && [ -n "$cur" ]; then
		stable=$((stable + 1))
		[ "$stable" -ge 3 ] && break # ~0.6s with no change
	else
		stable=0
	fi
	last="$cur"
	sleep 0.2
done

launch_waybar

# 2) Relaunch waybar (debounced) whenever the active-output set changes.
#    swaymsg -m subscribes continuously (without -m it exits after one event).
#    An outer loop reconnects if the subscription ever drops (e.g. sway reload).
last="$cur"
while true; do
	swaymsg -t subscribe -m '["output"]' 2>/dev/null | while read -r _event; do
		sleep 0.5
		new="$(active_fingerprint)"
		if [ "$new" != "$last" ] && [ -n "$new" ]; then
			last="$new"
			launch_waybar
		fi
	done
	sleep 2 # subscription dropped; reconnect after a brief pause
done
