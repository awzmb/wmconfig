#!/usr/bin/env bash
#
# post_install extension.
#
# arkdep sources this after installing all system packages and applying the
# post_install overlay, but before the generic immutability modifications.
# Fedora analogue of awzmlinux/extensions/post_install.sh.
#
# Runs as root inside the image build. $variant points at the variant config.
set -euo pipefail

variant=${HUMMINGBIRD_VARIANT_DIR:-/run/hummingbird/variant}

# --- Timezone -------------------------------------------------------------
# arkdep shipped /etc/localtime -> /usr/share/zoneinfo/UTC
printf '\e[1;32m-->\e[0m\e[1m Setting timezone to UTC\e[0m\n'
ln -sf ../usr/share/zoneinfo/UTC /etc/localtime

# --- Groups required by services -----------------------------------------
# seatd.service runs `seatd -g seat`
getent group seat >/dev/null 2>&1 || groupadd -r seat || true

# --- Remove unwanted packages --------------------------------------------
# Mirrors `pacman -Rdd chromium` from the Arch config.
if [[ -f $variant/package-remove.list ]]; then
	mapfile -t rm_pkgs < <(grep -vE '^\s*#|^\s*$' "$variant/package-remove.list" | xargs -n1 2>/dev/null || true)
	if [[ ${#rm_pkgs[@]} -gt 0 ]]; then
		printf '\e[1;32m-->\e[0m\e[1m Removing: %s\e[0m\n' "${rm_pkgs[*]}"
		dnf -y remove "${rm_pkgs[@]}" || true
	fi
fi

# --- Compile dconf databases shipped via the overlay --------------------
printf '\e[1;32m-->\e[0m\e[1m Updating dconf databases\e[0m\n'
dconf update || true

# --- Sway session: use the eGPU-aware wrapper ----------------------------
# Mirrors the sway.desktop Exec rewrite from the Arch post_install.sh.
sway_desktop=/usr/share/wayland-sessions/sway.desktop
[[ -f $sway_desktop ]] && sed -i -e 's|^Exec=.*|Exec=/usr/local/bin/sway-egpu|' "$sway_desktop"

# --- Default to the graphical target -------------------------------------
systemctl set-default graphical.target || true

# --- Make Sway the default graphical session -----------------------------
# GDM remembers the last session per user via AccountsService. Seed a default
# of Sway for the installer user so Sway (not GNOME Shell) is the main WM out of
# the box. GNOME Shell remains installed because GDM's greeter uses it.
# HUMMINGBIRD_DEFAULT_USER must match the user in bib/config.toml.
default_user=${HUMMINGBIRD_DEFAULT_USER:-awzm}
default_session=${HUMMINGBIRD_DEFAULT_SESSION:-sway}
printf '\e[1;32m-->\e[0m\e[1m Setting %s as default session for user %s\e[0m\n' \
	"$default_session" "$default_user"
install -d -m 0775 /var/lib/AccountsService/users
cat > "/var/lib/AccountsService/users/$default_user" <<EOF
[User]
Session=$default_session
XSession=$default_session
Icon=/var/lib/AccountsService/icons/$default_user
SystemAccount=false
EOF

# --- Enable system services ----------------------------------------------
printf '\e[1;32m-->\e[0m\e[1m Enabling system services\e[0m\n'
for unit in \
	NetworkManager.service \
	gdm.service \
	sshd.service \
	keyd.service \
	seatd.service \
	power-profiles-daemon.service \
	switcheroo-control.service \
	bluetooth.service \
	podman.socket \
	hummingbird-flatpak.service; do
	systemctl enable "$unit" 2>/dev/null || echo "!! could not enable $unit (may not exist yet)"
done

# opensnitch firewall (unit name varies by package)
systemctl enable opensnitchd.service 2>/dev/null || true

# suspend/resume hook for Hyprland (WantedBy=systemd-suspend/hibernate)
systemctl enable suspend-hyprland.service 2>/dev/null || true

# --- Enable per-user services globally -----------------------------------
# Mirrors `systemctl --user enable --now podman.socket` from arkane/post-install.sh
systemctl --global enable podman.socket 2>/dev/null || true
systemctl --global enable hummingbird-pytools.service 2>/dev/null || true

printf '\e[1;32m-->\e[0m\e[1m post_install complete\e[0m\n'
