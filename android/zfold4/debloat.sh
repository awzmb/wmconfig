#!/bin/sh
# Uninstall listed packages for user 0. Dry run by default; pass --apply to commit.
#
# Runs inside the android-tools container:
#   android ./debloat.sh            # dry run
#   android ./debloat.sh --apply
# (the wrapper bind-mounts this directory at /workspace and cd's there)
set -eu

apply=0
[ "${1-}" = "--apply" ] && { apply=1; shift; }
list=${1-$(dirname -- "$0")/packages.txt}
[ -r "$list" ] || { echo "no package list at $list" >&2; exit 1; }

# Fresh container = fresh adb server every run. Start it explicitly so its
# banner does not land in the middle of the first command's output.
adb start-server >/dev/null 2>&1 || true

state=$(adb devices | tr -d '\r' | awk 'NR>1 && NF {print $2; exit}')
case "${state:-none}" in
	device) ;;
	unauthorized)
		echo "device unauthorized - confirm the RSA prompt on the phone." >&2
		echo "No prompt? Developer options -> Revoke USB debugging authorizations, replug." >&2
		exit 1 ;;
	none)
		echo "no device. Check the cable, and that USB debugging is on." >&2
		echo "Seeing this only inside the container? The udev rule is missing on the HOST." >&2
		exit 1 ;;
	*)
		echo "device not ready (state: $state)" >&2
		exit 1 ;;
esac

installed=$(mktemp)
trap 'rm -f "$installed"' EXIT
adb shell pm list packages --user 0 | tr -d '\r' | sed 's/^package://' | sort -u > "$installed"

sed 's/#.*//' "$list" | tr -d '\r' | awk 'NF' | sort -u |
while read -r pkg; do
	grep -qxF "$pkg" "$installed" || continue
	if [ "$apply" = 1 ]; then
		printf '%-55s %s\n' "$pkg" "$(adb shell pm uninstall --user 0 "$pkg" </dev/null | tr -d '\r')"
	else
		echo "would remove: $pkg"
	fi
done
