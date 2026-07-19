# portable-intune-linux

A portable container image that runs [himmelblau](https://github.com/himmelblau-idm/himmelblau)
— the open-source Entra ID / Microsoft Intune SSO broker for Linux — inside a
rootless Podman container. Because the broker registers on your host's D-Bus
session bus, host applications such as Microsoft Edge and Chromium pick up SSO
tokens automatically with **no changes to the host system**.

---

## Table of contents

1. [How it works](#how-it-works)
2. [Prerequisites](#prerequisites)
3. [Step-by-step enrollment guide](#step-by-step-enrollment-guide)
   - [Step 1 – Set your Entra ID credentials](#step-1--set-your-entra-id-credentials)
   - [Step 2 – Build the image and start the container](#step-2--build-the-image-and-start-the-container)
   - [Step 3 – Enroll your Entra ID account](#step-3--enroll-your-entra-id-account)
   - [Step 4 – Verify SSO is active](#step-4--verify-sso-is-active)
   - [Step 5 – Use SSO in host applications](#step-5--use-sso-in-host-applications)
   - [Step 5a – Install the browser extension (Flatpak / older Chromium)](#step-5a--install-the-browser-extension-flatpak--older-chrome)
4. [Configuration reference](#configuration-reference)
5. [Subsequent runs](#subsequent-runs)
6. [Troubleshooting](#troubleshooting)

---

## How it works

```
┌─────────────────────────────────────────────────────────────────┐
│  Host (your Linux desktop / laptop)                             │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  Podman container (rootless)                           │     │
│  │                                                        │     │
│  │  himmelblaud ─────────────────────────────────────►    │     │
│  │  himmelblaud_tasks (Intune enrollment & compliance) ─► │     │
│  │                          broker (D-Bus service)        │     │
│  │                              │                         │     │
│  │  linux-entra-sso ◄───────────┘  (shares host D-Bus)    │     │
│  └────────────────────────────────────────────────────────┘     │
│                               │                                 │
│  Microsoft Edge / Chromium ◄──┘                                 │
│    D-Bus SSO (native, Chromium 111+)   ← com.microsoft.identity.  │
│    OR browser extension + NM host    ← linux_entra_sso          │
└─────────────────────────────────────────────────────────────────┘
```

1. `start.sh` builds the image and starts the container, mounting your host's
   D-Bus session socket into the container.
2. Inside the container, `himmelblaud` and **`himmelblaud_tasks`** run together.
   `himmelblaud` handles authentication against Entra ID; `himmelblaud_tasks`
   completes background Intune device-enrollment and compliance tasks — both
   are required for browsers to see the device as enrolled.
3. `broker` registers the `com.microsoft.identity.broker1` D-Bus service on the
   **host** session bus.  Chromium 111 and later find this service automatically
   and request SSO tokens without any browser extension.
4. `start.sh` also installs a thin **native-messaging host bridge** on the host
   and the companion manifest for every supported browser (native and Flatpak).
   This enables the
   [Linux Entra SSO](https://chrome.google.com/webstore/detail/jlnfnnolkbjieggibinobhkjdfbpcohn)
   browser extension as an additional SSO path — useful for older Chromium
   versions or Flatpak browsers where D-Bus access may be restricted.

---

## Prerequisites

| Requirement | Notes |
|---|---|
| **Podman** ≥ 4.0 | `sudo apt install podman` / `sudo dnf install podman` |
| **Wayland or X11 display** | Required to forward the display into the container |
| **D-Bus session bus** | Must be running (`echo $DBUS_SESSION_BUS_ADDRESS`) |
| **Internet access** | The build stage clones himmelblau from GitHub |
| **Entra ID account** | A Microsoft 365 / Azure AD user principal name (UPN) |

> **Docker users:** `start.sh` is written for Podman and uses Podman-specific
> flags such as `--userns=keep-id` and volume label suffixes (`:Z`). Docker
> does not support `--userns=keep-id`; see the
> [Troubleshooting](#troubleshooting) section for Docker alternatives.

---

## Step-by-step enrollment guide

### Step 1 – Set your Entra ID credentials

Export the following environment variables before running `start.sh`.
You will be prompted interactively for any that are not set.

```bash
# Required – your Entra ID / Microsoft 365 domain
export HIMMELBLAU_DOMAIN="contoso.com"

# Required – your full Entra ID user principal name (UPN)
export HIMMELBLAU_USER="alice@contoso.com"

# Optional – Entra ID tenant GUID (leave unset to use the domain for discovery)
# export HIMMELBLAU_TENANT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

### Step 2 – Build the image and start the container

From the directory that contains `start.sh` and `Dockerfile`:

```bash
bash start.sh
```

`start.sh` will:
- Write a `himmelblau.conf` and `user-map` to
  `~/.config/himmelblau/` on your host.
- Build the container image (this may take **10–20 minutes** on the first run
  while Rust and himmelblau compile).
- Create two named Podman volumes (`himmelblau-data`, `himmelblau-cache`) for
  persistent state that does not need to be visible on the host filesystem.
- Start the container and drop you into a Bash shell.

> **Tip:** The image is tagged `localhost/himmelblau`. On subsequent runs the
> build step is nearly instant because the layer cache is reused.

### Step 3 – Enroll your Entra ID account

Inside the container shell you will see an enrollment banner similar to:

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Entra ID account not yet enrolled                                       │
│                                                                          │
│  Populate the account cache so himmelblaud can find your identity:       │
│                                                                          │
│    aad-tool auth-test --name alice@contoso.com                           │
│                                                                          │
│  …                                                                       │
└──────────────────────────────────────────────────────────────────────────┘
```

Run the displayed command to enroll your account:

```bash
aad-tool auth-test --name alice@contoso.com
```

You will be prompted to authenticate. Depending on your tenant's policy:

- **Password only** – enter your Entra ID password.
- **MFA** – after the password prompt you will be asked to approve a push
  notification in the Microsoft Authenticator app or enter a TOTP code.
- **Hello PIN / FIDO2** – follow the on-screen instructions.

#### Expected output on success

```
Authentication successful
```

> **Note on PAM_ABORT on first run:** In a rootless container the Hello PIN
> setup daemon requires root, so the first `auth-test` call may end with
> `PAM_ABORT` after the PIN prompt. This is expected — authentication still
> completes in the background. You will see "Authentication successful" in the
> log output shortly after. Simply run the command **a second time** and it
> will succeed immediately using the cached token.

### Step 4 – Verify SSO is active

After successful enrollment, exit the container shell and restart the container
(or re-run `start.sh`). The entrypoint checks for an enrolled account and, if
found, starts `linux-entra-sso --interactive` automatically. You should see:

```
✓ Entra ID account enrolled. SSO broker services are ready.

  The SSO broker is now registered on the shared D-Bus session bus.
  Host applications can use your Entra ID token without any extra steps:

    • Microsoft Edge (host):   sign-in to https://login.microsoftonline.com
                               — SSO kicks in automatically via D-Bus.
    • Chromium (host):         same — no additional config needed.
    • CLI tools (host/container): use `linux-entra-sso --interactive getAccounts`
                               to verify the registered account.

  Keep this container running while you use SSO in host applications.
```

You can also verify from **within the container shell** (which is opened after
the banner):

```bash
linux-entra-sso --interactive getAccounts
```

A JSON response containing a `"username"` field confirms the account is
enrolled and the broker is reachable.

### Step 5 – Use SSO in host applications

Keep the container running in the background. As long as it is alive, host
applications that speak the Microsoft identity broker protocol will find the
broker on D-Bus and request tokens silently:

| Application | How SSO works |
|---|---|
| **Microsoft Edge** | Navigate to any Microsoft 365 / Azure resource. Edge detects the D-Bus broker and signs you in automatically. |
| **Chromium (native, ≥ 111)** | Same as Edge — built-in D-Bus SSO, no extension needed. |
| **Chromium (Flatpak)** | Requires the browser extension — see [Step 5a](#step-5a--install-the-browser-extension-flatpak--older-chrome). |
| **curl / custom scripts** | Use `linux-entra-sso --interactive getAccounts` inside the container to obtain a token programmatically. |

> **Keep the container running** while using SSO. Closing the container
> unregisters the D-Bus service and SSO stops working for host apps until the
> container is restarted.

### Step 5a – Install the browser extension (Flatpak / older Chromium)

Chromium 111+ and Microsoft Edge communicate with the broker directly over
D-Bus without any browser extension. If you are running **Flatpak Chromium**,
or an older browser that does not support the native D-Bus broker protocol, install the
[**Linux Entra SSO**](https://chrome.google.com/webstore/detail/jlnfnnolkbjieggibinobhkjdfbpcohn)
extension from the Chrome Web Store.

`start.sh` automatically installs a **native-messaging host bridge** and the
required JSON manifests for all common browser variants (native and Flatpak).
No further host-side setup is required — just install the extension in your
browser:

1. Open the Chrome Web Store link above and click **Add to Chrome**.
2. When prompted, grant the extension access to `https://login.microsoftonline.com`.
3. Navigate to `https://login.microsoftonline.com` and sign in.
   The extension injects a PRT SSO cookie so the login completes without
   a password prompt.

> **Flatpak note:** Chromium Flatpak spawns the native-messaging host
> (`~/.local/bin/linux-entra-sso-host-bridge`) as a host-side subprocess
> outside the Flatpak sandbox.  The bridge script calls
> `podman exec himmelblau-broker linux-entra-sso` so the container must be
> running when the extension calls it.

> **`socket=session-bus` note:** Flatpak Chromium with the
> `socket=session-bus` permission can also use the D-Bus broker directly
> (Chromium 111+) without the extension — provided `himmelblaud_tasks` has
> completed Intune device enrollment.  If Chromium still shows
> *"To enroll your device"* after a successful login, wait a minute for the
> background enrollment tasks to finish, then reload the page.

---

## Configuration reference

| Variable | Required | Description |
|---|---|---|
| `HIMMELBLAU_DOMAIN` | ✅ | Entra ID / Microsoft 365 domain (e.g. `contoso.com`) |
| `HIMMELBLAU_USER` | ✅ | Full UPN of the enrolling user (e.g. `alice@contoso.com`) |
| `HIMMELBLAU_TENANT_ID` | ☑️ optional | Entra ID tenant GUID. Omit to use domain-based discovery. |

Configuration files written to the host by `start.sh`:

| Path | Contents |
|---|---|
| `~/.config/himmelblau/himmelblau.conf` | Domain, optional tenant ID, UID idmap range |
| `~/.config/himmelblau/user-map` | `localuser:entra-upn` mapping |

Persistent storage mounted into the container:

| Mount | Container path | Purpose |
|---|---|---|
| podman volume `himmelblau-data` | `/var/lib/himmelblaud` | Enrolled account identity database |
| podman volume `himmelblau-cache` | `/var/cache/himmelblaud` | HSM PIN and key material (survives restarts) |
| host path `~/.config/himmelblau` | `/etc/himmelblau` | himmelblau.conf and user-map (written by `start.sh`, host-readable) |

> **Why named volumes for data/cache?**  The identity database and HSM key
> material only need to survive container restarts — no host process reads them
> directly.  Named Podman volumes are the right tool for that job.  Only the
> config directory must live on the host filesystem because `start.sh` writes
> it before the container starts.

---

## Subsequent runs

Once enrolled, simply re-run `start.sh` from the same directory:

```bash
bash start.sh
```

The build step completes almost instantly (layer cache hit). The entrypoint
detects your enrolled account and starts the SSO broker automatically — no
need to run `aad-tool auth-test` again unless your token has expired.

---

## Troubleshooting

### Browser still shows "To enroll your device" after successful login

This message means Chromium can find the broker on D-Bus but the
device has **not yet been enrolled in Intune MDM**.  Enrollment is handled by
`himmelblaud_tasks`, which now starts automatically alongside `himmelblaud`.
Possible causes and fixes:

1. **Using an old image** – rebuild to pick up the `himmelblaud_tasks` fix:
   ```bash
   podman rmi localhost/himmelblau
   bash start.sh
   ```
2. **Enrollment is still in progress** – `himmelblaud_tasks` runs background
   jobs after the first authenticated login.  Wait 1–2 minutes after running
   `aad-tool auth-test`, then reload the browser page.
3. **Flatpak browser without the extension** – Flatpak Chromium with
   only `socket=session-bus` may still require the browser extension on some
   versions.  Install the
   [Linux Entra SSO extension](https://chrome.google.com/webstore/detail/jlnfnnolkbjieggibinobhkjdfbpcohn)
   and check that the native-messaging host bridge is in place:
   ```bash
   cat ~/.local/bin/linux-entra-sso-host-bridge
   ls ~/.var/app/org.chromium.Chromium/config/chromium/NativeMessagingHosts/
   ```
   If those files are missing, re-run `start.sh` (the bridge and manifests are
   created before the container starts).

### Flatpak browser and D-Bus SSO (socket=session-bus)

Chromium Flatpak with `socket=session-bus` connects to the real
session bus and should reach `com.microsoft.identity.broker1` directly (Chromium
111+).  If it still fails:

* Verify the service is registered on the **host** session bus:
  ```bash
  dbus-send --session --dest=org.freedesktop.DBus \
    --type=method_call --print-reply /org/freedesktop/DBus \
    org.freedesktop.DBus.NameHasOwner \
    string:"com.microsoft.identity.broker1"
  # should return: boolean true
  ```
* Check the container is running and `himmelblaud_tasks` is alive:
  ```bash
  podman exec himmelblau-broker pgrep -a himmelblaud_tasks
  ```
* If you granted Flatpak the `socket=session-bus` permission **after** the
  browser was already running, restart the browser so it picks up the new
  permission.

### `ERROR: Failed to bind UNIX socket /var/run/himmelblaud/task_sock`

The socket directory was not created before the daemon started. This is handled
automatically by `docker-entrypoint.sh`, but if you start `himmelblaud`
manually inside the container, create the directory first:

```bash
mkdir -p /var/run/himmelblaud
himmelblaud
```

### `PAM_ABORT` on first auth-test run

Expected behaviour in a rootless container — see [Step 3](#step-3--enroll-your-entra-id-account).
Run the command a second time and it will succeed.

### `DBUS_SESSION_BUS_ADDRESS` is empty

The D-Bus session bus is required for the broker. Ensure it is running on the
host:

```bash
echo $DBUS_SESSION_BUS_ADDRESS
# should print something like: unix:path=/run/user/1000/bus
```

If it is empty, start a session bus with `dbus-launch --sh-syntax` and export
the printed address before running `start.sh`.

### Docker instead of Podman

`start.sh` uses Podman-specific options. To use Docker:

1. Replace `podman buildx build` with `docker build`.
2. Replace `podman run ... --userns=keep-id` with `docker run` (remove the
   `--userns=keep-id` flag).
3. Replace the `:Z` volume suffixes with `:z` or remove them.
4. Replace `podman rm -f` / `podman exec` references with their `docker`
   equivalents.
5. Note: without `--userns=keep-id` the in-container UID may differ from your
   host UID, which can cause permission issues with the mounted config/data
   directories.

### Container exits immediately / no banner shown

Check that a display is available:

```bash
echo $DISPLAY          # X11: should print :0 or similar
echo $WAYLAND_DISPLAY  # Wayland: should print wayland-0 or similar
```

At least one of these must be set for the entrypoint to enter interactive mode.
