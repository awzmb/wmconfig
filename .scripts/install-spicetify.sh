#!/bin/sh

SPICETIFY_INSTALL_DIR="~/.config/spicetify"
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

spicetify config inject_css 1
spicetify config replace_colors 1
spicetify config custom_apps marketplace

mkdir -p ${SPICETIFY_THEME_DIR}

# get text theme and modify according to system color scheme
curl -L --output "${SPICETIFY_THEME_DIR}/user.css" --url "https://raw.githubusercontent.com/spicetify/spicetify-themes/master/text/user.css"
curl -L --output "${SPICETIFY_THEME_DIR}/color.ini" --url "https://raw.githubusercontent.com/spicetify/spicetify-themes/master/text/color.ini"

# add font import at the start of document
sed -i "1i@import url(\'https://fonts.cdnfonts.com/css/terminus\');" ${SPICETIFY_THEME_DIR}/user.css
sed -i 's/DM Mono", monospace/Terminus", sans-serif/g' ${SPICETIFY_THEME_DIR}/user.css

# color substitution (so we can use the default theme without explicitly
# defining any color scheme
sed -i 's/1db954/4c566a/g' ${SPICETIFY_THEME_DIR}/color.ini
sed -i 's/1db954/81a1c1/g' ${SPICETIFY_THEME_DIR}/color.ini
sed -i 's/121212/3b4252/g' ${SPICETIFY_THEME_DIR}/color.ini
sed -i 's/1ed760/434c5e/g' ${SPICETIFY_THEME_DIR}/color.ini
sed -i 's/535353/2e3440/g' ${SPICETIFY_THEME_DIR}/color.ini
sed -i 's/535353/2e3440/g' ${SPICETIFY_THEME_DIR}/color.ini
sed -i 's/1a1a1a/a3be8c/g' ${SPICETIFY_THEME_DIR}/color.ini
sed -i 's/FFFFFF/eceff4/g' ${SPICETIFY_THEME_DIR}/color.ini
sed -i 's/FFFFFF/eceff4/g' ${SPICETIFY_THEME_DIR}/color.ini

sed -i 's/00e089/4c566a/g' ${SPICETIFY_THEME_DIR}/color.ini
sed -i 's/2E2837/81a1c1/g' ${SPICETIFY_THEME_DIR}/color.ini
sed -i 's/483b5b/3b4252/g' ${SPICETIFY_THEME_DIR}/color.ini

spicetify config current_theme ${SPICETIFY_THEME}

spicetify backup
spicetify apply
