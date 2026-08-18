#!/usr/bin/env bash
#
# build-hyprland.sh — build the latest Hyprland release + the hy3 layout plugin
# (and the Hypr* stack they depend on) FROM GIT, into a DESTDIR staging tree.
#
# Runs inside the `hypr-builder` stage of the flavor Containerfile. Everything is
# installed twice: once into the builder's real /usr (so each component can find
# the headers/libs of the ones built before it) and once into /staging (which the
# final image COPYs in). The builder stage — toolchain, sources, -devel deps — is
# then thrown away, so none of that bloat reaches the shipped image.
#
# Scope: because we replace the system hyprutils/hyprlang/hyprcursor/... with git
# builds, anything that links them must be built from git too or it would ABI-
# break. So we build the whole first-party chain: the libs, Hyprland, hyprlock,
# hypridle, xdg-desktop-portal-hyprland, and hy3. Fedora's hypr* RPMs are removed
# from package.list. Third-party runtime libs (mesa, wayland, pipewire, sdbus-c++,
# ...) still come from Fedora and are pulled via `dnf builddep` below.
#
# ponytail: pinned to each repo's latest tag. Hyprland and hy3 must be ABI-matched
# — hy3's latest tag targets Hyprland's latest release, which is why both are
# taken at HEAD-of-tags together. If hy3 refuses to load after a Hyprland bump,
# pin HY3_REF to the hy3 tag matching the Hyprland version (see outfoxxed/hy3).
set -euo pipefail

STAGING=/staging
SRC=/usr/src/hypr
JOBS="$(nproc)"
mkdir -p "$STAGING" "$SRC"

# --- build dependencies --------------------------------------------------
# Explicit BuildRequires for the whole hypr stack. We deliberately do NOT use
# `dnf builddep` here: it needs the (often flaky / renamed on rawhide) *source*
# repos and aborts when any hypr* srpm name doesn't match. --skip-unavailable
# tolerates a rawhide package rename — a genuinely missing dep then surfaces as a
# clear compile error rather than a mysterious depsolve abort.
dnf -y install gcc gcc-c++ cmake make ninja-build meson pkgconf-pkg-config git jq
dnf -y install --skip-unavailable \
	wayland-devel wayland-protocols-devel libdrm-devel libinput-devel \
	libxkbcommon-devel pixman-devel cairo-devel pango-devel \
	mesa-libEGL-devel mesa-libGL-devel mesa-libgbm-devel libgbm-devel libglvnd-devel \
	systemd-devel libseat-devel libdisplay-info-devel libliftoff-devel hwdata-devel \
	tomlplusplus-devel pugixml-devel librsvg2-devel libzip-devel \
	zlib-devel zlib-ng-devel glslang-devel readline-devel lua-devel \
	qt6-qtbase-devel qt6-qtwayland-devel \
	libuuid-devel libXcursor-devel libeis-devel re2-devel muParser-devel lcms2-devel \
	libjpeg-turbo-devel libwebp-devel libspng-devel file-devel \
	sdbus-cpp-devel sdbus-c++-devel pipewire-devel pam-devel glaze-devel \
	iniparser-devel abseil-cpp-devel \
	libxcb-devel xcb-util-devel xcb-util-wm-devel xcb-util-errors-devel \
	xcb-util-renderutil-devel xcb-util-keysyms-devel xcb-util-cursor-devel \
	xorg-x11-server-Xwayland-devel

# --- helpers -------------------------------------------------------------
# Clone a repo and check out its most recent tag (the "latest release").
clone_latest() {
	url=$1 dir=$2
	git clone "$url" "$SRC/$dir"
	git -C "$SRC/$dir" checkout \
		"$(git -C "$SRC/$dir" describe --tags "$(git -C "$SRC/$dir" rev-list --tags --max-count=1)")"
	git -C "$SRC/$dir" submodule update --init --recursive
}

# CMake project: configure, build, install to real /usr and to the staging tree.
build_cmake() {
	dir=$1; shift
	cmake -S "$SRC/$dir" -B "$SRC/$dir/build" -G Ninja \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_INSTALL_LIBDIR=lib64 "$@"
	cmake --build "$SRC/$dir/build" -j"$JOBS"
	cmake --install "$SRC/$dir/build"
	DESTDIR="$STAGING" cmake --install "$SRC/$dir/build"
	ldconfig
}

# Meson project (hyprland-protocols).
build_meson() {
	dir=$1
	meson setup "$SRC/$dir/build" "$SRC/$dir" --prefix=/usr --libdir=lib64 --buildtype=release
	meson install -C "$SRC/$dir/build"
	DESTDIR="$STAGING" meson install -C "$SRC/$dir/build" --no-rebuild
}

gh() { echo "https://github.com/$1"; }

