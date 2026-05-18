# Proxmox VE

Single-node Proxmox VE 9.1 install running all lab workloads.
Acts as the hypervisor for both VMs (full Debian) and LXC containers (lightweight services).

---

## Hardware

| Component   | Spec                                  |
|-------------|---------------------------------------|
| CPU         | AMD Ryzen 5 3400G (4C / 8T, Zen+, APU)|
| RAM         | 16 GB DDR4                            |
| Storage     | Local SSD (LVM-thin) for VMs and LXC  |
| Network     | 1× Gigabit Ethernet to managed L2 switch |
| Form factor | Mini desktop, always-on               |

The Ryzen 5 3400G is a deliberate choice: the integrated GPU keeps the system bootable
without a discrete card, and the 4C/8T budget is plenty for the current workload mix.

---

## Software

- Proxmox VE **9.1**
- Debian 12 (Bookworm) as the base for both VMs and LXC templates
- Backups: scheduled vzdump to a local directory (off-site backup planned, see [roadmap](../../docs/roadmap.md))

---

## Access

| Endpoint     | Address                          | Notes                         |
|--------------|----------------------------------|-------------------------------|
| Web UI       | `https://192.168.1.100:8006`     | Admin only, root via PAM      |
| SSH          | `ssh root@192.168.1.100`         | Key-based auth (no passwords) |

Web UI access is restricted to the LAN. No port is exposed to the internet.
Remote access is planned through WireGuard, not by exposing the Proxmox UI.

---

## VMs and LXC

| ID  | Hostname    | Type | IP             | vCPU | RAM    | Role                       |
|-----|-------------|------|----------------|------|--------|----------------------------|
| 101 | debian-01   | VM   | 192.168.1.24   | 2    | 4 GB   | General-purpose Docker host|
| 110 | dns         | LXC  | 192.168.1.110  | 1    | 512 MB | AdGuard Home               |
| 120 | nextcloud   | LXC  | 192.168.1.120  | 2    | 2 GB   | Nextcloud + MariaDB        |

LXC is preferred for single-purpose services with a small footprint (DNS, web apps).
VMs are used where a full kernel is required (Docker host, future k3s nodes).

---

## Conventions

- Static IPs from `192.168.1.0/24` for all infrastructure hosts.
- DHCP reservations match the static configuration to avoid surprises.
- Hostnames are short and match the role (`dns`, `nextcloud`, `debian-01`).
- All hosts resolve `*.home` via the AdGuard Home instance.

---

## Maintenance notes

- Snapshots before any non-trivial upgrade.
- `apt update && apt upgrade` weekly on guests, monthly on the host.
- Subscription nag is suppressed; no enterprise repos are configured.
