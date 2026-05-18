# AdGuard Home

Network-wide DNS resolver and ad/tracker blocker for the lab.
Runs in a dedicated LXC container (`dns`, `192.168.1.110`).

It is the single DNS server announced by DHCP, so every client on the LAN — wired or
Wi-Fi — uses it transparently.

---

## Why AdGuard Home (and not Pi-hole)

Both work. AdGuard Home was picked for a few concrete reasons:

| Aspect                  | AdGuard Home              | Pi-hole                          |
|-------------------------|---------------------------|----------------------------------|
| Encrypted upstream      | Built-in DoH / DoT / DoQ  | Needs `cloudflared`/`stubby`     |
| DNSSEC validation       | Toggle in the UI          | Possible, more setup             |
| Per-client rules        | Native, in the UI         | CLI / groups via web UI          |
| Single binary           | Yes (Go)                  | dnsmasq + lighttpd + PHP + scripts|
| Config as a file        | One YAML                  | Several files across services    |
| LXC footprint           | ~30–50 MB RAM             | Larger, more moving parts        |

The deciding factors were the **integrated DoH upstream** and the **single-binary,
single-config** model, which fits the "small LXC, easy to back up and reproduce" pattern
used elsewhere in the lab.

---

## Installation (LXC)

The container is a minimal Debian 12 LXC on Proxmox. AdGuard Home is installed from
the official script:

```bash
# inside the dns LXC
apt update && apt install -y curl ca-certificates
curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh \
  | sh -s -- -v
```

The installer creates a systemd unit (`AdGuardHome.service`) and exposes the web UI
on port 3000 (initial setup), then port 80 once configured.

---

## Configuration

Effective settings (configured through the web UI, persisted in
`/opt/AdGuardHome/AdGuardHome.yaml`):

- **Listen on**: `0.0.0.0:53` (UDP+TCP)
- **Upstream DNS**: `https://dns.cloudflare.com/dns-query` (DoH)
- **Bootstrap DNS**: `1.1.1.1`, `1.0.0.1`
- **DNSSEC**: enabled
- **Blocking mode**: `REFUSED`
  - clients get an immediate `REFUSED` response for blocked names
  - faster failure than `NXDOMAIN` for blocked trackers, no broken page timeouts
- **Cache size**: 32 MB
- **Query log**: enabled, 24 h retention
- **Statistics**: 7 days

> The web UI is reachable at `http://dns.home` (alias for `192.168.1.110`).
> No external exposure — admin access is LAN-only.

---

## Blocklists

| List                              | Purpose                          |
|-----------------------------------|----------------------------------|
| HaGeZi Pro                        | General ads + tracking, curated  |
| OISD (big)                        | Broad coverage, low breakage     |
| Peter Lowe's list                 | Classic ad/tracker list          |
| CERT Polska — warning list        | Phishing/malware (PL CERT feed)  |
| URLHaus (abuse.ch)                | Active malware URLs              |

Lists are updated on AdGuard's default schedule. Allowlist is kept short and reviewed
when a legitimate site breaks.

---

## DNS rewrites

`.home` is the internal TLD. Rewrites are configured in AdGuard Home so that
internal names resolve to LAN IPs without touching any upstream.

| Name              | Answer           |
|-------------------|------------------|
| pve.home          | 192.168.1.100    |
| debian-01.home    | 192.168.1.24     |
| dns.home          | 192.168.1.110    |
| nextcloud.home    | 192.168.1.120    |

New services get a rewrite added the moment they get a static IP.

---

## DHCP integration

DHCP is still handled by the router. It advertises
`192.168.1.110` as the only DNS server, which forces all clients through AdGuard.

Switching DHCP to AdGuard Home is on the table but not pressing — the current setup
already gives full visibility and filtering.

---

## Operations

- **Backup**: `/opt/AdGuardHome/AdGuardHome.yaml` is the only meaningful state. It is
  copied off the LXC after non-trivial changes.
- **Updates**: AdGuard Home self-update via the UI; LXC packages via `apt` weekly.
- **Monitoring**: query log + stats in the UI. Prometheus exporter planned (see
  [docs/roadmap.md](../../docs/roadmap.md)).

---

## Troubleshooting

| Symptom                                     | First check                                          |
|---------------------------------------------|------------------------------------------------------|
| Client cannot resolve anything              | `systemctl status AdGuardHome` on `dns`              |
| A site is broken on every device            | Query log → which list blocked it → add to allowlist |
| Slow first lookup                           | Cache empty after restart, normal                    |
| `.home` name not resolving                  | Check the DNS rewrite entry exists and is exact      |
