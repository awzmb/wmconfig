#!/usr/bin/env bash
#
# configure.sh — gnome flavor: enable GDM and default to the GNOME (Wayland)
# session. Runs as root inside the flavor image build, after the GNOME packages
# are installed. The base image already did the DE-agnostic configuration.
set -euo pipefail

# --- Default to the graphical target -------------------------------------
systemctl set-default graphical.target 2>/dev/null || true
ln -sfn graphical.target /usr/lib/systemd/system/default.target

# --- Enable GDM on boot --------------------------------------------------
# gdm.service's [Install] is `WantedBy=graphical.target` + `Alias=display-
# manager.service`. The graphical.target.wants/gdm.service symlink (from WantedBy)
# is what actually starts GDM under graphical.target; the display-manager.service
# alias alone is NOT pulled in. `systemctl enable` is unreliable offline, so write
# both symlinks statically. Default target is graphical.target (above), so GDM
# autostarts at boot.
if [[ -e /usr/lib/systemd/system/gdm.service ]]; then
	printf '\e[1;32m-->\e[0m\e[1m Enabling GDM on boot (graphical.target.wants + display-manager.service)\e[0m\n'
	mkdir -p /usr/lib/systemd/system/graphical.target.wants
	ln -sfn /usr/lib/systemd/system/gdm.service \
		/usr/lib/systemd/system/graphical.target.wants/gdm.service
	ln -sfn gdm.service /usr/lib/systemd/system/display-manager.service
	ln -sfn /usr/lib/systemd/system/gdm.service \
		/etc/systemd/system/display-manager.service
else
	echo "!! gdm.service not found; GDM will not be enabled on boot"
fi

# --- Seed the GNOME session as the default for the installer user --------
# FEDORA_DEFAULT_USER must match the user in ../base/bib/config.toml.
default_user=${FEDORA_DEFAULT_USER:-awzm}
default_session=${FEDORA_DEFAULT_SESSION:-gnome}
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

# --- Side-load GNOME Shell extensions (no Fedora RPMs exist) --------------
# PaperWM (plain JS, source tarball) + space-bar (prebuilt release zip). Fetched
# into the system-wide extensions dir; enabled-extensions +
# disable-extension-version-validation are set via dconf (base gnome.d).
# ponytail: pinned tags — bump these two when gnome-shell moves and an extension
# stops loading. Failures warn (like the dnf --skip-broken path) instead of
# aborting the build.
ext_dir=/usr/share/gnome-shell/extensions
mkdir -p "$ext_dir"

install_paperwm() { # source tarball -> extract straight into the uuid dir
	local tag=v50.0.1 tmp
	tmp=$(mktemp -d)
	curl -fsSL "https://github.com/paperwm/PaperWM/archive/refs/tags/${tag}.tar.gz" \
		| tar -xz -C "$tmp" --strip-components=1
	rm -rf "$ext_dir/paperwm@paperwm.github.com"
	mv "$tmp" "$ext_dir/paperwm@paperwm.github.com"
}

install_spacebar() { # EGO-format zip (metadata.json at root) -> unzip via python stdlib
	local tag=v37 tmp zip dest="$ext_dir/space-bar@luchrioh"
	tmp=$(mktemp -d); zip="$tmp/sb.zip"
	curl -fsSL -o "$zip" \
		"https://github.com/christopher-l/space-bar/releases/download/${tag}/space-bar@luchrioh.zip"
	rm -rf "$dest"; mkdir -p "$dest"
	python3 -m zipfile -e "$zip" "$dest"
	rm -rf "$tmp"
}

if command -v curl >/dev/null && command -v python3 >/dev/null; then
	printf '\e[1;32m-->\e[0m\e[1m Side-loading PaperWM + space-bar extensions\e[0m\n'
	install_paperwm  || echo "!! PaperWM install failed (network?); extension will be absent"
	install_spacebar || echo "!! space-bar install failed (network?); extension will be absent"
else
	echo "!! curl/python3 missing; skipping extension side-load"
fi

# --- Compile any dconf databases the GNOME packages added ----------------
dconf update || true

# --- Sanity: warn loudly if GDM/GNOME did not make it into the image -----
for chk in "gdm:/usr/bin/gdm" "gnome-shell:/usr/bin/gnome-shell"; do
	name=${chk%%:*}; path=${chk#*:}
	[[ -e $path ]] || echo "!! MISSING: $name ($path) — likely dropped by 'dnf --skip-broken'; check the install log above"
done

printf '\e[1;32m-->\e[0m\e[1m gnome configure complete\e[0m\n'
