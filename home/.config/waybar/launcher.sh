#!/usr/bin/env bash
# Launch one waybar process. The config lists outputs explicitly (DP-2,
# DP-3) because waybar 0.15.0's "*" wildcard only draws a bar on one
# output. killall first so a sway reload (exec_always) doesn't stack
# processes. Fixed two-monitor desktop — no hot-plug handling needed.
killall -q waybar 2>/dev/null
waybar >/dev/null 2>&1 &
