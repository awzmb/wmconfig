#!/bin/bash

# ---------------------------------------------------------------------------
# Entra ID / himmelblau configuration
#
# HIMMELBLAU_DOMAIN    – your Entra ID domain, e.g. contoso.com  (required)
# HIMMELBLAU_TENANT_ID – Entra ID tenant GUID                     (optional)
# HIMMELBLAU_USER      – your Entra ID UPN, e.g. user@contoso.com (required)
#                        Written to /etc/himmelblau/user-map, which tells
#                        himmelblaud to exempt the local user's UID from the
#                        nxset.  Without this, authentication succeeds in the
#                        broker but PAM_USER_UNKNOWN is returned because the
#                        assigned gidnumber (= HOST_UID) is otherwise blocked.
#
# Set these as environment variables before running start.sh, or leave them
# unset and you will be prompted interactively.
# ---------------------------------------------------------------------------

if [ -z "$HOME" ]; then
    echo "ERROR: \$HOME is not set. Cannot determine config/data directories." >&2
    exit 1
fi

if [ -z "$HIMMELBLAU_DOMAIN" ]; then
    read -rp "Entra ID domain (e.g. contoso.com): " HIMMELBLAU_DOMAIN
fi

if [ -z "$HIMMELBLAU_DOMAIN" ]; then
    echo "ERROR: HIMMELBLAU_DOMAIN is required." >&2
    exit 1
fi

# Basic sanity-check: domain must contain only DNS-safe characters
# (letters, digits, hyphens, dots). This prevents config-file injection
# and catches obvious typos early.
if ! printf '%s' "$HIMMELBLAU_DOMAIN" | grep -qE '^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$'; then
    echo "ERROR: HIMMELBLAU_DOMAIN '${HIMMELBLAU_DOMAIN}' does not look like a valid domain name." >&2
    exit 1
fi

if [ -z "$HIMMELBLAU_USER" ]; then
    read -rp "Entra ID user UPN (e.g. user@${HIMMELBLAU_DOMAIN}): " HIMMELBLAU_USER
fi

if [ -z "$HIMMELBLAU_USER" ]; then
    echo "ERROR: HIMMELBLAU_USER is required." >&2
    echo "  It is used to create the himmelblau user-map (/etc/himmelblau/user-map)," >&2
    echo "  which exempts the local user's UID from the broker's nxset so that" >&2
    echo "  linux-entra-sso can find your Entra ID account after enrollment." >&2
    exit 1
fi

# Validate UPN format: localpart@domain
if ! printf '%s' "$HIMMELBLAU_USER" | grep -qE '^[^@[:space:]]+@[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$'; then
    echo "ERROR: HIMMELBLAU_USER '${HIMMELBLAU_USER}' does not look like a valid UPN (user@domain)." >&2
    exit 1
fi

# Write himmelblau.conf to a host-side config directory so the value survives
# container restarts and is not baked into the image.
HIMMELBLAU_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/himmelblau"
mkdir -p "$HIMMELBLAU_CONFIG_DIR"
HOST_USERNAME=$(whoami)
HOST_UID=$(id -u)
{
    printf '[global]\n'
    printf 'domain = %s\n' "$HIMMELBLAU_DOMAIN"
    if [ -n "$HIMMELBLAU_TENANT_ID" ]; then
        printf 'tenant_id = %s\n' "$HIMMELBLAU_TENANT_ID"
    fi
    # Map the Entra ID user to the container user's UID so that
    # linux-entra-sso (which runs as the container user) can find the
    # account in the broker.  The broker's get_accounts looks up the
    # requesting process's UID in the token cache; setting idmap_range to
    # exactly the host UID ensures a match.
    printf 'idmap_range = %s-%s\n' "$HOST_UID" "$HOST_UID"
    # Required for Intune MDM enrollment and compliance reporting.
    # Without this himmelblaud silently skips dispatching the ApplyPolicy
    # task to himmelblaud_tasks — the daemon connects and waits, but no
    # enrollment work is ever sent.  Browsers would keep showing
    # "To enroll your device" even with himmelblaud_tasks running as root.
    printf 'apply_policy = true\n'
} > "$HIMMELBLAU_CONFIG_DIR/himmelblau.conf"

