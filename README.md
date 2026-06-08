# Homelab

Personal DevOps homelab built on **Proxmox VE**.
Used as a learning environment for infrastructure, networking, automation, cloud integration, and self-hosted services.

> Author: **Szymon Wyrobek** ([@s-wyrobek](https://github.com/s-wyrobek))  
> Status: **actively developed**

---

## About the project

This repository documents the design, configuration, and evolution of my home lab.
The goal is to build a small but realistic environment that mirrors production patterns:

- segregated services in VMs and LXC containers
- managed DNS with filtering and local TLS
- reproducible deployments via Docker Compose, k3s, Terraform, and Ansible
- observability with Prometheus and Grafana
- secure remote access via WireGuard VPN
- local AWS emulation via LocalStack

The lab is also a playground for evaluating tooling before introducing it in larger setups.

---

## Hardware

| Machine | CPU | RAM | Role |
|---|---|---|---|
| Proxmox node | AMD Ryzen 5 3400G | 16 GB | Hypervisor (VMs + LXC) |
| Ninkear A15 Plus | AMD Ryzen 7 5825U | 16 GB | Main workstation (Ubuntu 26.04 LTS) |
| ThinkPad T490 | Intel Core i7-8550U | 24 GB | LocalStack node (EndeavourOS, headless) |
| Gaming desktop | AMD Ryzen 5 3600X + RTX 2080 | 32 GB | Gaming / spare |

---

## Stack

| Layer | Technology |
|---|---|
| Hypervisor | Proxmox VE 9.1 |
| Guest OS (VM) | Debian 12 |
| Containers (LXC) | Debian 12 templates |
| Containers (app) | Docker, Docker Compose |
| DNS | AdGuard Home (DoH upstream, DNSSEC, blocklists) |
| Reverse proxy | Nginx (wildcard TLS, local CA) |
| VPN | WireGuard via wg-easy |
| Storage / sync | Nextcloud + MariaDB |
| Orchestration | k3s (single-node) |
| Ingress | Traefik |
| Monitoring | Prometheus + Grafana |
| Automation | n8n |
| Dashboard | Homepage |
| IaC | Terraform (bpg/proxmox provider) |
| Config management | Ansible |
| AWS emulation | LocalStack (community, Docker) |
| Workstation OS | Ubuntu 26.04 LTS |

---

## Infrastructure

| Host | Type | IP | Role | OS |
|---|---|---|---|---|
| pve | Host | 192.168.1.100 | Proxmox VE hypervisor | Proxmox VE 9.1 |
| debian-01 | VM | 192.168.1.24 | k3s node (Traefik, Grafana, Prometheus, n8n) | Debian 12 |
| dns | LXC | 192.168.1.110 | AdGuard Home | Debian 12 |
| nextcloud | LXC | 192.168.1.120 | Nextcloud + MariaDB | Debian 12 |
| nginx | LXC | 192.168.1.130 | Nginx reverse proxy + TLS termination | Debian 12 |
| wireguard | LXC | 192.168.1.140 | WireGuard VPN (wg-easy) | Debian 12 |
| nikear | Workstation | 192.168.1.22 | Main workstation | Ubuntu 26.04 LTS |
| localstack | Node | 192.168.1.23 | LocalStack AWS emulator (headless) | EndeavourOS |

---

## Network overview

```
                       ┌──────────────────────────┐
        Internet ────► │  ISP CPE router          │
                       │  (5G CPE)                │
                       │  192.168.1.1             │
                       └──────────────┬───────────┘
                                      │ 1 GbE
                       ┌──────────────▼───────────┐
                       │  TP-Link TL-SG108E       │  L2 managed switch
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
                            │ Proxmox VE │  │ Ninkear A15     │  │ LocalStack T490 │
                            │192.168.1.100  │ .22             │  │ .23             │
                            │            │  │ Ubuntu 26.04    │  │ EndeavourOS     │
                            │ ┌────────┐ │  └─────────────────┘  └─────────────────┘
                            │ │debian-01│ │
                            │ │.24 (VM) │ │
                            │ ├────────┤ │
                            │ │dns .110 │ │
                            │ │(LXC)    │ │
                            │ ├────────┤ │
                            │ │nextcloud│ │
                            │ │.120 LXC │ │
                            │ ├────────┤ │
                            │ │nginx    │ │
                            │ │.130 LXC │ │
                            │ ├────────┤ │
                            │ │wireguard│ │
                            │ │.140 LXC │ │
                            │ └────────┘ │
                            └────────────┘
```

LAN: `192.168.1.0/24`  
DNS: `192.168.1.110` (AdGuard Home)  
Details in [infrastructure/network/README.md](infrastructure/network/README.md).

---

## Local domains (`.home`)

| Domain | Points to | Service |
|---|---|---|
| `dns.home` | 192.168.1.110 | AdGuard Home |
| `dysk.home` | 192.168.1.130 | Nextcloud (via Nginx) |
| `nginx.home` | 192.168.1.130 | Nginx dashboard |
| `grafana.home` | 192.168.1.24 | Grafana |
| `prometheus.home` | 192.168.1.24 | Prometheus |
| `n8n.home` | 192.168.1.24 | n8n |
| `homepage.home` | 192.168.1.24 | Homepage dashboard |
| `traefik-k3s.home` | 192.168.1.24 | Traefik dashboard |
| `localstack.home` | 192.168.1.130 | LocalStack (via Nginx + HTTPS) |

All `.home` domains resolved by AdGuard DNS rewrites, served over HTTPS via Nginx with a locally-issued wildcard certificate (`*.home`).

---

## k3s services

Deployed on `debian-01` (192.168.1.24) via Helm:

| Service | Namespace | Access |
|---|---|---|
| Traefik | kube-system | `traefik-k3s.home` |
| Grafana | default | `grafana.home` |
| Prometheus | default | `prometheus.home` |
| n8n | n8n | `n8n.home` |
| Homepage | homepage | `homepage.home` |

---

## LocalStack

LocalStack runs as a Docker container on `T490/localstack` (192.168.1.23).
Accessible via:
- **AWS CLI**: `awslocal s3 ls` (endpoint auto-set to `http://192.168.1.23:4566`)
- **Web GUI**: `https://app.localstack.cloud` → instance `localhost.localstack.cloud:4566`

Enabled services: `s3`, `lambda`, `iam`, `dynamodb`, `sqs`, `ec2`, `kinesis`

---

## Repository layout

```
.
├── README.md
├── docs/
│   ├── decisions.md          # Architecture Decision Records
│   └── roadmap.md            # Phased roadmap
├── infrastructure/
│   ├── proxmox/README.md     # Hypervisor + VM/LXC inventory
│   ├── network/README.md     # Topology, DNS, local domains
│   └── terraform/
│       └── proxmox/          # Terraform configs (bpg/proxmox)
├── ansible/
│   ├── inventory.yaml
│   ├── apt-upgrade.yaml
│   └── services-check.yaml
├── ansible.cfg
├── k3s/                      # Kubernetes manifests + Ingress configs
└── services/
    ├── dns/README.md
    ├── nextcloud/
    ├── nginx/README.md
    ├── wireguard/README.md
    └── homepage/
        └── homepage-values.yaml
```

---

## Roadmap

### Done ✅

- [x] Proxmox VE installed and tuned
- [x] LAN segmented, managed switch in place
- [x] AdGuard Home — DNS resolver with DoH, DNSSEC, blocklists
- [x] Nextcloud + MariaDB on dedicated LXC
- [x] Nginx reverse proxy with wildcard TLS (local CA)
- [x] WireGuard VPN via wg-easy
- [x] Local CA + wildcard cert for all `.home` services
- [x] k3s cluster on debian-01 VM
- [x] Traefik as Ingress controller
- [x] Prometheus + Grafana for metrics
- [x] n8n for automation workflows
- [x] Homepage dashboard
- [x] Terraform for Proxmox provisioning (bpg/proxmox provider)
- [x] Ansible for configuration management (4 LXCs)
- [x] LocalStack AWS emulator (headless node, web GUI)
- [x] New workstation: Ninkear A15 Plus (Ubuntu 26.04 LTS)

### In progress 🔄

- [ ] GitLab CI/CD pipeline
- [ ] Wake-on-LAN for Proxmox and LocalStack nodes
- [ ] Fix Homepage API widgets (Grafana, Prometheus, WireGuard)
- [ ] Grafana dashboards with Prometheus metrics

### Planned 📋

- [ ] AWS CLI exercises on LocalStack (S3, Lambda, IAM, DynamoDB)
- [ ] Terraform for LocalStack resources
- [ ] Nightly Prometheus metrics email via n8n
- [ ] kubeconfig locally on Ninkear workstation

---

## Security & Credentials

This repository is **public** and follows security best practices:

- **Secrets excluded from git**: `.env` files, `credentials.auto.tfvars`, `*.tfstate`, and `homelab-ca/` are in `.gitignore`.
- **Example files committed**: `.env.example` documents expected variables.
- **Placeholder values**: Terraform credentials use `CHANGE_ME_*` placeholders.

---

## License

See [LICENSE](LICENSE).
