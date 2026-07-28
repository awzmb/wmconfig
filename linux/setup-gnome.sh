#!/bin/bash

set -euo pipefail

#PAPERWM_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/gnome-shell/extensions/paperwm@hedning:matrix.org"
#CONFIG_FILE="$PAPERWM_DIR/.cfg/linux/paperwm@paperwm.github.com"

#if [ -d "$PAPERWM_DIR" ]; then
  #echo "PaperWM directory already exists. Performing git pull..."
  #cd "$PAPERWM_DIR"
  #git pull
#else
  #echo "Cloning PaperWM repository..."
  #git clone https://github.com/paperwm/PaperWM.git "$PAPERWM_DIR"
#fi

## Run the install script
#cd "$PAPERWM_DIR"
#./install.sh

# Check if the configuration file exists, create it if not
#if [ ! -f "$CONFIG_FILE" ]; then
  #mkdir -p "$(dirname "$CONFIG_FILE")"
  #touch "$CONFIG_FILE"
#fi

# Install GNOME extensions
#gnome-extensions install "space-bar@luchrioh"
#gnome-extensions enable "https://extensions.gnome.org/extension/5090/space-bar"

# Disable active window drop shadow
#gsettings set org.gnome.desktop.wm.preferences has-shadow false

# Set single-color background
gsettings set org.gnome.desktop.background picture-options none
gsettings set org.gnome.desktop.background primary-color '#242933'
gsettings set org.gnome.desktop.background color-shading-type 'solid'

# Disable extension validation
gsettings set org.gnome.shell disable-extension-version-validation true

# Set GNOME theme to Adwaita-dark
gsettings set org.gnome.desktop.interface gtk-theme "Qogir-Dark"
gsettings set org.gnome.desktop.interface icon-theme "Paper"
gsettings set org.gnome.desktop.wm.preferences theme 'Qogir-Dark'

# Set GNOME to dark mode
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Enable Night Light on GNOME
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true

# Disable GNOME animations
gsettings set org.gnome.desktop.interface enable-animations false

# Set GNOME monospace font to Hack Nerd Font Mono 11
gsettings set org.gnome.desktop.interface monospace-font-name "Terminess Nerd Font Regular 12"
gsettings set org.gnome.desktop.interface document-font-name "Terminess Nerd Font Regular 12"

# UI tweaks
gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.desktop.interface clock-format '24h'

# Configure keyboard layouts on GNOME
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'us+alt-intl')]"

# Deactivate Caps Lock key
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']"

# Touchpad — mirror sway: accel_profile flat, pointer_accel 0.5, tap disabled, natural_scroll
gsettings set org.gnome.desktop.peripherals.touchpad accel-profile 'flat'
gsettings set org.gnome.desktop.peripherals.touchpad speed 0.5
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click false
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true

# Mouse — sway: accel_profile flat, pointer_accel 0.0 (GNOME speed 0.0 = neutral)
gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat'
gsettings set org.gnome.desktop.peripherals.mouse speed 0.0

# Remove default switch to application shortcuts
for number in {1..9}; do gsettings set org.gnome.shell.keybindings switch-to-application-"${number}" '[]'; done

# Set shortcuts for workspace switching and moving windows to workspaces
for number in {1..9}; do gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-"${number}" "['<Super>$number']"; done
for number in {1..9}; do gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-"${number}" "['<Super><Shift>$number']"; done

# Close focused window (sway: $mod+Shift+Q kill)
gsettings set org.gnome.desktop.wm.keybindings close "['<Shift><Super>q']"

# Free GNOME's screensaver lock so Forge's <Super>l (focus-right) works
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "@as []"

# Free GNOME shortcuts that collide with the i3/sway-style Forge keys
gsettings set org.gnome.desktop.wm.keybindings minimize '[]'                         # <Super>h
gsettings set org.gnome.desktop.wm.keybindings switch-input-source '[]'              # <Super>space
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward '[]'     # <Shift><Super>space

