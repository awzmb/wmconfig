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

# Kill client-side shadows and rounded corners (no gsettings key exists — GTK CSS override)
for d in gtk-3.0 gtk-4.0; do
  mkdir -p "$HOME/.config/$d"
  cat > "$HOME/.config/$d/gtk.css" <<'CSS'
/* flat, square windows to match the tiling look */
window, .background,
decoration, headerbar, .titlebar,
.popup, .menu, popover, tooltip {
  border-radius: 0;
  box-shadow: none;
}
CSS
done

# Set single-color background
gsettings set org.gnome.desktop.background picture-options none
gsettings set org.gnome.desktop.background primary-color '#242933'
gsettings set org.gnome.desktop.background color-shading-type 'solid'

# Disable extension validation
gsettings set org.gnome.shell disable-extension-version-validation true

# Enabled GNOME shell extensions
# launch-new-instance: activating a running app opens a NEW window instead of
# focusing the existing one (ships with the gnome-shell-extensions package).
gsettings set org.gnome.shell enabled-extensions "['paperwm@paperwm.github.com', 'space-bar@luchrioh', 'launch-new-instance@gnome-shell-extensions.gcampax.github.com']"

# Favorite (dash) apps
gsettings set org.gnome.shell favorite-apps "['org.chromium.Chromium.desktop', 'org.gnome.Calendar.desktop', 'io.bassi.Amberol.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Software.desktop']"

# Set Chromium as the default web browser (http/https + html)
xdg-settings set default-web-browser org.chromium.Chromium.desktop || true
xdg-mime default org.chromium.Chromium.desktop x-scheme-handler/http x-scheme-handler/https text/html

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

# Set GNOME monospace/document font
gsettings set org.gnome.desktop.interface monospace-font-name "Terminess Nerd Font Medium 12"
gsettings set org.gnome.desktop.interface document-font-name "Terminess Nerd Font Medium 12"

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
# Slow the scroll wheel (sway: scroll_factor 0.4). Key exists on GNOME 47+ only
gsettings writable org.gnome.desktop.peripherals.mouse scroll-factor 2>/dev/null \
  && gsettings set org.gnome.desktop.peripherals.mouse scroll-factor 0.4

# Focus follows mouse (sway: focus_follows_mouse yes). 'sloppy' keeps focus over the desktop
gsettings set org.gnome.desktop.wm.preferences focus-mode 'sloppy'

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
# Full config captured via `dconf dump /org/gnome/shell/extensions/forge/`.
# focus / move (h j k l) mirror sway defaults; resize rides Ctrl+Super h/j/k/l;
# swap defaults on that row are cleared; window wiggling/focus-border disabled;
# gaps set to 0 for the flat tiling look.

# General settings
gsettings set org.gnome.shell.extensions.forge focus-border-toggle false
gsettings set org.gnome.shell.extensions.forge preview-hint-enabled false
gsettings set org.gnome.shell.extensions.forge window-gap-size 0
gsettings set org.gnome.shell.extensions.forge window-gap-size-increment 0

# Keybindings
gsettings set org.gnome.shell.extensions.forge.keybindings con-split-horizontal "['<Shift><Super>b']"
gsettings set org.gnome.shell.extensions.forge.keybindings con-split-layout-toggle "['<Super>g']"
gsettings set org.gnome.shell.extensions.forge.keybindings con-split-vertical "['<Shift><Super>v']"
gsettings set org.gnome.shell.extensions.forge.keybindings con-stacked-layout-toggle "['<Shift><Super>s']"
gsettings set org.gnome.shell.extensions.forge.keybindings con-tabbed-layout-toggle "['<Shift><Super>t']"
gsettings set org.gnome.shell.extensions.forge.keybindings con-tabbed-showtab-decoration-toggle "['<Control><Alt>y']"
gsettings set org.gnome.shell.extensions.forge.keybindings focus-border-toggle "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings prefs-tiling-toggle "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-focus-down "['<Super>j']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-focus-left "['<Super>h']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-focus-right "['<Super>l']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-focus-up "['<Super>k']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-gap-size-decrease "['<Control><Super>minus']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-gap-size-increase "['<Control><Super>plus']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-move-down "['<Shift><Super>j']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-move-left "['<Shift><Super>h']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-move-right "['<Shift><Super>l']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-move-up "['<Shift><Super>k']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-resize-bottom-decrease "['<Control><Super>k']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-resize-bottom-increase "['<Control><Super>j']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-resize-left-decrease "['<Shift><Control><Super>o']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-resize-left-increase "['<Control><Super>y']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-resize-right-decrease "['<Control><Super>h']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-resize-right-increase "['<Control><Super>l']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-resize-top-decrease "['<Shift><Control><Super>u']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-resize-top-increase "['<Control><Super>i']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-snap-center "['<Control><Alt>c']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-snap-one-third-left "['<Control><Alt>d']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-snap-one-third-right "['<Control><Alt>g']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-snap-two-third-left "['<Control><Alt>e']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-snap-two-third-right "['<Control><Alt>t']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-swap-down "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-swap-last-active "['<Super>Return']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-swap-left "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-swap-right "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-swap-up "[]"
gsettings set org.gnome.shell.extensions.forge.keybindings window-toggle-always-float "['<Shift><Super>c']"
gsettings set org.gnome.shell.extensions.forge.keybindings window-toggle-float "['<Shift><Super>space']"
gsettings set org.gnome.shell.extensions.forge.keybindings workspace-active-tile-toggle "['<Shift><Super>w']"

# Make Alacritty the default terminal
gsettings set org.gnome.desktop.default-applications.terminal exec '/usr/bin/alacritty'
gsettings set org.gnome.desktop.default-applications.terminal exec-arg "--working-directory"
#gsettings set org.gnome.nautilus.desktop terminal-prefers-external-terminal true
#gsettings set org.gnome.nautilus.desktop preferred-executable '/usr/bin/alacritty'

# Super+Shift+Return launches the terminal (sway: $mod+Shift+Return).
# GNOME has no built-in "spawn terminal" key, so use a custom keybinding.
# Set name/command/binding BEFORE adding the path to the list so gnome-settings-
# daemon doesn't first register an empty (ungrabbed) accelerator.
term_kb='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/'
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$term_kb" name 'Terminal'
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$term_kb" command '/usr/bin/alacritty'
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$term_kb" binding '<Shift><Super>Return'
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$term_kb']"

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

