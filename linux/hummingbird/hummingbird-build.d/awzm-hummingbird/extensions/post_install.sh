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
# `systemctl enable` does not work reliably in this offline image build (the
# enable symlinks it would create under /etc are either never written or do not
# survive into the deployed system), which left services like keyd, seatd,
# bluetooth and podman.socket disabled on first boot. Instead we write the
# enablement (`.wants`) symlinks directly into the immutable /usr tree, which is
# always present at runtime. systemctl is still called as a harmless fallback.

# enable_unit <unit> [target]
# Create a static wants-symlink for a SYSTEM unit in /usr. Skips (with a loud
# warning) if the unit file cannot be found, so we never ship dangling symlinks.
enable_unit() {
	local unit=$1 target=${2:-multi-user.target} src=""
	local d
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

# enable_user_unit <unit> [target]
# Same, for a per-user (global) unit under /usr/lib/systemd/user.
enable_user_unit() {
	local unit=$1 target=${2:-default.target} src=""
	local d
	for d in /etc/systemd/user /usr/lib/systemd/user; do
		[[ -e $d/$unit ]] && { src=$d/$unit; break; }
	done
	if [[ -z $src ]]; then
		echo "!! user unit $unit not found; NOT enabled"
		return
	fi
	mkdir -p "/usr/lib/systemd/user/${target}.wants"
	ln -sfn "$src" "/usr/lib/systemd/user/${target}.wants/$unit"
	systemctl --global enable "$unit" 2>/dev/null || true
}

printf '\e[1;32m-->\e[0m\e[1m Enabling system services (static /usr enablement)\e[0m\n'
enable_unit NetworkManager.service
enable_unit sshd.service
enable_unit keyd.service
enable_unit seatd.service
enable_unit power-profiles-daemon.service
enable_unit switcheroo-control.service
enable_unit bluetooth.service
enable_unit podman.socket sockets.target
enable_unit hummingbird-flatpak.service
enable_unit opensnitchd.service

# --- Virtualization (KVM/libvirt) ----------------------------------------
# Modern libvirt uses modular, socket-activated daemons. Enable the sockets so
# the daemons start on first use; the monolithic libvirtd.socket is enabled too
# as a compatibility fallback (enable_unit skips silently if a unit is absent).
enable_unit virtqemud.socket sockets.target
enable_unit virtnetworkd.socket sockets.target
enable_unit virtstoraged.socket sockets.target
enable_unit virtnodedevd.socket sockets.target
enable_unit virtlogd.socket sockets.target
enable_unit libvirtd.socket sockets.target
# Classic LXC has no daemon socket to enable.

# suspend/resume hook for Hyprland (WantedBy=systemd-suspend/hibernate)
enable_unit suspend-hyprland.service systemd-suspend.service
enable_unit suspend-hyprland.service systemd-hibernate.service

# --- Enable per-user services globally -----------------------------------
# Mirrors `systemctl --user enable --now podman.socket` from arkane/post-install.sh
enable_user_unit podman.socket sockets.target
enable_user_unit hummingbird-pytools.service default.target

# --- Ensure the `python` command exists ----------------------------------
# python-unversioned-command (package.list) provides /usr/bin/python, but the
# bulk `dnf install --skip-broken` can transiently drop it if the overlay has a
# break. Guarantee `python` resolves to python3 if the package did not land.
if [[ ! -e /usr/bin/python ]]; then
	if [[ -e /usr/bin/python3 ]]; then
		printf '\e[1;32m-->\e[0m\e[1m Linking /usr/bin/python -> python3 (fallback)\e[0m\n'
		ln -sfn python3 /usr/bin/python
	else
		echo "!! python3 is not installed; cannot provide a python command"
	fi
fi

# --- Sanity: warn loudly about missing critical components ---------------
# The bulk install uses --skip-broken/--skip-unavailable, which silently drops a
# package (and its dependants) if the overlay has a break. Surface that in
# the build log so it is obvious which components did not make it into the image.
for chk in \
	"NetworkManager:/usr/lib/systemd/system/NetworkManager.service" \
	"gdm:/usr/bin/gdm" \
	"fontconfig(fc-cache):/usr/bin/fc-cache" \
	"python:/usr/bin/python"; do
	name=${chk%%:*}; path=${chk#*:}
	[[ -e $path ]] || echo "!! MISSING: $name ($path) — likely dropped by 'dnf --skip-broken'; check the install log above"
done

# Secure Boot: the image is only Secure Boot-capable if the signed shim is present
# (the Fedora base ships it; turning SB on is a firmware action, not a build step).
rpm -q shim-x64 >/dev/null 2>&1 \
	|| echo "!! shim-x64 not installed; image is NOT Secure Boot capable (enable SB in UEFI after install)"

# --- System locale -------------------------------------------------------
# The Hummingbird base is minimal and may not set a UTF-8 locale, which causes
# `cannot change locale (en_US.UTF-8)` warnings (and breaks tools like fc-cache).
#
# glibc-langpack-en (package.list) is the normal source of the en_US.UTF-8 data,
# but it hard-pins `glibc = <exact EVR>` and the distroless Hummingbird base ships
# a `.hum1` glibc whose EVR no Fedora-repo langpack matches, so dnf --skip-broken
# silently drops it. Instead, generate the locale from glibc's own i18n sources
# with `localedef` — this uses whatever glibc is installed, no version matching.
printf '\e[1;32m-->\e[0m\e[1m Setting system locale to en_US.UTF-8\e[0m\n'
if ! locale -a 2>/dev/null | grep -qiE '^en_US\.(utf8|UTF-8)$'; then
	if command -v localedef >/dev/null 2>&1; then
		localedef -i en_US -f UTF-8 en_US.UTF-8 \
			|| echo "!! localedef failed to build en_US.UTF-8 (glibc-common i18n data missing?)"
	else
		echo "!! localedef not found (glibc-common missing); cannot generate en_US.UTF-8"
	fi
fi
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

# --- Plymouth boot splash + LUKS/LVM initramfs ---------------------------
# plymouth + a theme are installed via package.list, but in a bootc image two
# extra things are required for the splash to actually appear:
#   1. a default theme must be selected, and
#   2. the initramfs must be regenerated so the `plymouth` dracut module (and the
#      selected theme) are baked in — the distroless base ships an initramfs
#      without plymouth.
# We ALSO add the `crypt`/`lvm`/`dm` dracut modules here: on a bootc/ostree system
# the initramfs is baked into the IMAGE (not generated by Anaconda at install), so
# without these modules a LUKS-on-LVM root (see bib/config.toml autopart
# --encrypted) cannot be unlocked at boot. plymouth then renders the passphrase
# prompt. The `rhgb quiet` kargs go via a bootc kargs.d snippet below.
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
	printf '\e[1;32m-->\e[0m\e[1m Selecting Plymouth theme\e[0m\n'
	plymouth-set-default-theme bgrt 2>/dev/null \
		|| plymouth-set-default-theme spinner 2>/dev/null \
		|| echo "!! could not set a default plymouth theme"
fi

# Append rhgb/quiet via bootc kargs (consumed at deploy time, including by the
# bib installer which uses `bootc install`).
printf '\e[1;32m-->\e[0m\e[1m Writing Plymouth kernel arguments (rhgb quiet)\e[0m\n'
mkdir -p /usr/lib/bootc/kargs.d
cat > /usr/lib/bootc/kargs.d/10-plymouth.toml <<'EOF'
# Enable the graphical boot splash (Plymouth).
kargs = ["rhgb", "quiet"]
EOF

# Regenerate the initramfs(es) so the plymouth + crypt/lvm dracut modules are
# included. Build a generic (non-hostonly) initramfs in place at the ostree/bootc
# location (/usr/lib/modules/<kver>/initramfs.img). crypt/lvm/dm are required to
# unlock the LUKS-on-LVM root that the installer creates.
if command -v dracut >/dev/null 2>&1 && [[ -d /usr/lib/modules ]]; then
	for kver in $(ls /usr/lib/modules 2>/dev/null); do
		[[ -e /usr/lib/modules/$kver/vmlinuz ]] || continue
		printf '\e[1;32m-->\e[0m\e[1m Regenerating initramfs with Plymouth + LUKS (%s)\e[0m\n' "$kver"
		dracut --force --no-hostonly --no-hostonly-cmdline \
			--add "plymouth crypt lvm dm" \
			--kver "$kver" "/usr/lib/modules/$kver/initramfs.img" \
			|| echo "!! dracut failed to regenerate initramfs for $kver"
		# Verify the splash actually landed: a silent dracut that drops the
		# plymouth module (the original bug) leaves an initramfs that boots
		# without a splash. Fail loudly here instead of discovering it post-install.
		if lsinitrd "/usr/lib/modules/$kver/initramfs.img" 2>/dev/null | grep -q plymouth; then
			printf '    plymouth present in initramfs (%s)\n' "$kver"
		else
			echo "!! plymouth MISSING from regenerated initramfs ($kver) — boot splash / graphical LUKS prompt will NOT appear"
		fi
	done
else
	echo "!! dracut or /usr/lib/modules not available; skipping initramfs regen (plymouth splash may not appear)"
fi

printf '\e[1;32m-->\e[0m\e[1m post_install complete\e[0m\n'