# --- Hypr* libraries (order matters: later ones link earlier ones) -------
clone_latest "$(gh hyprwm/hyprwayland-scanner)" hyprwayland-scanner; build_cmake hyprwayland-scanner
clone_latest "$(gh hyprwm/hyprutils)"           hyprutils;           build_cmake hyprutils
clone_latest "$(gh hyprwm/hyprlang)"            hyprlang;            build_cmake hyprlang
clone_latest "$(gh hyprwm/hyprcursor)"          hyprcursor;          build_cmake hyprcursor
clone_latest "$(gh hyprwm/hyprgraphics)"        hyprgraphics;        build_cmake hyprgraphics
clone_latest "$(gh hyprwm/hyprwire)"            hyprwire;            build_cmake hyprwire
clone_latest "$(gh hyprwm/aquamarine)"          aquamarine;          build_cmake aquamarine
clone_latest "$(gh hyprwm/hyprtoolkit)"         hyprtoolkit;         build_cmake hyprtoolkit
clone_latest "$(gh hyprwm/hyprland-protocols)"  hyprland-protocols;  build_meson hyprland-protocols

# --- Hyprland compositor -------------------------------------------------
clone_latest "$(gh hyprwm/Hyprland)" Hyprland
build_cmake Hyprland

# --- first-party apps used by .config/hypr/* (ABI-tied to the libs above) -
clone_latest "$(gh hyprwm/hyprlock)" hyprlock; build_cmake hyprlock
clone_latest "$(gh hyprwm/hypridle)" hypridle; build_cmake hypridle
clone_latest "$(gh hyprwm/xdg-desktop-portal-hyprland)" xdph; build_cmake xdph
# hyprland-dialog & co. Hyprland >=0.5x execs hyprland-dialog for its error/
# crash/update dialogs and logs "hyprland-guiutils not installed" without it.
clone_latest "$(gh hyprwm/hyprland-guiutils)" hyprland-guiutils; build_cmake hyprland-guiutils

# --- hy3 layout plugin ---------------------------------------------------
# Built against the just-installed Hyprland (found via pkg-config). It produces a
# single libhy3.so; the config loads it from /usr/lib (plugin = /usr/lib/libhy3.so).
clone_latest "$(gh outfoxxed/hy3)" hy3
cmake -S "$SRC/hy3" -B "$SRC/hy3/build" -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build "$SRC/hy3/build" -j"$JOBS"
install -Dm755 "$SRC/hy3/build/libhy3.so" /usr/lib/libhy3.so
install -Dm755 "$SRC/hy3/build/libhy3.so" "$STAGING/usr/lib/libhy3.so"

# --- hyprfocus plugin ----------------------------------------------------
# Flashfocus-style focus animation, from the OFFICIAL hyprwm/hyprland-plugins
# monorepo (kept in lockstep with Hyprland releases), not the pyt0xic fork —
# that fork stalled on the pre-0.56 plugin API (Debug::log, g_pConfigManager->
# getAnimationPropertyConfig, window->m_alpha) and no longer compiles.
# Built with its Makefile, NOT cmake: only the Makefile passes --no-gnu-unique,
# without which Hyprland refuses to dlopen the plugin.
# ponytail: tracks main (the repo tags nothing useful per-plugin), so a Hyprland
# bump that lands before the plugins repo catches up fails the build loudly —
# pin HYPRFOCUS_REF to a known-good commit, or HYPRFOCUS_OPTIONAL=1 to ship
# without the plugin (cosmetic; Hyprland just logs a config error and starts).
git clone "$(gh hyprwm/hyprland-plugins)" "$SRC/hyprland-plugins"
[[ -z ${HYPRFOCUS_REF:-} ]] || git -C "$SRC/hyprland-plugins" checkout "$HYPRFOCUS_REF"
if make -C "$SRC/hyprland-plugins/hyprfocus" all 2>&1 | tee "$SRC/hyprfocus.log"; then
	install -Dm755 "$SRC/hyprland-plugins/hyprfocus/hyprfocus.so" /usr/lib/libhyprfocus.so
	install -Dm755 "$SRC/hyprland-plugins/hyprfocus/hyprfocus.so" "$STAGING/usr/lib/libhyprfocus.so"
else
	echo "!! hyprfocus FAILED to build against this Hyprland; last 40 lines:"
	tail -40 "$SRC/hyprfocus.log"
	[[ ${HYPRFOCUS_OPTIONAL:-0} == 1 ]] || {
		echo "!! pin HYPRFOCUS_REF to a known-good hyprland-plugins commit, or rebuild with HYPRFOCUS_OPTIONAL=1"
		exit 1
	}
fi

echo "==> hypr stack built:"
"$STAGING/usr/bin/Hyprland" --version || true
