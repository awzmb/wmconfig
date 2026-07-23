# CoreOS + Incus Setup

This node runs Fedora CoreOS with Incus, OVN, and MinIO. Networking is split across three segments:

| Interface | Role |
|---|---|
| `eth0` | Management / Incus cluster address |
| `eth1–eth4` | Linux bridge `br-lan` → Incus `physnet` (physical network, L2 passthrough) |
| `eth5` | Direct NIC passthrough to a specific container |

---

## 1. Transpile and provision

```bash
# Install butane if not present
sudo dnf install -y butane          # or: brew install butane

# Transpile Butane → Ignition
butane --pretty --strict coreos.bu > coreos.ign

# Boot the ISO with the ignition file (adjust to your provisioning method)
# PXE / live ISO example:
coreos-installer install /dev/sda --ignition-file coreos.ign
```

> On first boot, `install-packages.service` runs once (stamp: `/var/lib/install-packages.service.stamp`).
> It installs packages via `rpm-ostree` and calls `incus admin init --preseed`.
> **A reboot is required after the service completes** for rpm-ostree changes to take effect.

---

## 2. Verify network bridge (post-boot)

```bash
# Bridge and slaves should be up
ip link show br-lan
bridge link show

# eth5 should show as unmanaged in NetworkManager
nmcli device status | grep eth5
```

---

## 3. Incus initial verification

```bash
incus network list
# Expected output includes:
#   incusbr0  bridge    (NAT, DHCP 10.0.0.x)
#   physnet   physical  (parent: br-lan)

incus profile list
# Expected profiles: default (incusbr0), physnet (br-lan)
```

---

## 4. Launch containers on the physical network (br-lan)

Containers on `physnet` receive their IP from whatever DHCP server exists on
the eth1–eth4 network segment. Incus does **not** provide DHCP for `physical`
type networks — that must come from an external router/DHCP server on that LAN.

```bash
# Launch a container using the physnet profile
incus launch images:ubuntu/22.04 mycontainer --profile physnet

# Or attach physnet to an existing container
incus config device add mycontainer eth0 nic network=physnet name=eth0
```

> **If you need Incus-managed DHCP on br-lan** (no external DHCP server):
> Change the network type in the preseed from `physical` to `bridge` and add
> `ipv4.address`, `ipv4.dhcp: true`, and `ipv4.nat: false`. This makes Incus
> manage dnsmasq on top of br-lan.

---

## 5. Attach eth5 to a specific container

`eth5` is marked unmanaged by NetworkManager so Incus can pass it directly.
This is a **per-container** operation — not a preseed network:

```bash
# Pass eth5 directly into a container (exclusive — one container at a time)
incus config device add <container> eth5 nic nictype=physical parent=eth5 name=eth0
```

---

## 6. Incus clustering

### Does clustering require a reserved physical NIC?

No — a dedicated NIC is **not required**, but recommended for production.
The cluster address can share `eth0` (management). Key facts:

- Each node needs a stable IP reachable by all other nodes on port `8444/tcp`
- Cluster raft traffic is low-bandwidth but latency-sensitive
- If `eth0` is also carrying container/storage traffic, consider a dedicated NIC

### Bootstrap the first node (already handled by preseed with `cluster: null`)

After first boot and rpm-ostree reboot:

```bash
# Confirm Incus is running
systemctl status incus.service

# If cluster: null was set in preseed, the node is standalone — promote to cluster:
incus cluster enable brouter
```

### Add subsequent nodes

On **node 2** (also booted from this ignition):

```bash
# On node 1 — generate a join token
incus cluster add node2
# → prints a token string

# On node 2
incus admin init
# Choose "join existing cluster", paste token, set cluster address to node2's eth0 IP
```

Repeat for each additional node.

### Firewall ports (already opened by install-packages.sh)

| Port | Protocol | Purpose |
|---|---|---|
| 8443 | TCP | Incus HTTPS API |
| 8444 | TCP | Incus cluster (raft) |
| 4789 | UDP | VXLAN (OVN overlay) |

