#!/usr/bin/env bash
#
# configure.sh — system configuration, run by the Containerfile after packages
# and the rootfs overlay are in place: services, timezone, locale, package
# removals, dconf, default session, plymouth + initramfs. Fedora analogue of
# awzmlinux/extensions/post_install.sh.
#
# Runs as root inside the image build. $variant points at the variant config.
set -euo pipefail

variant=${HB:-/run/fedora/variant}

# --- Timezone -------------------------------------------------------------
# arkdep shipped /etc/localtime -> /usr/share/zoneinfo/UTC
printf '\e[1;32m-->\e[0m\e[1m Setting timezone to UTC\e[0m\n'
ln -sf ../usr/share/zoneinfo/UTC /etc/localtime

# --- Groups required by services -----------------------------------------
# seatd.service runs `seatd -g seat`
getent group seat >/dev/null 2>&1 || groupadd -r seat || true

# --- Login user (build-time) ---------------------------------------------
# Create the `fedora` user in the IMAGE rather than via the installer kickstart:
# Anaconda's kickstart `user` password did not produce a working login on this
# ostree/bootc target (console login failed "Login incorrect"), whereas baking the
# account into the image's /etc/passwd+/etc/shadow works under any install path.
# ponytail: password is literal "fedora" and MUST match the LUKS passphrase in
# flavors/base/bib/config.toml — change both together.
# ponytail: `useradd -m` seeds /var/home/fedora (/home -> var/home) which bootc
# carries into the target's /var; if home is ever missing on first boot, add
# oddjob-mkhomedir/pam_mkhomedir instead.
printf '\e[1;32m-->\e[0m\e[1m Creating login user "fedora"\e[0m\n'
mkdir -p /var/home
if ! getent passwd fedora >/dev/null 2>&1; then
	# ponytail: UID 1001, not the default 1000 — tacklebox's live baseline.sh
	# runs `useradd` for its own UID-1000 live user against this image and dies
	# "UID 1000 is not unique" if we already own 1000. Bump if tacklebox ever
	# moves its live user off 1000.
	useradd -u 1001 -m -G wheel fedora
fi
for g in video audio input render seat realtime libvirt kvm; do
	getent group "$g" >/dev/null 2>&1 && usermod -aG "$g" fedora || true
done
echo 'fedora:fedora' | chpasswd
# %wheel sudo comes from the stock Fedora /etc/sudoers rule — nothing to add.

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
enable_unit power-profiles-daemon.service
enable_unit switcheroo-control.service
enable_unit bluetooth.service
enable_unit podman.socket sockets.target
enable_unit fedora-flatpak.service
enable_unit opensnitchd.service
enable_unit tailscaled.service

# --- Keyboard remap hwdb -------------------------------------------------
# overlay ships /usr/lib/udev/hwdb.d/90-keyboard-remap.hwdb (capslock->esc).
# Compile it into the binary hwdb.bin now so the remap is baked into the
# immutable image; udev applies it on every device add at boot (no service).
if command -v systemd-hwdb >/dev/null 2>&1; then
	printf '\e[1;32m-->\e[0m\e[1m Compiling udev hwdb (keyboard remap)\e[0m\n'
	systemd-hwdb update 2>/dev/null || echo "!! systemd-hwdb update failed; keyboard remap may not apply"
else
	echo "!! systemd-hwdb not found; keyboard remap (hwdb) will not be compiled"
fi

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

# --- Local VT login (getty on tty1) --------------------------------------
# The container-derived fedora-bootc base does NOT statically enable
# getty@tty1.service (containers have no VTs), so on bare metal only the
# serial-getty (auto-generated by systemd-getty-generator from console=ttyS0)
# ever spawns — the physical monitor is left with no login prompt. Enable the
# tty1 instance the same static way systemd itself does: a wants-symlink NAMED
# for the instance, pointing at the getty@.service TEMPLATE (enable_unit can't
# do this — it looks for a getty@tty1.service file that doesn't exist).
# ponytail: tty1 only; logind autospawns getty on tty2-6 via NAutoVTs on VT switch.
if [[ -e /usr/lib/systemd/system/getty@.service ]]; then
	printf '\e[1;32m-->\e[0m\e[1m Enabling getty on tty1 (local VT login)\e[0m\n'
	mkdir -p /usr/lib/systemd/system/getty.target.wants
	ln -sfn ../getty@.service /usr/lib/systemd/system/getty.target.wants/getty@tty1.service
else
	echo "!! getty@.service template not found; local VT login will NOT work"
fi

