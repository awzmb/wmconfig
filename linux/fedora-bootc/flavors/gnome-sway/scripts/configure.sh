#!/usr/bin/env bash
#
# configure.sh — gnome-sway flavor: enable the display manager, set Sway as the
# default session, and enable the wlroots seat/suspend services. Runs as root
# inside the flavor image build, after the desktop packages + overlay are in
# place. The base image already did the DE-agnostic configuration.
set -euo pipefail

# enable_unit <unit> [target] — static /usr `.wants` enablement (systemctl is
# unreliable offline in an image build; the symlink under immutable /usr always
# applies at runtime). Skips loudly if the unit is missing so we never ship a
# dangling symlink.
enable_unit() {
	local unit=$1 target=${2:-multi-user.target} src="" d
	for d in /etc/systemd/system /usr/lib/systemd/system /run/systemd/system; do
		[[ -e $d/$unit ]] && { src=$d/$unit; break; }
	done
	if [[ -z $src ]]; then
		echo "!! system unit $unit not found; NOT enabled (package missing?)"
		return
	fi
	mkdir -p "/usr/lib/systemd/system/${target}.wants"
	ln -sfn "$src" "/usr/lib/systemd/system/${target}.wants/$unit"
	systemctl enable "$unit" 2>/dev/null || true
}

# --- seat group required by seatd ----------------------------------------
getent group seat >/dev/null 2>&1 || groupadd -r seat || true

# --- Default to the graphical target -------------------------------------
systemctl set-default graphical.target 2>/dev/null || true
ln -sfn graphical.target /usr/lib/systemd/system/default.target

# --- Enable GDM on boot (display-manager.service) ------------------------
# GDM ships only `Alias=display-manager.service` (no WantedBy); graphical.target
# has `Wants=display-manager.service`. So GDM starts at boot as long as (a) the
# default target is graphical and (b) display-manager.service resolves to gdm.
if [[ -e /usr/lib/systemd/system/gdm.service ]]; then
	printf '\e[1;32m-->\e[0m\e[1m Enabling GDM on boot (display-manager.service)\e[0m\n'
	systemctl enable gdm.service 2>/dev/null || true
	ln -sfn gdm.service /usr/lib/systemd/system/display-manager.service
	ln -sfn /usr/lib/systemd/system/gdm.service \
		/etc/systemd/system/display-manager.service
else
	echo "!! gdm.service not found; GDM will not be enabled on boot"
fi

# --- Make Sway the default graphical session -----------------------------
# GDM remembers the last session per user via AccountsService. Seed a default of
# Sway for the installer user so Sway (not GNOME Shell) is the main WM out of the
# box. GNOME Shell stays installed because GDM's greeter uses it.
# FEDORA_DEFAULT_USER must match the user in ../base/bib/config.toml.
default_user=${FEDORA_DEFAULT_USER:-awzm}
default_session=${FEDORA_DEFAULT_SESSION:-sway}
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

# --- Desktop services ----------------------------------------------------
printf '\e[1;32m-->\e[0m\e[1m Enabling desktop services\e[0m\n'
enable_unit seatd.service
# suspend/resume hook for Hyprland (WantedBy=systemd-suspend/hibernate)
enable_unit suspend-hyprland.service systemd-suspend.service
enable_unit suspend-hyprland.service systemd-hibernate.service

# --- Compile any dconf databases the desktop packages added --------------
dconf update || true

# --- Sanity: warn loudly about missing critical desktop components -------
for chk in "gdm:/usr/bin/gdm" "sway:/usr/bin/sway"; do
	name=${chk%%:*}; path=${chk#*:}
	[[ -e $path ]] || echo "!! MISSING: $name ($path) — likely dropped by 'dnf --skip-broken'; check the install log above"
done

printf '\e[1;32m-->\e[0m\e[1m gnome-sway configure complete\e[0m\n'