---

## 7. DHCP server container on br-lan

Since `physnet` is a `physical`-type network, Incus provides **no DHCP** on it.
A dedicated container running `dnsmasq` acts as the DHCP server for the whole
`br-lan` segment.

### Create and configure the container

```bash
# Launch on the physnet profile (gets a NIC on br-lan)
incus launch images:ubuntu/24.04 dhcp-server --profile physnet

# PPPoE/routing containers that need to forward to br-lan must also be on physnet;
# only one container owns the DHCP server role.

# DHCP server needs to bind to port 67 and send broadcasts — make it privileged
incus config set dhcp-server security.privileged=true
incus restart dhcp-server
```

### Configure a static IP and dnsmasq inside the container

```bash
incus exec dhcp-server -- bash
```

Inside the container:

```bash
apt update && apt install -y dnsmasq

# Static IP on eth0 (pick an address outside your intended DHCP pool)
cat > /etc/netplan/01-static.yaml << 'EOF'
network:
  version: 2
  ethernets:
    eth0:
      addresses: [192.168.1.1/24]
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
EOF
netplan apply

# dnsmasq DHCP configuration
cat > /etc/dnsmasq.d/br-lan.conf << 'EOF'
interface=eth0
bind-interfaces

# Hand out 192.168.1.100 – 192.168.1.200 with a 24-hour lease
dhcp-range=192.168.1.100,192.168.1.200,24h

# Default gateway sent to clients — pppoe-router's LAN IP
dhcp-option=option:router,192.168.1.254

# DNS sent to clients
dhcp-option=option:dns-server,1.1.1.1,8.8.8.8
EOF

systemctl enable --now dnsmasq
systemctl status dnsmasq
```

> **Adjust** the subnet, pool range, and gateway to match your network.
> The gateway (`192.168.1.254`) should be the IP of the PPPoE/router container
> described in section 8.

---

## 8. PPPoE router container (eth5 → modem → internet gateway for all containers)

The `pppoe-router` container owns the internet connection and acts as the default
gateway for **all** Incus containers on this host — both `physnet` (br-lan) and
`incusbr0` containers.

```
[Modem] ──eth5──▶ pppoe-router ──ppp0──▶ [Internet]
                   eth1 (192.168.1.254)   ← physnet / br-lan containers
                   eth2 (10.0.0.254)      ← incusbr0 containers
```

`incusbr0` is pre-configured (via preseed `raw.dnsmasq`) to advertise
`10.0.0.254` as the default gateway. NAT on `incusbr0` is disabled — the
`pppoe-router` is the sole NAT boundary for all subnets.

### Prerequisites on the host

The `ppp` and `pppoe` kernel modules must be loaded. Add them to `coreos.bu`
under the existing `modules-load.d` file (or load manually until next reboot):

```bash
# Temporary (until next reboot)
sudo modprobe ppp pppoe

# Permanent — append to /etc/modules-load.d/kubernetes.conf in coreos.bu:
#   ppp
#   pppoe
```

### Create the container with all three NICs

```bash
# Launch empty (no profile — devices are added manually)
incus launch images:ubuntu/24.04 pppoe-router --empty

# WAN: eth5 passed directly as the physical modem-facing interface
incus config device add pppoe-router wan nic nictype=physical parent=eth5 name=eth0

# LAN 1: br-lan for physnet containers (192.168.1.254)
incus config device add pppoe-router lan nic network=physnet name=eth1

# LAN 2: incusbr0 for all other Incus containers (static 10.0.0.254)
incus config device add pppoe-router mgmt nic network=incusbr0 name=eth2

# PPPoE requires raw socket access
incus config set pppoe-router security.privileged=true

# Expose /dev/ppp from the host
incus config device add pppoe-router ppp unix-char source=/dev/ppp path=/dev/ppp

# Root disk
incus config device add pppoe-router root disk path=/ pool=default

incus start pppoe-router
```

### Configure addresses and PPPoE inside the container

