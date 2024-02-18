#!/bin/sh

SPICETIFY_INSTALL_DIR="~/.spicetify"
SPICETIFY_THEME="text-nord"
SPICETIFY_THEME_DIR="${HOME}/.config/spicetify/Themes/${SPICETIFY_THEME}"

#SPOTIFY_PATH="$(flatpak info --show-location com.spotify.Client)/../active/files/extra/share/spotify"
SPOTIFY_PATH="$(find ~/.local/share/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share -type d -iname 'spotify')"
SPOTIFY_PREFS_PATH=$(find ~/.var/app/com.spotify.Client | grep prefs | tail -1)

if [[ ! -d "$SPICETIFY_INSTALL_DIR" ]]; then
  curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh | sh
fi

#spicetify config spotify_path ${SPOTIFY_PATH}
#spicetify config prefs_path ${SPOTIFY_PREFS_PATH}

sed -i "s|spotify_path.*$|spotify_path = ${SPOTIFY_PATH}|g" ~/.config/spicetify/config-xpui.ini
sed -i "s|prefs_path.*$|prefs_path = ${SPOTIFY_PREFS_PATH}|g" ~/.config/spicetify/config-xpui.ini

spicetify update
spicetify backup

spicetify config inject_css 1
spicetify config replace_colors 1
spicetify config custom_apps marketplace

mkdir -p ${SPICETIFY_THEME_DIR}

# get text theme and modify according to system color scheme
curl -L --output "${SPICETIFY_THEME_DIR}/user.css" --url "https://raw.githubusercontent.com/spicetify/spicetify-themes/master/text/user.css"
curl -L --output "${SPICETIFY_THEME_DIR}/color.ini" --url "https://raw.githubusercontent.com/spicetify/spicetify-themes/master/text/color.ini"

spicetify config current_theme ${SPICETIFY_THEME}

spicetify apply
