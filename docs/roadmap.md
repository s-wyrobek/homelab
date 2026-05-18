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

## Phase 2 — Reverse proxy + TLS (🟡 in progress)

- [ ] Nginx LXC fronting internal services
- [ ] Custom internal CA (smallstep `step-ca` or `cfssl`)
- [ ] TLS certificates issued for every `.home` service
- [ ] Workstation + phones trust the internal CA
- [ ] Switch `nextcloud.home` to HTTPS on standard ports

**Exit criterion.** `https://nextcloud.home` works in any browser on any device
with no warnings.

---

## Phase 3 — Remote access (planned)

- [ ] WireGuard server on Proxmox (or a dedicated LXC)
- [ ] Per-device peer configs (laptop, phone)
- [ ] Split tunnel: only `192.168.1.0/24` routed
- [ ] Document the recovery path if the tunnel is broken

**Exit criterion.** I can reach the lab from anywhere using only WireGuard, never
by exposing services to the internet.

---

## Phase 4 — Orchestration (planned)

- [ ] k3s cluster (1 control plane + 2 workers, VMs on Proxmox)
- [ ] Migrate Nextcloud (or a sample app) to k3s manifests
- [ ] Internal container registry or pre-built images on a private repo
- [ ] Backups for cluster state (etcd snapshots / `k3s-etcd-snapshots`)

**Exit criterion.** A new app is deployed to k3s by committing manifests, not by
SSHing anywhere.

---

## Phase 5 — Observability (planned)

- [ ] Prometheus + Node Exporter on the host and guests
- [ ] AdGuard Home metrics scraped
- [ ] cAdvisor / kube-state-metrics inside k3s
- [ ] Grafana with curated dashboards (host, network, DNS, apps)
- [ ] Alerts: disk pressure, AdGuard down, certs expiring < 14 days

**Exit criterion.** When something breaks, the dashboard or an alert shows it
before I notice on my own.

---

## Phase 6 — Automation (planned)

- [ ] Terraform provider for Proxmox: VMs and LXCs declared in code
- [ ] Ansible playbooks for post-provisioning (base packages, users, SSH, Docker)
- [ ] Role per service (`adguard`, `nginx`, `nextcloud`, `wireguard`)
- [ ] CI workflow (GitHub Actions) to lint/validate the IaC

**Exit criterion.** I can wipe a VM and rebuild it identically with one command.

---

## Phase 7 — Cloud integration (planned)

- [ ] Off-site encrypted backups to S3 (restic)
- [ ] Hosted Zone in Route 53 for a real domain (split-horizon with `.home`)
- [ ] Small workload on AWS (EC2 or Fargate) reachable from the lab over WireGuard
- [ ] Cost dashboard and budget alerts

**Exit criterion.** The lab survives the loss of the physical host: data is
recoverable and at least one service can be brought up in AWS quickly.

---

## Cross-cutting items

These are not phases but they apply continuously:

- Secrets management — move from `.env` files to SOPS or Vault before phase 4.
- Documentation — every service gets a README in this repo, kept in sync with
  reality.
- Reviews — revisit ADRs in [docs/decisions.md](decisions.md) when a phase ends.
