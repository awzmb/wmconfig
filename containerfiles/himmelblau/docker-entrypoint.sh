#!/bin/bash

# Default to running himmelblaud if no other command is specified
if [ $# -eq 0 ]; then
    set -- himmelblaud
fi

# Ensure the socket directory exists. In containers /var/run is typically a
# tmpfs remounted at startup, which removes directories baked into the image.
mkdir -p /var/run/himmelblaud

# /run/intune may also be lost on tmpfs remount; recreate it for the same reason.
mkdir -p /run/intune

# Print the enrollment instructions banner and drop to a bash shell.
# Called when no Entra ID account has been enrolled yet (first run or before
# the user has run aad-tool auth-test).
_show_enrollment_banner() {
    local _entra_user="${HIMMELBLAU_USER:-user@yourdomain.com}"
    cat >&2 <<'BANNER_TOP'

┌──────────────────────────────────────────────────────────────────────────┐
│  Entra ID account not yet enrolled                                       │
│                                                                          │
│  Populate the account cache so himmelblaud can find your identity:       │
│                                                                          │
BANNER_TOP
    printf '│    aad-tool auth-test --name %s\n' "$_entra_user" >&2
    cat >&2 <<'BANNER_BOTTOM'
│                                                                          │
│  You will be prompted for your Entra ID / Microsoft 365 password or      │
│  Hello PIN. If your account requires MFA, an additional step follows.    │
│                                                                          │
│  Note: the first run may show a "socket timeout" / PAM_ABORT after the   │
│  PIN prompt - this is expected in a rootless container (the PIN setup    │
│  daemon requires root). Auth still completes in the background; you will │
│  see "Authentication successful" in the log output shortly after.        │
│  If PAM_ABORT appears, run the command once more - the second run will   │
│  succeed immediately using the cached token.                             │
│                                                                          │
│  After enrolling, run aad-tool auth-test ONCE MORE to trigger Intune     │
│  device enrollment (himmelblaud_tasks processes the ApplyPolicy task     │
│  during authentication — it will not run on a cold-start alone).         │
│                                                                          │
│  Once enrolled, run the SSO client:                                      │
│                                                                          │
│    linux-entra-sso --interactive                                         │
│                                                                          │
│  Daemon logs (himmelblaud, broker, himmelblaud_tasks):                   │
│    tail -f /tmp/himmelblau.log                                           │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘

Type a command below:
BANNER_BOTTOM
}

# Check if a Wayland or X11 display is available.
# This requires the container to be run with appropriate environment variables and volume mounts.
if [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]; then
    # If the default command is himmelblaud and a display is available,
    # start the required background services and switch to the GUI application.
    if [ "$1" = "himmelblaud" ]; then
        BROKER_SOCK=/var/run/himmelblaud/broker_sock
        # Daemon logs go to a file so they don't interleave with and corrupt
        # the enrollment banner that is printed to the terminal later.
        # Logs can be followed with: tail -f /tmp/himmelblau.log
        DAEMON_LOG=/tmp/himmelblau.log

        if ! pgrep -x himmelblaud > /dev/null 2>&1; then
            # himmelblaud is not yet running in this container session.

            # Remove any stale socket from a previous container run so the
            # socket-presence check below is a reliable fresh-start signal.
            rm -f "$BROKER_SOCK"

            # Step 1: start himmelblaud and wait for it to bind its broker
            # socket before starting anything that depends on it.  Running all
            # three daemons simultaneously caused broker to loop "Unable to
            # find himmelblaud, sleeping..." until himmelblaud caught up.
            himmelblaud >> "$DAEMON_LOG" 2>&1 &

            HIMMELBLAUD_READY=0
            for _ in $(seq 1 30); do
                if [ -S "$BROKER_SOCK" ]; then
                    HIMMELBLAUD_READY=1
                    break
                fi
                sleep 1
            done
            if [ "$HIMMELBLAUD_READY" -eq 0 ]; then
                echo "WARNING: himmelblaud broker socket did not appear after 30s; linux-entra-sso may fail" >&2
            fi

            # Step 2: start broker (needs himmelblaud socket) and
            # himmelblaud_tasks (needs root; granted via scoped NOPASSWD sudo).
            broker >> "$DAEMON_LOG" 2>&1 &
            # himmelblaud_tasks performs Intune device-enrollment and
            # compliance-reporting tasks that require UID 0.  Without it the
            # broker reports "device not enrolled" and browsers show
            # "To enroll your device" even after a successful login.
            # sudo strips environment variables, so pass RUST_LOG explicitly
            # so the caller can set e.g. RUST_LOG=debug for verbose output.
            sudo RUST_LOG="${RUST_LOG:-info}" himmelblaud_tasks >> "$DAEMON_LOG" 2>&1 &

            # Step 3: wait for broker to register its D-Bus service name.
            # Use `timeout 3` on each dbus-send call so we don't hang silently
            # if the D-Bus session bus is unavailable (e.g. no bus socket forwarded).
            echo "Waiting for broker D-Bus registration..." >&2
            BROKER_READY=0
            for _ in $(seq 1 30); do
                if timeout 3 dbus-send --session --dest=org.freedesktop.DBus \
                    --type=method_call --print-reply /org/freedesktop/DBus \
                    org.freedesktop.DBus.NameHasOwner \
                    string:"com.microsoft.identity.broker1" 2>/dev/null \
                    | grep -q "boolean true"; then
                    BROKER_READY=1
                    break
                fi
                sleep 1
            done
            if [ "$BROKER_READY" -eq 0 ]; then
                echo "WARNING: broker D-Bus service did not appear after 30s; linux-entra-sso may fail" >&2
            fi
        fi

        # Services are up (either just started or were already running).
        # Check whether at least one Entra ID account is enrolled by asking the
        # broker for its account list.  linux-entra-sso always exits 0 (even on
        # error), so we inspect stdout: a successful getAccounts response contains
        # a "username" field; an empty or error response does not.
        # NOTE: do NOT use --interactive here — that flag enables the
        # native-messaging bridge mode which reads stdin in a loop; piping its
        # output to grep would cause the process to hang waiting for more input.
        # Use `timeout 15` so a slow or unresponsive broker cannot stall startup.
        echo "Checking enrollment status..." >&2
        if timeout 15 linux-entra-sso getAccounts 2>/dev/null | grep -q '"username"'; then
            # Start linux-entra-sso in the background.  When run without a
            # sub-command it keeps running as a session-level SSO helper that
            # the browser extension's native-messaging bridge can call into.
            # (The D-Bus service name com.microsoft.identity.broker1 is owned
            # by the separate `broker` process started above.)
            if ! pgrep -f "linux-entra-sso --interactive" > /dev/null 2>&1; then
                linux-entra-sso --interactive >> "$DAEMON_LOG" 2>&1 &
            fi
            # Reset cursor to column 0 and erase the current line before drawing
            # the banner so that any stray cursor movement from background output
            # cannot push the box characters to a non-zero column.
            printf '\r\033[2K'
            cat <<'SSO_READY'
✓ Entra ID account enrolled. SSO broker services are ready.

  The SSO broker is now registered on the shared D-Bus session bus.
  Host applications can use your Entra ID token without any extra steps:

    • Microsoft Edge (host):      sign-in to https://login.microsoftonline.com
                                  — SSO kicks in automatically via D-Bus.
    • Chromium / Chrome ≥ 111:   same — built-in D-Bus SSO, no extension needed.
    • Flatpak Chrome / Chromium: install the Linux Entra SSO extension from the
                                  Chrome Web Store and keep this container running.
                                  Extension ID: jlnfnnolkbjieggibinobhkjdfbpcohn
    • CLI tools (host/container): use `linux-entra-sso --interactive getAccounts`
                                  to verify the registered account.

  Keep this container running while you use SSO in host applications.

  Daemon logs (himmelblaud, broker, himmelblaud_tasks):
    tail -f /tmp/himmelblau.log
SSO_READY
        else
            # Reset cursor to column 0 and erase the current line before drawing
            # the banner so that any stray cursor movement from background output
            # cannot push the box characters to a non-zero column.
            printf '\r\033[2K' >&2
            _show_enrollment_banner
        fi
        exec bash
    fi
fi

exec "$@"
