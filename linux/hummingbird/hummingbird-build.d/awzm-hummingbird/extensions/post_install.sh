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

# --- Default to the graphical target + enable GDM ------------------------
# Enablement must be deterministic in an image build: `systemctl` cannot always
# operate offline in the build container, and changes under /etc are subject to
# bootc's first-boot 3-way merge. We therefore write the enablement symlinks
# directly into the immutable /usr tree (always present at runtime) and ALSO ask
# systemctl, as belt-and-suspenders.
systemctl set-default graphical.target 2>/dev/null || true
# Force a graphical default boot regardless of what the base image shipped.
ln -sfn graphical.target /usr/lib/systemd/system/default.target

# GDM ships only `Alias=display-manager.service` (no WantedBy); graphical.target
# has `Wants=display-manager.service`. So GDM starts at boot as long as (a) the
# default target is graphical and (b) display-manager.service resolves to gdm.
if [[ -e /usr/lib/systemd/system/gdm.service ]]; then
	printf '\e[1;32m-->\e[0m\e[1m Enabling GDM on boot (display-manager.service)\e[0m\n'
	systemctl enable gdm.service 2>/dev/null || true
	ln -sfn gdm.service /usr/lib/systemd/system/display-manager.service
	# Keep the conventional /etc alias too (harmless if it does not persist).
	ln -sfn /usr/lib/systemd/system/gdm.service \
		/etc/systemd/system/display-manager.service
else
	echo "!! gdm.service not found; GDM will not be enabled on boot"
fi

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

# --- System locale -------------------------------------------------------
# The Hummingbird base is minimal and may not set a UTF-8 locale, which causes
# `cannot change locale (en_US.UTF-8)` warnings (and breaks tools like fc-cache).
# glibc-langpack-en (package.list) provides the en_US.UTF-8 data; pin it here.
printf '\e[1;32m-->\e[0m\e[1m Setting system locale to en_US.UTF-8\e[0m\n'
printf 'LANG=en_US.UTF-8\n' > /etc/locale.conf

# --- Terminess Nerd Font -------------------------------------------------
# "Terminess Nerd Font" is the Nerd Fonts patched Terminus. It is not packaged
# in Fedora, so fetch the official release tarball and install the faces into
# the immutable /usr font tree. Pinned for reproducibility; override with
# HUMMINGBIRD_NERD_FONTS_VERSION.
nerd_fonts_version=${HUMMINGBIRD_NERD_FONTS_VERSION:-v3.4.0}
terminess_dir=/usr/share/fonts/terminess-nerd-font
terminess_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${nerd_fonts_version}/Terminus.tar.xz"
printf '\e[1;32m-->\e[0m\e[1m Installing Terminess Nerd Font (%s)\e[0m\n' "$nerd_fonts_version"
if command -v curl >/dev/null 2>&1 && curl -fsSL "$terminess_url" -o /tmp/terminess.tar.xz; then
	mkdir -p "$terminess_dir"
	# Only the .ttf faces are needed; skip the bundled README/LICENSE.
	tar -xJf /tmp/terminess.tar.xz -C "$terminess_dir" \
		--wildcards --no-anchored '*.ttf' 2>/dev/null \
		|| tar -xJf /tmp/terminess.tar.xz -C "$terminess_dir" || true
	rm -f /tmp/terminess.tar.xz
else
	echo "!! could not download Terminess Nerd Font from $terminess_url, continuing"
fi

# --- Refresh the font cache ----------------------------------------------
# fc-cache comes from fontconfig (package.list). Rebuild so the newly added
# fonts (Terminess + the packaged fonts) are immediately discoverable.
if command -v fc-cache >/dev/null 2>&1; then
	printf '\e[1;32m-->\e[0m\e[1m Rebuilding font cache\e[0m\n'
	fc-cache -f 2>/dev/null || true
else
	echo "!! fc-cache not found (fontconfig missing?); skipping font cache rebuild"
fi

printf '\e[1;32m-->\e[0m\e[1m post_install complete\e[0m\n'
