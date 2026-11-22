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
                       └──┬─────┬─────┬────────┬──────────────────┬──┘
                          │     │     │        │                  │
              ┌───────────▼─┐   │     │        │                  │
              │ Wi-Fi AP    │   │     │        │                  │
              │ (primary)   │   │     │        │                  │
              └─────────────┘   │     │        │                  │
                                │     │        │                  │
                  ┌─────────────▼─┐   │        │                  │
                  │ Wi-Fi AP      │   │        │                  │
                  │ (secondary)   │   │        │                  │
                  └───────────────┘   │        │                  │
                                      │        │                  │
                            ┌─────────▼──┐  ┌──▼──────────────┐  ┌──▼──────────────┐
                            │ Proxmox VE │  │ Ninkear A15     │  │ T490 (spare)    │
                            │192.168.1.252  │ .22             │  │ .23             │
                            │            │  │ Ubuntu 26.04    │  │ EndeavourOS     │
                            │ ┌────────┐ │  └─────────────────┘  └─────────────────┘
                            │ │debian-01│ │
                            │ │.24 (VM) │ │
                            │ ├────────┤ │
                            │ │LXC 102- │ │
                            │ │108 (.1xx│ │
                            │ │=VMID)   │ │
                            │ └────────┘ │
                            └────────────┘
```

---

## Addressing

| Range / Address      | Purpose                                    |
|----------------------|--------------------------------------------|
| 192.168.1.0/24       | LAN                                        |
| 192.168.1.1          | Default gateway (ISP CPE router)           |
| 192.168.1.22         | nikear (Ninkear A15 Plus workstation)      |
| 192.168.1.23         | T490 (headless spare, LocalStack retired)  |
| 192.168.1.24         | debian-01 (k3s node)                       |
| 192.168.1.102        | Disk-Nextcloud (Nextcloud + MariaDB)       |
| 192.168.1.103        | Proxy-Nginx (Nginx reverse proxy + TLS)    |
| 192.168.1.105        | Monitor-Zabbix (Zabbix server)             |
| 192.168.1.106        | Secrets-Vault (HashiCorp Vault)            |
| 192.168.1.107        | Cloud-Floci (LocalStack replacement)       |
| 192.168.1.108        | Dash-Homepage (Homepage dashboard)         |
| 192.168.1.252        | Proxmox VE host                            |
| 192.168.1.253        | Raspberry Pi bastion (NetBird + AdGuard)   |
| 192.168.1.200–250    | DHCP pool for clients                      |

Infrastructure hosts use static IPs and matching DHCP reservations on the router.

---

## DNS

AdGuard Home on the Pi bastion (`192.168.1.253`) is the only DNS server advertised by DHCP.

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

| Hostname           | Target IP        | Service                      |
|--------------------|------------------|------------------------------|
| proxmox.home       | 192.168.1.252    | Proxmox VE UI                |
| dns.home           | 192.168.1.253    | AdGuard Home UI (Pi)         |
| dysk.home          | 192.168.1.103    | Nextcloud (via Nginx)        |
| nginx.home         | 192.168.1.103    | Nginx status page            |
| vault.home         | 192.168.1.103    | Vault (via Nginx)            |
| zabbix.home        | 192.168.1.103    | Zabbix (via Nginx)           |
| grafana.home       | 192.168.1.24     | Grafana                      |
| prometheus.home    | 192.168.1.24     | Prometheus                   |
| n8n.home           | 192.168.1.24     | n8n automation               |
| homepage.home      | 192.168.1.24     | Homepage dashboard (stale — should move to LXC 108) |
| traefik-k3s.home   | 192.168.1.24     | Traefik dashboard            |
| floci.home         | 192.168.1.103    | Floci (via Nginx/HTTPS)      |
| localstack.home    | 192.168.1.103    | Legacy alias → Floci         |

All `.home` names are DNS rewrites in AdGuard Home. Traffic is routed through Nginx
(192.168.1.103) for TLS termination with a locally-issued wildcard certificate (`*.home`).

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
- Guest network and IoT VLAN on Wi-Fi APs.
