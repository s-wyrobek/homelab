# Homelab

Personal DevOps homelab built on **Proxmox VE**.
Used as a learning environment for infrastructure, networking, automation, and self-hosted services.

> Author: **Szymon Wyrobek** ([@s-wyrobek](https://github.com/s-wyrobek))
> Status: actively developed

---

## Stack

| Layer            | Technology                                                               |
| ----------------- | ------------------------------------------------------------------------ |
| Hypervisor        | Proxmox VE 9.1                                                           |
| Guest OS (VM)     | Debian 12                                                                |
| Containers (LXC)  | Debian 12 templates                                                      |
| Orchestration     | k3s (single-node)                                                       |
| Ingress           | Traefik (k3s) + Nginx (LXC reverse proxy)                                |
| DNS               | AdGuard Home (on Raspberry Pi bastion) + NetBird nameserver group        |
| Remote access     | NetBird mesh VPN (Raspberry Pi routing peer) + WireGuard/wg-easy (LAN)   |
| Monitoring        | Zabbix (Proxmox + LXC), Grafana + Prometheus (k3s)                      |
| IaC               | Terraform (`bpg/proxmox` provider), Ansible                              |
| Secrets / PKI     | HashiCorp Vault (Raft, Shamir 3-of-5, PKI backend for `*.home` certs)    |
| CI/CD             | GitHub Actions (gitleaks, Trivy IaC scan, ansible-lint) + self-hosted GitLab Runner |
| Cloud emulation   | Cloud-Floci (open-source LocalStack replacement, MIT, port 4566)        |
| Workstation       | Ninkear A15 Plus — Ubuntu 26.04, zsh + OhMyZsh + Starship               |

> Dropped LocalStack Pro in favor of **Cloud-Floci** (MIT-licensed LocalStack replacement) to avoid the Pro-only persistence paywall.

---

## Infrastructure

| Host           | Type | IP                       | Role                                          | OS             |
| -------------- | ---- | ------------------------ | ---------------------------------------------- | -------------- |
| Proxmox        | Host | 192.168.1.252            | Proxmox VE hypervisor                          | Proxmox VE 9.1 |
| Ninkear        | WS   | 192.168.1.22              | Primary workstation                            | Ubuntu 26.04   |
| T490           | WS   | 192.168.1.23              | Headless spare node (LocalStack retired)       | EndeavourOS    |
| debian-01      | VM   | 192.168.1.24              | k3s cluster (VMID 100)                         | Debian 12      |
| Raspberry Pi 4B| SBC  | 192.168.1.253             | NetBird routing peer + AdGuard Home (DNS)      | Raspberry Pi OS Lite |
| Disk-Nextcloud | LXC 102 | 192.168.1.102          | Nextcloud + MariaDB (Docker, :8080)            | Debian 12      |
| Proxy-Nginx    | LXC 103 | 192.168.1.103          | Nginx reverse proxy + TLS                      | Debian 12      |
| Monitor-Zabbix | LXC 105 | 192.168.1.105          | Zabbix monitoring server                       | Debian 12      |
| Secrets-Vault  | LXC 106 | 192.168.1.106          | HashiCorp Vault (PKI for `*.home`)             | Debian 12      |
| Cloud-Floci    | LXC 107 | 192.168.1.107          | Cloud-Floci (LocalStack replacement, :4566)    | Debian 12      |
| Dash-Homepage  | LXC 108 | 192.168.1.108          | Homepage dashboard (Docker, :3000)             | Debian 12      |

Hardware: AMD Ryzen 5 3400G, 16 GB RAM, single node.

> All LXC containers follow the `VMID = last IP octet` convention. The old `dns` (101) and `wireguard` (104) LXCs were retired — DNS moved to AdGuard on the Pi bastion, remote access to NetBird.

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
                          │
               ┌──────────▼───────────┐
               │ Raspberry Pi bastion  │  NetBird routing peer (100.99.79.192)
               │ 192.168.1.253         │  routes 192.168.1.0/24 to the NetBird mesh
               └───────────────────────┘
```

LAN: `192.168.1.0/24`
DNS: `192.168.1.253` (AdGuard Home on the Pi bastion)
Remote access: NetBird mesh (via Pi bastion)
TLS: Custom CA (`~/homelab-ca/ca.crt`) + Vault PKI role `homelab-dot-home`, explicit SANs per service

---

## Local domains (`.home`)

| Domain              | Target                             |
| ------------------- | ----------------------------------- |
| `proxmox.home`      | Proxmox UI (192.168.1.252:8006)     |
| `dns.home`          | AdGuard Home (Pi, 192.168.1.253)    |
| `dysk.home`         | Nextcloud                           |
| `grafana.home`      | Grafana (k3s)                       |
| `prometheus.home`   | Prometheus (k3s)                    |
| `n8n.home`          | n8n (k3s)                           |
| `traefik-k3s.home`  | Traefik dashboard (k3s)             |
| `homepage.home`     | Homepage dashboard (Docker, LXC)    |
| `zabbix.home`       | Zabbix monitoring                   |
| `vault.home`        | HashiCorp Vault UI                  |
| `floci.home`        | Cloud-Floci (LocalStack replacement)|

Most `.home` domains → AdGuard rewrite → Nginx LXC (192.168.1.103) → upstream service; k3s services (`grafana`, `prometheus`, `n8n`, `traefik-k3s`) point straight at debian-01 (192.168.1.24).
Resolved on the LAN directly, and off-LAN via the NetBird nameserver group (`home` → 192.168.1.253).

---

## K3s services (debian-01)

| Service    | Description                    |
| ---------- | ------------------------------- |
| Traefik    | Ingress controller              |
| Grafana    | Metrics dashboards               |
| Prometheus | Metrics collection                |
| n8n        | Workflow automation                |

> Homepage was migrated off k3s to a Docker container (LXC) — remove the old k3s Homepage release once confirmed unused.

---

## Cloud emulation (Floci, LXC 107)

AWS-compatible emulation via **Cloud-Floci** (open-source, MIT, replaces LocalStack Pro to avoid the persistence paywall). It speaks the LocalStack API, so existing tooling works unchanged.

- Endpoint: `http://192.168.1.107:4566` (also `https://floci.home` and the legacy `https://localstack.home` via Nginx)
- Data: Docker volume `floci-data` on LXC 107
- Bootstrap resources (S3, IAM, SQS, DynamoDB): [`services/floci/init-floci.sh`](services/floci/init-floci.sh) — idempotent

---

## CI/CD

GitHub Actions (`.github/workflows/security-scan.yml`):
- **gitleaks** — secret scanning, extended with custom rules in [`.gitleaks.toml`](.gitleaks.toml) for NetBird/Vault/Proxmox/WireGuard secrets
- **Trivy IaC scan** — Terraform misconfiguration scanning (`infrastructure/terraform/proxmox`); replaces the deprecated `tfsec-action`
- **ansible-lint** — lints `ansible/`
- **block-state-files** — fails the build if `terraform.tfstate*` is ever tracked

Self-hosted **GitLab Runner** (in an LXC, LAN access) also runs real `terraform plan` against the homelab for the separate GitLab.com project.

---

## Repository layout

```
.
├── README.md
├── .gitleaks.toml             # custom gitleaks rules (NetBird/Vault/Proxmox/WireGuard)
├── ansible/                   # Ansible playbooks
│   ├── inventory.yaml
│   ├── apt-upgrade.yaml
│   ├── configure-ninkear.yaml
│   └── services-check.yaml
├── docs/
│   ├── decisions.md
│   └── roadmap.md
├── infrastructure/
│   ├── proxmox/README.md
│   ├── network/README.md
│   └── terraform/             # Proxmox provisioning (bpg/proxmox)
├── k3s/                       # Kubernetes manifests
├── scripts/
│   ├── lab-up.sh              # Wake-on-LAN
│   └── lab-down.sh            # SSH poweroff
├── services/
│   ├── floci/                 # Cloud-Floci compose + init script (LXC 107)
│   ├── homepage/              # Homepage dashboard (LXC 108)
│   └── ...
└── workstation/
    └── setup.sh                # Ninkear bootstrap script
```

---

## Roadmap (summary — see [docs/roadmap.md](docs/roadmap.md) for the full phased plan)

- [x] Proxmox VE installed and tuned
- [x] AdGuard Home as local resolver (now on Raspberry Pi bastion)
- [x] Nextcloud + MariaDB
- [x] Nginx reverse proxy + custom TLS CA
- [x] WireGuard VPN (wg-easy)
- [x] k3s cluster (Traefik, Grafana, Prometheus, n8n)
- [x] Terraform — Proxmox provisioning (`bpg/proxmox`)
- [x] Ansible — workstation config + service health checks
- [x] Cloud-Floci — open-source LocalStack replacement (S3, IAM, SQS, DynamoDB)
- [x] Wake-on-LAN scripts
- [x] Zabbix monitoring (Proxmox VE by HTTP template)
- [x] HashiCorp Vault as PKI backend for `*.home` certs
- [x] NetBird mesh VPN via Raspberry Pi bastion (routing peer + DNS)
- [x] GitHub Actions CI (gitleaks, Trivy IaC scan, ansible-lint)
- [x] LXC renumbering (VMID = last IP octet), Terraform in sync with Proxmox
- [ ] Proxmox host IP renumbering (.100 → .252) — host, SSH config, AdGuard rewrite and Terraform done; DHCP reservation and `/etc/hosts` on the node still pending
- [ ] Fix `homepage.home` rewrite (points at k3s .24, Homepage now on LXC 108)
- [ ] Zabbix Agent2 on debian-01
- [ ] GitLab CI/CD pipeline (self-hosted runner exists, pipeline still WIP)

---

## License

[MIT](LICENSE)
