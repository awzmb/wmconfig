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
gsettings set org.gnome.desktop.interface monospace-font-name "Terminus 12"
gsettings set org.gnome.desktop.interface document-font-name "Terminus 12"

# UI tweaks
gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.desktop.interface clock-format '24h'

# Configure keyboard layouts on GNOME
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'us+alt-intl')]"

# Deactivate Caps Lock key
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:none']"

# Remove default switch to application shortcuts
for number in {1..9}; do gsettings set org.gnome.shell.keybindings switch-to-application-"${number}" '[]'; done

# Set shortcuts for workspace switching and moving windows to workspaces
for number in {1..9}; do gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-"${number}" "['<Super>$number']"; done
for number in {1..9}; do gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-"${number}" "['<Super><Shift>$number']"; done

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

