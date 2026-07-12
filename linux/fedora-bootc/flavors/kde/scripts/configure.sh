#!/usr/bin/env bash
#
# configure.sh — kde flavor: enable SDDM and default to the graphical target.
# Runs as root inside the flavor image build, after the Plasma packages are
# installed. The base image already did the DE-agnostic configuration.
#
# SDDM tracks the last-used session in its own state and defaults to the Plasma
# (Wayland) session, so there is no AccountsService session seed here (that is a
# GDM mechanism).
set -euo pipefail

# --- Default to the graphical target -------------------------------------
systemctl set-default graphical.target 2>/dev/null || true
ln -sfn graphical.target /usr/lib/systemd/system/default.target

# --- Enable SDDM on boot (display-manager.service) -----------------------
# sddm.service carries `Alias=display-manager.service`; wire it up statically in
# the immutable /usr tree (systemctl enable is unreliable offline in an image
# build) and default display-manager.service to it.
if [[ -e /usr/lib/systemd/system/sddm.service ]]; then
	printf '\e[1;32m-->\e[0m\e[1m Enabling SDDM on boot (display-manager.service)\e[0m\n'
	systemctl enable sddm.service 2>/dev/null || true
	ln -sfn sddm.service /usr/lib/systemd/system/display-manager.service
	ln -sfn /usr/lib/systemd/system/sddm.service \
		/etc/systemd/system/display-manager.service
else
	echo "!! sddm.service not found; SDDM will not be enabled on boot"
fi

# --- Default SDDM to the Wayland Plasma session --------------------------
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/10-wayland.conf <<'EOF'
[General]
DisplayServer=wayland
EOF

# --- Sanity: warn loudly if Plasma/SDDM did not make it into the image ---
for chk in "sddm:/usr/bin/sddm" "plasmashell:/usr/bin/plasmashell"; do
	name=${chk%%:*}; path=${chk#*:}
	[[ -e $path ]] || echo "!! MISSING: $name ($path) — likely dropped by 'dnf --skip-broken'; check the install log above"
done

printf '\e[1;32m-->\e[0m\e[1m kde configure complete\e[0m\n'
