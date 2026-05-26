# Homelab

Personal DevOps homelab built on **Proxmox VE**.
Used as a learning environment for infrastructure, networking, automation, and self-hosted services.

> Author: **Szymon Wyrobek** ([@s-wyrobek](https://github.com/s-wyrobek))
> Status: actively developed

---

## About the project

This repository documents the design, configuration, and evolution of my home lab.
The goal is to build a small but realistic environment that mirrors production patterns:
- segregated services in VMs and LXC containers
- managed DNS with filtering
- reproducible deployments via Docker Compose (later: k3s, Terraform, Ansible)
- observability, secure remote access, and gradual cloud integration

The lab is also a playground for evaluating tooling before introducing it in larger setups.

---

## Stack

| Layer            | Technology                                          |
|------------------|-----------------------------------------------------|
| Hypervisor       | Proxmox VE 9.1                                      |
| Guest OS (VM)    | Debian 12                                           |
| Containers (LXC) | Debian 12 templates                                 |
| Containers (app) | Docker, Docker Compose                              |
| DNS              | AdGuard Home (DoH upstream, DNSSEC, blocklists)     |
| Storage / sync   | Nextcloud + MariaDB                                 |
| Reverse proxy    | Nginx (LXC 192.168.1.130)                           |
| VPN              | WireGuard (LXC 192.168.1.140)                       |
| TLS              | Self-signed CA, wildcard *.home cert                |
| Kubernetes       | k3s (single-node, debian-01)                        |
| Ingress          | Traefik (bundled with k3s)                          |
| Package manager  | Helm 3                                              |
| Monitoring       | Prometheus + Grafana (via Helm)                     |
| Automation       | n8n (via Helm, namespace: n8n)                      |
| Planned          | Terraform, Ansible, AWS                             |

---

## Infrastructure

| Host        | Type | IP             | Role                          | OS / Base       |
|-------------|------|----------------|-------------------------------|-----------------|
| pve         | Host | 192.168.1.100  | Proxmox VE hypervisor         | Proxmox VE 9.1  |
| debian-01   | VM   | 192.168.1.24   | k3s node (Docker + Kubernetes)| Debian 12       |
| dns         | LXC  | 192.168.1.110  | AdGuard Home                  | Debian 12       |
| nextcloud   | LXC  | 192.168.1.120  | Nextcloud + MariaDB           | Debian 12       |
| proxy-nginx | LXC  | 192.168.1.130  | Nginx reverse proxy           | Debian 12       |
| vpn         | LXC  | 192.168.1.140  | WireGuard VPN                 | Debian 12       |

Hardware: AMD Ryzen 5 3400G, 16 GB RAM, single node.
Details in [infrastructure/proxmox/README.md](infrastructure/proxmox/README.md).

---

## Network overview

```
                  ┌──────────────────────┐
   Internet ────► │  ISP CPE router      │  5G CPE
                  └──────────┬───────────┘
                             │
                  ┌──────────▼───────────┐
                  │  Managed L2 switch   │
                  └──┬───────┬───────┬───┘
                     │       │       │
              ┌──────▼─┐ ┌───▼────┐ ┌▼────────────────┐
              │ Wi-Fi  │ │  PVE   │ │  Workstation    │
              │  APs   │ │ host   │ │  EndeavourOS    │
              │ (×2)   │ │        │ │                 │
              └────────┘ └────────┘ └─────────────────┘
```

LAN: `192.168.1.0/24`
DNS: `192.168.1.110` (AdGuard Home) handed out by DHCP.
Details in [infrastructure/network/README.md](infrastructure/network/README.md).

---

## Repository layout

```
.
├── README.md
├── docs/
│   ├── decisions.md       # Architecture Decision Records
│   └── roadmap.md         # Phased roadmap
├── infrastructure/
│   ├── proxmox/README.md  # Hypervisor + VM/LXC inventory
│   └── network/README.md  # Topology, DNS, local domains
├── k3s/
│   ├── nginx-deployment.yaml
│   └── nginx-service.yaml
└── services/
    ├── dns/README.md      # AdGuard Home
    └── nextcloud/         # Nextcloud stack
        ├── README.md
        ├── docker-compose.yml
        └── .env.example
```

---

## Roadmap

- [x] Proxmox VE installed and tuned on the host
- [x] LAN segmented, managed switch in place
- [x] AdGuard Home as local resolver (DoH, DNSSEC, blocklists)
- [x] Nextcloud + MariaDB on a dedicated LXC
- [x] Nginx reverse proxy in front of internal services
- [x] WireGuard VPN for remote access
- [x] Custom internal CA + TLS for all `.home` services
- [x] k3s cluster on top of LXC/VM workers
- [x] Prometheus + Grafana for metrics and dashboards
- [ ] Terraform for Proxmox provisioning
- [ ] Ansible for configuration management
- [ ] AWS integration (off-site backups, then more)

Detailed plan: [docs/roadmap.md](docs/roadmap.md).

---

## License

See [LICENSE](LICENSE).
