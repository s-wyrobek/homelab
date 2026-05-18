# Network

Flat `192.168.1.0/24` LAN behind a 5G CPE router, with a managed switch as the core.
Two access points cover Wi-Fi. VLANs are planned but not yet enabled.

---

## Topology

```
                       ┌──────────────────────────┐
        Internet ────► │  ISP CPE router          │
                       │  (5G CPE)                │
                       │  192.168.1.1             │
                       └──────────────┬───────────┘
                                      │ 1 GbE
                       ┌──────────────▼───────────┐
                       │  Managed L2 switch       │
                       └──┬─────┬─────┬────────┬──┘
                          │     │     │        │
              ┌───────────▼─┐   │     │        │
              │ Wi-Fi AP    │   │     │        │
              │ (primary)   │   │     │        │
              └─────────────┘   │     │        │
                                │     │        │
                  ┌─────────────▼─┐   │        │
                  │ Wi-Fi AP      │   │        │
                  │ (secondary)   │   │        │
                  └───────────────┘   │        │
                                      │        │
                            ┌─────────▼──┐  ┌──▼──────────────┐
                            │ Proxmox VE │  │ Workstation     │
                            │ 192.168.1.10│ │ EndeavourOS     │
                            │            │  │                 │
                            │ ┌────────┐ │  └─────────────────┘
                            │ │debian-01│ │
                            │ │.24 (VM) │ │
                            │ ├────────┤ │
                            │ │dns .110 │ │
                            │ │(LXC)    │ │
                            │ ├────────┤ │
                            │ │nextcloud│ │
                            │ │.120 LXC │ │
                            │ └────────┘ │
                            └────────────┘
```

---

## Addressing

| Range / Address      | Purpose                                    |
|----------------------|--------------------------------------------|
| 192.168.1.0/24       | LAN                                        |
| 192.168.1.1          | Default gateway (ISP CPE router)           |
| 192.168.1.10         | Proxmox VE host                            |
| 192.168.1.24         | debian-01 (Docker host)                    |
| 192.168.1.110        | dns (AdGuard Home)                         |
| 192.168.1.120        | nextcloud (Nextcloud + MariaDB)            |
| 192.168.1.200–250    | DHCP pool for clients                      |

Infrastructure hosts use static IPs and matching DHCP reservations on the router.

---

## DNS

AdGuard Home on `192.168.1.110` is the only DNS server advertised by DHCP.

- **Upstream**: DNS-over-HTTPS to Cloudflare (`https://dns.cloudflare.com/dns-query`)
- **DNSSEC**: enabled
- **Blocking mode**: `REFUSED` (so clients fail fast instead of timing out)
- **Blocklists**: HaGeZi Pro, OISD, Peter Lowe, CERT Polska, URLHaus
- **Local rewrites**: `*.home` resolves to internal IPs (see below)

Details and operational notes: [services/dns/README.md](../../services/dns/README.md).

---

## Local domains

All internal services use the `.home` TLD. Resolution is provided by AdGuard rewrites,
no public DNS records exist for these names.

| Hostname           | Target IP        | Service              |
|--------------------|------------------|----------------------|
| pve.home           | 192.168.1.100    | Proxmox web UI       |
| debian-01.home     | 192.168.1.24     | Docker host          |
| dns.home           | 192.168.1.110    | AdGuard Home UI      |
| nextcloud.home     | 192.168.1.120    | Nextcloud (port 8080)|

A reverse proxy (Nginx) and a local CA are planned so that `https://nextcloud.home`
works without explicit ports or browser warnings.

---

## Wi-Fi

| AP                   | Role                       | Notes                                |
|----------------------|----------------------------|--------------------------------------|
| Wi-Fi AP (primary)   | Primary AP                 | LTE fallback disabled, AP mode only  |
| Wi-Fi AP (secondary) | Secondary AP / coverage    | Same SSID, different channel         |

Both APs are bridged into the same `192.168.1.0/24` LAN. No guest network yet —
guest isolation and IoT VLAN are in the roadmap.

---

## Planned changes

- VLAN segmentation on the managed L2 switch (management / services / clients / IoT).
- WireGuard endpoint on the Proxmox host (or a dedicated LXC) for remote access.
- Nginx reverse proxy fronting `*.home` services on standard ports.
