# Nginx reverse proxy (LXC 103, 192.168.1.103)

Reverse proxy dla usług `.home`, terminacja TLS certyfikatem `*.home` z Vault PKI
(`/etc/nginx/ssl/homelab.{crt,key}`, odnawiany przez `scripts/renew-nginx-cert.sh`).

| Vhost | Backend |
|---|---|
| `dash.home`, `homepage.home` | Homepage — 192.168.1.108:3000 |
| `dysk.home` | Nextcloud — 192.168.1.102:8080 |
| `floci.home`, `localstack.home` | Floci — 192.168.1.107:4566 |
| `vault.home` | Vault — 192.168.1.106:8200 |
| `zabbix.home` | Zabbix — 192.168.1.105 |

`proxmox.home` i usługi k3s (grafana/prometheus/n8n/traefik-k3s) idą z AdGuarda
bezpośrednio do hostów, z pominięciem Nginx.

## Domyślne vhosty
- port 80: `default` z Debiana (`default_server`, strona 404),
- port 443: [`00-default-443.conf`](sites-available/00-default-443.conf) —
  `ssl_reject_handshake on`, więc nazwy bez własnego vhosta nie lądują
  w pierwszym pliku z listy (wcześniej był to Floci).