# i3/sway-style window management for the Forge extension.
# Forge's schema is relocatable, so gsettings can't reach it by name — use dconf.
# focus / move (h j k l) already match sway defaults; the rest mirror config.sway.
dconf write /org/gnome/shell/extensions/forge/keybindings/window-focus-left    "['<Super>h']"
dconf write /org/gnome/shell/extensions/forge/keybindings/window-focus-down    "['<Super>j']"
dconf write /org/gnome/shell/extensions/forge/keybindings/window-focus-up      "['<Super>k']"
dconf write /org/gnome/shell/extensions/forge/keybindings/window-focus-right   "['<Super>l']"
dconf write /org/gnome/shell/extensions/forge/keybindings/window-move-left     "['<Shift><Super>h']"
dconf write /org/gnome/shell/extensions/forge/keybindings/window-move-down     "['<Shift><Super>j']"
dconf write /org/gnome/shell/extensions/forge/keybindings/window-move-up       "['<Shift><Super>k']"
dconf write /org/gnome/shell/extensions/forge/keybindings/window-move-right    "['<Shift><Super>l']"
dconf write /org/gnome/shell/extensions/forge/keybindings/con-split-horizontal "['<Shift><Super>b']"   # sway: split h
dconf write /org/gnome/shell/extensions/forge/keybindings/con-split-vertical   "['<Shift><Super>v']"   # sway: split v
dconf write /org/gnome/shell/extensions/forge/keybindings/window-toggle-float  "['<Shift><Super>space']" # sway: floating toggle
dconf write /org/gnome/shell/extensions/forge/keybindings/window-swap-last-active "['<Super>Return']"

# disable window wiggling
dconf write /org/gnome/shell/extensions/forge/keybindings/prefs-tiling-toggle "@as []"
dconf write /org/gnome/shell/extensions/forge/keybindings/focus-border-toggle "@as []"

# Resize on a Ctrl+Super h/j/k/l row (overrides Forge's swap defaults on this combo)
dconf write /org/gnome/shell/extensions/forge/keybindings/window-resize-right-decrease  "['<Control><Super>h']"   # shrink width
dconf write /org/gnome/shell/extensions/forge/keybindings/window-resize-bottom-increase "['<Control><Super>j']"   # grow height
dconf write /org/gnome/shell/extensions/forge/keybindings/window-resize-bottom-decrease "['<Control><Super>k']"   # shrink height
dconf write /org/gnome/shell/extensions/forge/keybindings/window-resize-right-increase  "['<Control><Super>l']"   # grow width

# Clear Forge's swap defaults that used to own the Ctrl+Super h/j/k/l row
dconf write /org/gnome/shell/extensions/forge/keybindings/window-swap-left  "@as []"
dconf write /org/gnome/shell/extensions/forge/keybindings/window-swap-down  "@as []"
dconf write /org/gnome/shell/extensions/forge/keybindings/window-swap-up    "@as []"
dconf write /org/gnome/shell/extensions/forge/keybindings/window-swap-right "@as []"

# Make Alacritty the default terminal
gsettings set org.gnome.desktop.default-applications.terminal exec '/usr/bin/alacritty'
gsettings set org.gnome.desktop.default-applications.terminal exec-arg "--working-directory"
#gsettings set org.gnome.nautilus.desktop terminal-prefers-external-terminal true
#gsettings set org.gnome.nautilus.desktop preferred-executable '/usr/bin/alacritty'

# Set a solid color (#242933) as the background
gsettings set org.gnome.desktop.background picture-uri ''
gsettings set org.gnome.desktop.background primary-color '#242933'
gsettings set org.gnome.desktop.background color-shading-type 'solid'

# Make the top bar transparent
#gsettings set org.gnome.shell.extensions.dynamic-panel-transparency transparency 0
#gsettings set org.gnome.shell.extensions.dynamic-panel-transparency max-opacity 0
#gsettings set org.gnome.shell.extensions.dynamic-panel-transparency min-opacity 0

# Set workspaces
gsettings set org.gnome.desktop.wm.preferences num-workspaces 6

# restart GNOME shell
#gnome-session-quit --logout --no-prompt

# Enable PaperWM extension (need to log out before it takes effect)
#gnome-extensions enable paperwm@paperwm.github.com