# Write the user-map file.  This is the mechanism himmelblaud uses to exempt
# a local user's UID from the nxset (the set of UIDs reserved for local users).
# Without this mapping, after a successful broker authentication the daemon
# checks whether the returned token's gidnumber is in the nxset; with
# idmap_range = HOST_UID-HOST_UID, gidnumber == HOST_UID which IS a local
# UID — so the daemon refuses to release the token and returns PAM_USER_UNKNOWN.
# The user-map (local_username:entra_upn) is read by the daemon at startup;
# any local name listed there (and its UID) is skipped when building the nxset.
# Note: allow_id_overrides in himmelblau.conf is NOT a valid config field and
# has no effect — the user-map is the only way to control this.
# Entra ID UPNs are case-insensitive; normalise to lowercase so the user-map
# lookup in the daemon (which lowercases UPNs internally) always finds a match.
HIMMELBLAU_USER_LOWER="$(printf '%s' "$HIMMELBLAU_USER" | tr '[:upper:]' '[:lower:]')"
printf '%s:%s\n' "$HOST_USERNAME" "$HIMMELBLAU_USER_LOWER" \
    > "$HIMMELBLAU_CONFIG_DIR/user-map"

# Persistent data is stored in named Podman volumes so it survives container
# restarts without scattering files across the host filesystem.
# himmelblau-data : enrolled account identity database (/var/lib/himmelblaud)
# himmelblau-cache: HSM PIN and cryptographic key material (/var/cache/himmelblaud)
#                   Without this the HSM PIN is regenerated on every start and
#                   enrolled accounts become cryptographically inaccessible.
podman volume create himmelblau-data 2>/dev/null || true
podman volume create himmelblau-cache 2>/dev/null || true

podman buildx build \
  --build-arg "USERNAME=$(whoami)" \
  --build-arg "USER_ID=$(id -u)" \
  --build-arg "GROUP_ID=$(id -g)" \
  --tag localhost/himmelblau \
  .

# ---------------------------------------------------------------------------
# Native-messaging host setup
#
# The linux-entra-sso browser extension (available from the Chrome Web Store:
# https://chrome.google.com/webstore/detail/jlnfnnolkbjieggibinobhkjdfbpcohn)
# communicates with a local helper binary via Chrome's native-messaging
# protocol.  We install a thin wrapper script on the HOST that forwards
# stdin/stdout into the running container, so both native browser installs
# and Flatpak-sandboxed browsers (which cannot reach inside the container
# directly) can reach the broker.
# ---------------------------------------------------------------------------

CONTAINER_NAME="himmelblau-broker"
NM_BRIDGE="${XDG_BIN_HOME:-$HOME/.local/bin}/linux-entra-sso-host-bridge"
# Chrome Web Store extension ID for the Linux Entra SSO extension by Siemens.
# Source: https://chrome.google.com/webstore/detail/jlnfnnolkbjieggibinobhkjdfbpcohn
CHROME_EXT_ID="jlnfnnolkbjieggibinobhkjdfbpcohn"

# Create the bridge script that proxies native-messaging traffic into the
# running container.  The script is idempotent – re-running start.sh
# overwrites it with the correct container name each time.
mkdir -p "$(dirname "$NM_BRIDGE")"
cat > "$NM_BRIDGE" <<BRIDGE_SCRIPT
#!/bin/bash
# Auto-generated by start.sh – do not edit manually.
# Forwards native-messaging stdin/stdout to linux-entra-sso inside the
# himmelblau container.
if ! podman container exists "$CONTAINER_NAME" 2>/dev/null; then
    echo '{"error":"himmelblau-broker container is not running – start it with: bash start.sh"}' >&2
    exit 1