# --- Enable per-user services globally -----------------------------------
# Mirrors `systemctl --user enable --now podman.socket` from arkane/post-install.sh
enable_user_unit podman.socket sockets.target

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
	"systemd-cryptsetup:/usr/lib/systemd/systemd-cryptsetup" \
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
# glibc-langpack-en (package.list) installs the en_US.UTF-8 locale on the
# standard Fedora base. As a fallback (e.g. if the langpack was dropped by
# --skip-broken), generate it from glibc's i18n sources with `localedef`
# (glibc-locale-source, also in package.list). Setting a UTF-8 locale avoids the
# `cannot change locale (en_US.UTF-8)` warnings that break tools like fc-cache.
printf '\e[1;32m-->\e[0m\e[1m Setting system locale to en_US.UTF-8\e[0m\n'
if ! locale -a 2>/dev/null | grep -qiE '^en_US\.(utf8|UTF-8)$'; then
	echo "!! en_US.UTF-8 not present (glibc-langpack-en missing?); generating with localedef"
	if command -v localedef >/dev/null 2>&1; then
		localedef -i en_US -f UTF-8 en_US.UTF-8 \
			|| echo "!! localedef failed to build en_US.UTF-8 (glibc-locale-source missing?)"
	else
		echo "!! localedef not found (glibc-common missing); cannot generate en_US.UTF-8"
	fi
fi
printf 'LANG=en_US.UTF-8\n' > /etc/locale.conf

# --- zsh completion (compinit/compdef) system-wide ------------------------
# Fedora's /etc/zshrc (zshrc.rhs) does NOT source /etc/zshrc.d/*.zsh — it only
# sets prompt/pathmunge — so our overlay drop-in (etc/zshrc.d/00-fedora-compinit.zsh)
# is never read and compinit/compdef stay undefined for every interactive zsh
# except skel-seeded ~/.zshrc. Append an idempotent source loop to /etc/zshrc so
# the drop-in dir is honoured for all users (root included) and any /etc plugin.
if [[ -f /etc/zshrc ]] && ! grep -q '/etc/zshrc.d/\*\.zsh' /etc/zshrc; then
	printf '\e[1;32m-->\e[0m\e[1m Wiring /etc/zshrc.d into /etc/zshrc (compinit)\e[0m\n'
	cat >> /etc/zshrc <<'EOF'

