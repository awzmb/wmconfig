#!/bin/sh
xrandr \
    --output HDMI1 --primary --mode 1920x1080 --pos 0x0 --rotate normal \
    --output LVDS1 --mode 1366x768 --pos 1920x0 --rotate normal && \
nitrogen --restore
