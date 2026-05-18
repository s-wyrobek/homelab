# Architecture Decision Records

Short notes on the non-obvious choices made in this lab.
Format: lightweight ADR — context, decision, consequences. New entries are appended;
old ones are kept even after they are superseded.

---

## ADR-0001 — Use Proxmox VE as the hypervisor

- **Status**: Accepted
- **Date**: 2025-09

**Context.** The host is a single Ryzen 5 3400G box that needs to run both full Linux
VMs (Docker host, future k3s nodes) and very small single-purpose services (DNS,
Nextcloud). A bare-metal Debian install with libvirt was an option, as was ESXi.

**Decision.** Use Proxmox VE 9.x.

**Why.**
- First-class support for both KVM (VMs) and LXC (containers) under one UI.
- Snapshots, backups, and a clustering path without paying for licenses.
- Active Debian-based ecosystem; familiar tooling underneath.
- LXC keeps single-service workloads cheap (≤ 100 MB RAM each).

**Consequences.** Lab is tied to Proxmox conventions (vmid ranges, storage names).
Provisioning will eventually be automated with Terraform's Proxmox provider.

---

## ADR-0002 — LXC for single-purpose services, VM for Docker

- **Status**: Accepted
- **Date**: 2025-10

**Context.** Each service could be a VM, an LXC, or a Docker container on a single VM.

**Decision.**
- Single-purpose, low-resource services → **LXC** (DNS today, reverse proxy and
  WireGuard later).
- Anything Docker-based, or anything that needs a full kernel and isolation →
  **VM** (`debian-01`).

**Why.** LXC has near-zero overhead and is trivial to back up, which fits services
like AdGuard Home perfectly. Docker inside LXC is possible but adds friction
(`keyctl`, nesting, AppArmor); a VM is the path of least surprise.

**Consequences.** Two operational patterns to maintain (LXC + VM), but each is
simpler than the all-in-one alternative.

---

## ADR-0003 — AdGuard Home as the LAN resolver

- **Status**: Accepted
- **Date**: 2025-10

**Context.** The lab needs a local resolver that supports filtering and encrypted
upstreams. Candidates: Pi-hole, AdGuard Home, Unbound + Blocky/dnsmasq.

**Decision.** AdGuard Home in a dedicated LXC.

**Why.** Built-in DoH upstream and DNSSEC, single Go binary, one YAML config file,
clean per-client controls. See the comparison in
[services/dns/README.md](../services/dns/README.md).

**Consequences.** All clients are pointed at one IP — that LXC is now a hard
dependency for network usability. A secondary resolver (or a quick fallback plan)
is on the roadmap.

---

## ADR-0004 — Blocking mode set to REFUSED

- **Status**: Accepted
- **Date**: 2025-10

**Context.** AdGuard Home can answer blocked queries with `NXDOMAIN`, `null`, a
custom IP, or `REFUSED`.

**Decision.** Use `REFUSED`.

**Why.** Apps and browsers stop retrying immediately on `REFUSED`, while `NXDOMAIN`
or `0.0.0.0` sometimes causes long page hangs while clients wait for a timeout.
Faster failure = better perceived performance on the LAN.

**Consequences.** A handful of apps treat `REFUSED` as a hard DNS error and log it
loudly. Acceptable trade-off.

---

## ADR-0005 — `.home` as the internal TLD

- **Status**: Accepted
- **Date**: 2025-10

**Context.** Internal services need stable names. Options were `.lan`, `.local`
(reserved for mDNS), `.internal`, or a real owned domain with split-horizon DNS.

**Decision.** Use `.home`, resolved by AdGuard Home rewrites only on the LAN.

**Why.** Short, intuitive, and not in conflict with public TLDs that matter today.
A real owned domain is overkill while nothing is exposed publicly.

**Consequences.** If `.home` is ever delegated as a real TLD by ICANN, the lab
will have to rename. Cheap to do; treated as acceptable risk.

---

## ADR-0006 — Docker Compose for application stacks (for now)

- **Status**: Accepted, will be revisited when k3s lands
- **Date**: 2025-11

**Context.** Nextcloud (and future apps) need a deployable, reproducible format.
The end state for the lab is a k3s cluster, but it is not built yet.

**Decision.** Use Docker Compose on `debian-01` and per-service LXCs for now.
Compose files live in this repo alongside their `.env.example`.

**Why.** Compose is the smallest reproducible unit that already covers the current
needs. Manifests will be ported to k3s later, not rewritten from scratch.

**Consequences.** Two deployment models will coexist during the migration to k3s.
ADR will be superseded when the cluster is the primary target.

---

## ADR-0007 — Secrets stay out of git, `.env.example` stays in

- **Status**: Accepted
- **Date**: 2025-11

**Context.** The repo is intended to be public (portfolio).

**Decision.**
- All real secrets live in `.env` files, which are gitignored.
- Each service ships an `.env.example` with placeholder values and comments.
- Long-term, secrets will move to a dedicated tool (planned: SOPS or Vault, see
  [roadmap](roadmap.md)).

**Consequences.** Anyone cloning the repo has to populate `.env` before
`docker compose up`. Acceptable and explicitly documented in each README.
