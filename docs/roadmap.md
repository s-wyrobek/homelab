# Roadmap

Phased plan for the homelab. Each phase has a concrete goal and an exit criterion —
"done" should mean something I can demo, not just "configured once".

---

## Phase 0 — Foundation (✅ done)

- [x] Proxmox VE 9.x installed and tuned on the Ryzen 5 3400G host
- [x] LAN segmented behind the managed L2 switch
- [x] Static IPs + DHCP reservations for all infrastructure hosts
- [x] First VM (`debian-01`) and first LXC templates working

**Exit criterion.** Any service can be spun up as a VM or LXC in minutes.

---

## Phase 1 — Network services (✅ done)

- [x] AdGuard Home LXC with DoH upstream + DNSSEC
- [x] LAN-wide filtering via DHCP-advertised DNS
- [x] `.home` TLD with DNS rewrites for internal services
- [x] First app stack: Nextcloud + MariaDB via Docker Compose

**Exit criterion.** Every device on the LAN resolves `.home` names and is filtered.

---

## Phase 2 — Reverse proxy + TLS (✅ done)

- [x] Nginx LXC fronting internal services (192.168.1.130)
- [x] Custom internal CA (local CA, wildcard `*.home`)
- [x] TLS certificates issued for every `.home` service
- [x] Workstation + browsers trust the internal CA
- [x] All `.home` services accessible over HTTPS on standard ports

**Exit criterion.** `https://dysk.home` and every other `.home` service works in any
browser with no warnings.

---

## Phase 3 — Remote access (✅ done)

- [x] WireGuard server in a dedicated LXC (192.168.1.140, wg-easy)
- [x] Per-device peer configs (workstation, phone)
- [x] Split tunnel: only `192.168.1.0/24` routed through VPN

**Exit criterion.** I can reach the lab from anywhere using only WireGuard, never
by exposing services to the internet.

---

## Phase 4 — Orchestration (✅ done)

- [x] k3s single-node cluster on `debian-01` VM
- [x] Traefik as Ingress controller (bundled with k3s)
- [x] Helm used for all service deployments (Grafana, Prometheus, n8n, Homepage)
- [x] Ingress manifests committed to repo (`k3s/`)

**Exit criterion.** A new app is deployed to k3s by committing manifests, not by
SSHing anywhere.

---

## Phase 5 — Observability (✅ done)

- [x] Prometheus + Node Exporter deployed via Helm
- [x] Grafana deployed via Helm, reachable at `grafana.home`
- [x] Traefik and node metrics scraped

**Exit criterion.** Host and cluster metrics are visible in Grafana dashboards.

---

## Phase 6 — Automation (✅ done)

- [x] Terraform provider for Proxmox: dns LXC declared in code (bpg/proxmox)
- [x] Ansible inventory for all 4 LXC containers
- [x] Ansible playbooks: `apt-upgrade.yaml`, `services-check.yaml`

**Exit criterion.** Infrastructure changes go through code, not manual SSH sessions.

---

## Phase 7 — Cloud integration (🔄 in progress)

- [x] LocalStack AWS emulator running on dedicated headless node (T490, .23)
- [x] S3, Lambda, IAM, DynamoDB, SQS, EC2, Kinesis enabled
- [x] Accessible via `awslocal` CLI and web GUI
- [ ] AWS CLI exercises on LocalStack (S3, Lambda, IAM, DynamoDB)
- [ ] Terraform for LocalStack resources
- [ ] Off-site encrypted backups to S3 (restic)

**Exit criterion.** AWS CLI workflows (create bucket, deploy lambda, put item) run
against LocalStack without touching real AWS.

---

## In progress 🔄

- GitLab CI/CD pipeline for this repository
- Wake-on-LAN for Proxmox host and LocalStack node
- Fix Homepage API widgets (Grafana, Prometheus, WireGuard data sources)
- Grafana dashboards with curated Prometheus metrics

---

## Cross-cutting items

These are not phases but they apply continuously:

- Secrets management — move from `.env` files to SOPS or Vault.
- Documentation — every service gets a README in this repo, kept in sync with reality.
- Reviews — revisit ADRs in [docs/decisions.md](decisions.md) when a phase ends.
