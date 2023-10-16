#!/bin/bash

#### For Desktop ####
# xrandr --output Virtual1 --mode 1920x1080
# autorandr default
#### End Desktop ####

#### For virtual box ####
# gtf 2560 1600 60

# 2560x1600 @ 60.00 Hz (GTF) hsync: 99.36 kHz; pclk: 348.16 MHz
# Modeline "2560x1600_60.00"  348.16  2560 2752 3032 3504  1600 1601 1604 1656  -HSync +Vsync
xrandr --newmode "2560x1600_60.00"  348.16  2560 2752 3032 3504  1600 1601 1604 1656  -HSync +Vsync
xrandr --addmode Virtual1 "2560x1600_60.00"
xrandr --output Virtual1 --primary --mode "2560x1600_60.00" --pos 0x0 --rotate normal --scale 1.2x1.2
VBoxClient-all
#### End virtual box ####

picom --config ~/.config/picom/picom.conf &

nm-applet &
nitrogen --restore &

sleep 1
volumeicon &

