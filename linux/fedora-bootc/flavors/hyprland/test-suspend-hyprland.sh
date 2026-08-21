#!/usr/bin/env bash
#
# Self-check for suspend-hyprland's resume wait. Not shipped in the image (lives
# outside overlay/). Run: ./test-suspend-hyprland.sh
#
# The bug this guards: on resume amdgpu returns before the USB4/DPIA links do
# (dmesg shows ~9s of "DPIA AUX failed ... error 7" then a late HPD). Resuming
# Hyprland in that window means empty EDIDs, so the desc: rules miss and the
# catch-all monitor rule grabs the ultrawides with the wrong mode/transform.
set -euo pipefail

script=$(dirname "$0")/overlay/usr/local/bin/suspend-hyprland
STATE=$(mktemp)
# shellcheck disable=SC1090
source <(sed -n '/^wait_for_displays/,/^}/p' "$script")

check() { # name pre_suspend_count min max connected_impl
    local name=$1 min=$3 max=$4
    echo "$2" > "$STATE"
    eval "$5"
    local s=$SECONDS
    wait_for_displays
    local el=$((SECONDS - s))
    if ((el >= min && el <= max)); then
        echo "ok   $name (${el}s)"
    else
        echo "FAIL $name: waited ${el}s, expected ${min}-${max}s"; exit 1
    fi
}

C=$(mktemp); echo 0 > "$C"
check "docked: holds through the DPIA window" 3 9 14 \
    'connected() { n=$(cat "$C"); echo $((n+1)) > "$C"; ((n<9)) && echo 1 || echo 3; }'
check "undocked: no needless delay" 1 0 3 \
    'connected() { echo 1; }'
check "dock never returns: bounded give-up" 3 28 35 \
    'connected() { echo 1; }'
echo PASS