fi
exec podman exec -i "$CONTAINER_NAME" linux-entra-sso "\$@"
BRIDGE_SCRIPT
chmod +x "$NM_BRIDGE"

# Build the manifest content once.
# The name "linux_entra_sso" must match what the browser extension expects
# (see https://github.com/siemens/linux-entra-sso).
NM_MANIFEST=$(printf '{
    "name": "linux_entra_sso",
    "description": "Entra ID SSO via Microsoft Identity Broker",
    "path": "%s",
    "type": "stdio",
    "allowed_origins": [
        "chrome-extension://%s/"
    ]
}' "$NM_BRIDGE" "$CHROME_EXT_ID")

# Install the manifest for every supported browser variant.
# Directories that do not correspond to an installed browser are created
# harmlessly; browsers only read manifests from these paths when they exist.
NM_DIRS=(
    # Native (non-Flatpak) browser installs
    "$HOME/.config/google-chrome/NativeMessagingHosts"
    "$HOME/.config/chromium/NativeMessagingHosts"
    "$HOME/.config/microsoft-edge/NativeMessagingHosts"
    "$HOME/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts"
    # Flatpak browser installs
    # Chrome: socket=session-bus + native-messaging lets host binaries run
    "$HOME/.var/app/com.google.Chrome/config/google-chrome/NativeMessagingHosts"
    # Chromium Flatpak
    "$HOME/.var/app/org.chromium.Chromium/config/chromium/NativeMessagingHosts"
    # Edge Flatpak
    "$HOME/.var/app/com.microsoft.Edge/config/microsoft-edge/NativeMessagingHosts"
)
for nm_dir in "${NM_DIRS[@]}"; do
    mkdir -p "$nm_dir"
    printf '%s\n' "$NM_MANIFEST" > "$nm_dir/linux_entra_sso.json"
done
echo "Native-messaging host manifests installed."
echo "Install the browser extension from the Chrome Web Store:"
echo "  https://chrome.google.com/webstore/detail/${CHROME_EXT_ID}"

# ---------------------------------------------------------------------------
# Start the container
# ---------------------------------------------------------------------------

# Remove any leftover stopped container with this name from a previous run so
# that `podman run --name` does not fail.  Persistent state lives in the named
# Podman volumes (himmelblau-data, himmelblau-cache) and the host-side config
# directory – nothing is stored inside the container itself.
podman rm -f "$CONTAINER_NAME" 2>/dev/null || true

# Resolve the hostname to pass into the container so that Intune device
# enrollment sees the same device name as the host.  Try $HOSTNAME first
# (always available in bash without a subprocess), then fall back to the
# `hostname` command, and finally read /etc/hostname if both are empty.
CONTAINER_HOSTNAME="${HOSTNAME:-$(hostname 2>/dev/null)}"
if [ -z "$CONTAINER_HOSTNAME" ] && [ -r /etc/hostname ]; then
    CONTAINER_HOSTNAME="$(head -n1 /etc/hostname | tr -d '[:space:]')"
fi

podman run -it --rm \
  --name "$CONTAINER_NAME" \
  --hostname "${CONTAINER_HOSTNAME}" \
  --user $(id -u):$(id -g) \
  --userns=keep-id \
  --privileged \
  -e DISPLAY=$DISPLAY \
  -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
  -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR \
  -v $XDG_RUNTIME_DIR:$XDG_RUNTIME_DIR \
  -e DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS}" \
  -e HIMMELBLAU_USER="${HIMMELBLAU_USER}" \
  -v himmelblau-data:/var/lib/himmelblaud \
  -v himmelblau-cache:/var/cache/himmelblaud \
  -v "$HIMMELBLAU_CONFIG_DIR":/etc/himmelblau:Z \
  --mount "type=bind,$(printf "%s" "${DBUS_SESSION_BUS_ADDRESS}" | sed -e 's/unix:path=\(.\+\)/src=\1,dst=\1/')" \
  --security-opt label=disable \
  localhost/himmelblau