# Source system drop-ins (added by fedora-build; Fedora's stock zshrc does not).
for _f in /etc/zshrc.d/*.zsh(N); do source "$_f"; done
unset _f
EOF
else
	[[ -f /etc/zshrc ]] || echo "!! /etc/zshrc missing (zsh not installed?); compinit drop-in not wired"
fi

# --- Terminess Nerd Font -------------------------------------------------
# "Terminess Nerd Font" is the Nerd Fonts patched Terminus. It is not packaged
# in Fedora, so fetch the official release tarball and install the faces into
# the immutable /usr font tree. Pinned for reproducibility; override with
# FEDORA_NERD_FONTS_VERSION.
nerd_fonts_version=${FEDORA_NERD_FONTS_VERSION:-v3.4.0}
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
	# Flatpaks only reliably see host fonts via /usr/local/share/fonts (bound to
	# /run/host/local-fonts); the /usr/share/fonts -> /run/host/fonts mapping is
	# flaky on ostree. Mirror the faces there so flatpak apps get Terminess too.
	# ponytail: cp, not symlink — a symlink into /usr/share/fonts would dangle
	# inside the sandbox where that path is the runtime's own tree. If /usr/local
	# is the ostree /var/usrlocal symlink, this rides bootc's first-install /var
	# seed; re-run configure (fedora-update won't re-seed /var) if it goes missing.
	flatpak_fonts=/usr/local/share/fonts/terminess-nerd-font
	mkdir -p "$flatpak_fonts"
	cp -a "$terminess_dir"/. "$flatpak_fonts"/ 2>/dev/null || true
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

# --- Plymouth boot splash (userspace) + LUKS/LVM initramfs ---------------
# Plymouth is installed via package.list and shows its splash in USERSPACE (after
# the LUKS root is unlocked and we've pivoted). It is deliberately NOT baked into
# the initramfs: the plymouth dracut module drags in `drm` + all GPU KMS drivers,
# which makes i915 probe before its firmware is available and wedges the GPU (see
# the long note in etc/dracut.conf.d/fedora.conf). So the initramfs carries only
# ostree + crypt/lvm/dm (declared in that overlay config), and the LUKS passphrase
# prompt is text-mode; the graphical splash appears later in userspace.
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
	printf '\e[1;32m-->\e[0m\e[1m Selecting Plymouth theme\e[0m\n'
	plymouth-set-default-theme bgrt 2>/dev/null \
		|| plymouth-set-default-theme spinner 2>/dev/null \
		|| echo "!! could not set a default plymouth theme"
fi

# Append boot kargs via bootc kargs.d (consumed at deploy time by `bootc install`,
# run from live/install.sh, and by day-2 bootc updates).
#   rhgb quiet                     — drive the userspace Plymouth splash.
#   rd.luks.options=x-initrd.attach — global option marking the LUKS root device
#       x-initrd.attach so systemd-cryptsetup-generator emits its unlock unit INTO
#       the initrd (and wires cryptsetup.target.requires/) instead of the real-root
#       systemd. The device itself is named at install time: live/install.sh appends
#       `rd.luks.name=<LUKS-header-UUID>=root` to the BLS options line (mapping the
#       container to /dev/mapper/root). Without the attach option the root can't be
#       unlocked during early boot. (The first-boot hang we chased was NOT this or
#       the unit escaping — it was the `nvme` driver failing to autoload so the disk
#       never appeared; see force_drivers in overlay/etc/dracut.conf.d/fedora.conf.)
printf '\e[1;32m-->\e[0m\e[1m Writing kernel arguments (rhgb quiet, LUKS initrd-attach)\e[0m\n'
mkdir -p /usr/lib/bootc/kargs.d
cat > /usr/lib/bootc/kargs.d/10-plymouth.toml <<'EOF'
# Enable the graphical boot splash (Plymouth).
kargs = ["rhgb", "quiet"]
EOF
cat > /usr/lib/bootc/kargs.d/15-luks.toml <<'EOF'
# Global LUKS option: mark the root device x-initrd.attach so systemd-cryptsetup-
# generator emits the unlock unit into the initrd (wiring cryptsetup.target.requires/).
# The device is named at install time by live/install.sh, which appends
# rd.luks.name=<LUKS-header-UUID>=root to the BLS options line. Required for
# early-boot unlock. The disk-not-appearing hang was fixed by force-loading nvme
# (overlay/etc/dracut.conf.d/fedora.conf), not by this karg.
kargs = ["rd.luks.options=x-initrd.attach"]
EOF

# ponytail: Patch dracut's 70crypt so its generated udev rule uses the CORRECT
# systemd escaping. In DRACUT_SYSTEMD mode parse-crypt.sh writes a udev rule that
# does `systemctl start systemd-cryptsetup@<name>.service`, but it first DOUBLES the
# backslash in the escaped instance name (`luks\x2d…` -> `luks\\x2d…`) to survive a
# layer of udev unescaping. Rawhide's udev no longer unescapes RUN= strings, so the
# doubled name reaches systemctl verbatim, matches no unit, and normal boot loops on
# `Failed to start systemd-cryptsetup@luks\\x2d….service`. (The single-escaped unit
# the systemd generator writes into cryptsetup.target.requires/ is the one that
# unlocks manually.) Drop the doubling so the udev-rule path targets that same
# correctly-escaped unit. Ceiling: revert once rawhide udev restores RUN= unescaping
# or dracut stops doubling. See flavors/base/overlay/etc/dracut.conf.d/fedora.conf.
# ponytail: module dir moved 70crypt -> 90crypt upstream at some point; glob
# instead of hardcoding the number so a future rename doesn't silently no-op this.
patched_any=0
while IFS= read -r -d '' parse_crypt; do
	if grep -q 'str_replace "$luksname"' "$parse_crypt"; then
		sed -i '/luksname="$(str_replace "$luksname"/d' "$parse_crypt"
		if grep -q 'str_replace "$luksname"' "$parse_crypt"; then
			echo "!! failed to patch dracut backslash-doubling in $parse_crypt — LUKS may loop on first boot"
		else
			printf '\e[1;32m-->\e[0m\e[1m Patched dracut crypt module: single-escape systemd-cryptsetup unit name (%s)\e[0m\n' "$parse_crypt"
			patched_any=1
		fi
	fi
done < <(find /usr/lib/dracut/modules.d -maxdepth 2 -name parse-crypt.sh -print0 2>/dev/null)
[[ $patched_any -eq 1 ]] || echo "!! no dracut parse-crypt.sh with backslash-doubling found — verify LUKS escaping"

# Regenerate the initramfs(es). We pass the module/driver/omit set EXPLICITLY on the
# dracut command line (not only via etc/dracut.conf.d/fedora.conf) so it always
# applies regardless of whether a base-image dracut.conf.d snippet or config-read
# quirk would otherwise swallow our `+=` additions:
#   --add          ostree (mount composefs/ostree root) + crypt/systemd-cryptsetup/
#                  lvm/dm (unlock the LUKS-on-LVM root)
#   --add-drivers  xfs/ext4 (root fs) + erofs/overlay (composefs) — a generic
#                  initramfs has no disk to probe, so these must be forced in
#   --force-drivers nvme — force-LOAD the NVMe driver at initramfs start; generic
#                  initramfs autoload does not fire for it on this rawhide, so the
#                  root disk never appears and LUKS never prompts (see fedora.conf)
#   --omit         drm/plymouth — keep GPU KMS drivers out of the initramfs so i915
#                  doesn't probe before its firmware and wedge the GPU (blank screen)
# Build a generic (non-hostonly) initramfs in place at the ostree/bootc location
# (/usr/lib/modules/<kver>/initramfs.img). DRACUT_NO_XATTR avoids xattr failures on
# the container's overlay filesystem; --reproducible + chmod 0600 match how every
# bootc image project ships the initramfs (deterministic bytes, root-only).
if command -v dracut >/dev/null 2>&1 && [[ -d /usr/lib/modules ]]; then
	export DRACUT_NO_XATTR=1
	for kver in $(ls /usr/lib/modules 2>/dev/null); do
		[[ -e /usr/lib/modules/$kver/vmlinuz ]] || continue
		img="/usr/lib/modules/$kver/initramfs.img"
		printf '\e[1;32m-->\e[0m\e[1m Regenerating initramfs: ostree + LUKS, no GPU drivers (%s)\e[0m\n' "$kver"
		dracut --force --reproducible --no-hostonly --no-hostonly-cmdline \
			--add "ostree crypt systemd-cryptsetup lvm dm" \
			--add-drivers "xfs ext4 erofs overlay" \
			--force-drivers "nvme" \
			--omit "drm plymouth" \
			--kver "$kver" "$img" \
			|| echo "!! dracut failed to regenerate initramfs for $kver"
		chmod 0600 "$img" 2>/dev/null || true
		# Verify the result. Read the initramfs ONCE; if lsinitrd can't read it
		# (tooling gap in the build container), say so rather than emitting bogus
		# "MISSING" for every check.
		listing=$(lsinitrd "$img" 2>/dev/null) || true
		modules=$(lsinitrd -m "$img" 2>/dev/null) || true
		if [[ -z $listing ]]; then
			echo "!! could not read $img with lsinitrd — skipping content verification (initramfs may still be fine; verify by booting)"
		else
			# ostree is mandatory: without it the composefs/ostree root can't mount.
			grep -qw ostree <<<"$modules" \
				&& printf '    ostree present (%s)\n' "$kver" \
				|| echo "!! ostree MISSING from initramfs ($kver) — system will NOT boot (cannot mount the ostree root)"
			# systemd-cryptsetup unlocks the LUKS root. Check the dracut MODULE (its
			# generator writes the @luks-<uuid> unit at boot — there is no static
			# systemd-cryptsetup@.service file in modern systemd). Its absence is the
			# "systemd-cryptsetup@luks-<uuid>.service not found" first-boot failure.
			grep -qw systemd-cryptsetup <<<"$modules" \
				&& printf '    systemd-cryptsetup module present (%s)\n' "$kver" \
				|| echo "!! systemd-cryptsetup MISSING from initramfs ($kver) — encrypted root will NOT unlock (install the systemd-cryptsetup rpm)"
			# The NVMe driver must be force-LOADED, not just present: force_drivers
			# writes /usr/lib/dracut/modules.d/00warpclock-style conf that modprobes
			# it at start. Verify the module is in the initramfs (its autoload is what
			# was failing, so presence + force_drivers together fix the disk-not-found
			# hang that blocked LUKS unlock).
			grep -qE '/nvme\.ko' <<<"$listing" \
				&& printf '    nvme driver present (%s)\n' "$kver" \
				|| echo "!! nvme driver MISSING from initramfs ($kver) — root disk will NOT appear, LUKS will never prompt (add nvme to add_drivers/force_drivers)"
			# composefs root = erofs image + overlayfs; both are mandatory.
			grep -qE '/(erofs|overlay)\.ko' <<<"$listing" \
				&& printf '    composefs modules (erofs/overlay) present (%s)\n' "$kver" \
				|| echo "!! erofs/overlay MISSING from initramfs ($kver) — the composefs root will NOT mount"
			# No GPU KMS driver may leak in (that reintroduces the GuC black-screen).
			grep -qE '/(i915|xe|amdgpu)\.ko' <<<"$listing" \
				&& echo "!! GPU driver LEAKED into initramfs ($kver) — check drm/plymouth are omitted" \
				|| printf '    no GPU KMS driver in initramfs (%s) — good\n' "$kver"
		fi
	done
else
	echo "!! dracut or /usr/lib/modules not available; skipping initramfs regen (system may not boot)"
fi

printf '\e[1;32m-->\e[0m\e[1m base configure complete\e[0m\n'