```bash
incus exec pppoe-router -- bash
```

Inside the container:

```bash
apt update && apt install -y ppp pppoeconf net-tools iproute2 iptables iptables-persistent

# Static IPs on LAN interfaces (do NOT use DHCP — this container is the gateway)
cat > /etc/netplan/01-static.yaml << 'EOF'
network:
  version: 2
  ethernets:
    eth1:
      addresses: [192.168.1.254/24]
    eth2:
      addresses: [10.0.0.254/8]
EOF
netplan apply

# PPPoE on eth0 (WAN)
# Option A — interactive wizard
pppoeconf eth0

# Option B — manual
cat > /etc/ppp/peers/dsl-provider << 'EOF'
plugin rp-pppoe.so eth0
user "YOUR_ISP_USERNAME"
noipdefault
defaultroute
replacedefaultroute
hide-password
noauth
persist
maxfail 0
holdoff 5
EOF

echo '"YOUR_ISP_USERNAME" * "YOUR_ISP_PASSWORD" *' >> /etc/ppp/chap-secrets
chmod 600 /etc/ppp/chap-secrets

pon dsl-provider

# Verify ppp0 is up with a WAN IP
ip addr show ppp0
ip route show
```

### Enable NAT and IP forwarding (gateway function)

```bash
# Inside pppoe-router:

# Enable IP forwarding
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.d/99-forwarding.conf
sysctl -p /etc/sysctl.d/99-forwarding.conf

# Masquerade ALL LAN subnets out through ppp0
iptables -t nat -A POSTROUTING -o ppp0 -j MASQUERADE

# Allow forwarding from both LAN segments to WAN and back
iptables -A FORWARD -i eth1 -o ppp0 -j ACCEPT
iptables -A FORWARD -i eth2 -o ppp0 -j ACCEPT
iptables -A FORWARD -i ppp0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i ppp0 -o eth2 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Also allow traffic between the two LAN segments (optional)
iptables -A FORWARD -i eth1 -o eth2 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -j ACCEPT

# Persist rules
netfilter-persistent save
```

### Auto-start PPPoE on container boot

```bash
# Inside the container
cat > /etc/rc.local << 'EOF'
#!/bin/bash
pon dsl-provider
exit 0
EOF
chmod +x /etc/rc.local
systemctl enable rc-local
```

### Verify from another container

```bash
# On any incusbr0 container
incus exec some-container -- ip route show
# default via 10.0.0.254  ← must point to pppoe-router

incus exec some-container -- ping 1.1.1.1
```

> **Note**: `incusbr0` containers receive `10.0.0.254` as their default gateway
> via DHCP (configured in the preseed via `raw.dnsmasq`). If `pppoe-router` is
> not yet running, those containers will have no internet access until it starts.
> The `incusbr0` bridge itself (`10.0.0.1`) remains reachable for host-level
> services regardless.

---

## 9. MinIO

The install scripts are placed at `/usr/local/bin/` but **not run automatically**.
Run them manually after the rpm-ostree reboot:

```bash
# Install MinIO server
sudo /usr/local/bin/install-minio.sh

# Install MinIO client (mcli)
sudo /usr/local/bin/install-minio-client.sh

# Start MinIO (example — adjust paths/credentials)
export MINIO_ROOT_USER=admin
export MINIO_ROOT_PASSWORD=changeme
minio server /var/data/minio --console-address ":9001" &
```

---

## 10. OVN (for Incus cluster overlay networking)

OVN is installed and the config stub is at `/etc/sysconfig/ovn`. After the
rpm-ostree reboot, the OVS bridge is configured by `install-packages.sh`.
Refer to the upstream docs for full cluster OVN setup:

- https://linuxcontainers.org/incus/docs/main/howto/network_ovn_setup/
- https://andreaskaris.github.io/blog/networking/ovn_standalone_on_fedora/

```bash
# Verify OVN is running
systemctl status ovn-northd.service
systemctl status ovn-controller.service
ovs-vsctl show
```
