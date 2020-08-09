#!/bin/sh
xrandr \
--output DP1 --mode 1920x1080 --pos 0x0 --rotate normal \
--output eDP1 --primary --mode 1600x900 --pos 1920x0 --rotate normal &&
nitrogen --restore
~/.config/i3/polybar.sh
