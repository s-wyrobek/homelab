# Homelab

Personal DevOps homelab built on **Proxmox VE**.
Used as a learning environment for infrastructure, networking, automation, and self-hosted services.

> Author: **Szymon Wyrobek** ([@s-wyrobek](https://github.com/s-wyrobek))
> Status: actively developed

---

## Stack

| Layer            | Technology                                                              |
| ---------------- | ----------------------------------------------------------------------- |
| Hypervisor       | Proxmox VE 9.1                                                          |
| Guest OS (VM)    | Debian 12                                                               |
| Containers (LXC) | Debian 12 templates                                                     |
| Orchestration    | k3s (single-node)                                                       |
| Ingress          | Traefik (k3s) + Nginx (LXC reverse proxy)                               |
| DNS              | AdGuard Home (DoH upstream, DNSSEC, blocklists)                         |
| Monitoring       | Zabbix (Proxmox + LXC), Grafana + Prometheus (k3s)                     |
| IaC              | Terraform (`bpg/proxmox` provider), Ansible                             |
| Secrets          | BitWarden (manual), Vault (planned)                                     |
| Cloud emulation  | LocalStack Pro (AWS: S3, IAM, SQS, DynamoDB)                           |
| Workstation      | Ninkear A15 Plus — Ubuntu 26.04, zsh + OhMyZsh + Starship              |

---

## Infrastructure

| Host      | Type | IP              | Role                              | OS             |
| --------- | ---- | --------------- | --------------------------------- | -------------- |
| Proxmox   | Host | 192.168.1.100   | Proxmox VE hypervisor             | Proxmox VE 9.1 |
| Ninkear   | WS   | 192.168.1.22    | Primary workstation               | Ubuntu 26.04   |
| T490      | WS   | 192.168.1.23    | LocalStack node (headless)        | EndeavourOS    |
| debian-01 | VM   | 192.168.1.24    | k3s cluster                       | Debian 12      |
| dns       | LXC  | 192.168.1.110   | AdGuard Home                      | Debian 12      |
| nextcloud | LXC  | 192.168.1.120   | Nextcloud + MariaDB               | Debian 12      |
| nginx     | LXC  | 192.168.1.130   | Nginx reverse proxy + TLS         | Debian 12      |
| wireguard | LXC  | 192.168.1.140   | WireGuard VPN (wg-easy)           | Debian 12      |
| zabbix    | LXC  | 192.168.1.150   | Zabbix monitoring server          | Debian 12      |

Hardware: AMD Ryzen 5 3400G, 16 GB RAM, single node.

---

## Network overview

```
               ┌──────────────────────┐
Internet ────► │  ISP CPE router      │  5G CPE
               └──────────┬───────────┘
                          │
               ┌──────────▼───────────┐
               │  Managed L2 switch   │  TP-Link TL-SG108E
               └──┬───────┬───────┬───┘
                  │       │       │
           ┌──────▼─┐ ┌───▼────┐ ┌▼─────────────┐
           │ Wi-Fi  │ │  PVE   │ │  Workstations │
           │  APs   │ │  host  │ │  Ninkear/T490 │
           └────────┘ └────────┘ └───────────────┘
```

LAN: `192.168.1.0/24`
DNS: `192.168.1.110` (AdGuard Home) via DHCP
TLS: Custom CA (`~/homelab-ca/ca.crt`), explicit SANs per service

---

## Local domains (`.home`)

| Domain              | Target                          |
| ------------------- | ------------------------------- |
| `proxmox.home`      | Proxmox UI (192.168.1.100:8006) |
| `dns.home`          | AdGuard Home                    |
| `dysk.home`         | Nextcloud                       |
| `grafana.home`      | Grafana (k3s)                   |
| `prometheus.home`   | Prometheus (k3s)                |
| `n8n.home`          | n8n (k3s)                       |
| `traefik-k3s.home`  | Traefik dashboard (k3s)         |
| `homepage.home`     | Homepage dashboard (k3s)        |
| `zabbix.home`       | Zabbix monitoring               |

All `.home` domains → AdGuard rewrite → Nginx LXC (192.168.1.130) → upstream service.

---

## K3s services (debian-01)

| Service    | Description                    |
| ---------- | ------------------------------ |
| Traefik    | Ingress controller             |
| Grafana    | Metrics dashboards             |
| Prometheus | Metrics collection             |
| n8n        | Workflow automation            |
| Homepage   | Self-hosted dashboard          |

---

## LocalStack (T490)

AWS emulation via LocalStack Pro (free tier). Persistent resources via `init-localstack.sh`:

- S3: `app-logs`, `app-backups`
- IAM: `szymon-cloud-engineer` + S3FullAccess policy
- SQS: `app-events`
- DynamoDB: `app-data`

GUI: `localhost.localstack.cloud:4566` — requires SSH tunnel (`tunnel-ls` alias).

---

## Repository layout

```
.
├── README.md
├── ansible/                  # Ansible playbooks
│   ├── inventory.yaml
│   └── configure-ninkear.yaml
├── docs/
│   ├── decisions.md
│   └── roadmap.md
├── infrastructure/
│   ├── proxmox/README.md
│   ├── network/README.md
│   └── terraform/            # Proxmox provisioning (bpg/proxmox)
├── k3s/                      # Kubernetes manifests
├── localstack/               # LocalStack docker-compose + init script
├── scripts/
│   ├── lab-up.sh             # Wake-on-LAN: Proxmox + T490
│   └── lab-down.sh           # SSH poweroff both hosts
├── services/
│   └── ...
└── workstation/
    └── setup.sh              # Ninkear bootstrap script
```

---

## Roadmap

- [x] Proxmox VE installed and tuned
- [x] AdGuard Home as local resolver
- [x] Nextcloud + MariaDB
- [x] Nginx reverse proxy + custom TLS CA
- [x] WireGuard VPN (wg-easy)
- [x] k3s cluster (Traefik, Grafana, Prometheus, n8n, Homepage)
- [x] Terraform — Proxmox provisioning (`bpg/proxmox`)
- [x] Ansible — workstation config (`configure-ninkear.yaml`)
- [x] LocalStack — AWS emulation (S3, IAM, SQS, DynamoDB)
- [x] Wake-on-LAN scripts (Proxmox + T490)
- [x] Zabbix monitoring (Proxmox VE by HTTP template)
- [ ] Zabbix Agent2 on debian-01 (Docker/k3s monitoring)
- [ ] Firefox root CA automation via Ansible
- [ ] debian-01 DNS fix (AdGuard instead of 1.1.1.1)
- [ ] HashiCorp Vault as PKI backend
- [ ] GitLab CI/CD pipeline
- [ ] NetBird mesh VPN (planned)

---

## License

[MIT](LICENSE)