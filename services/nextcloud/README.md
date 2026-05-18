# Nextcloud

Self-hosted file sync, calendar, and contacts. Runs on the `nextcloud` LXC
(`192.168.1.120`) using Docker Compose, with MariaDB as the backing database.

Accessed locally at **http://nextcloud.home:8080** (TLS via reverse proxy is on the roadmap).

---

## Stack

| Component  | Image / Version       | Role                         |
|------------|-----------------------|------------------------------|
| Nextcloud  | `nextcloud:stable`    | Web app + sync server        |
| MariaDB    | `mariadb:11`          | Application database         |
| Docker     | Engine 24+            | Container runtime in the LXC |

Both containers are defined in [docker-compose.yml](docker-compose.yml).
Secrets and tunables live in `.env` (see [.env.example](.env.example)).

---

## Layout

```
services/nextcloud/
├── README.md
├── docker-compose.yml
└── .env.example          # copy to .env and fill in secrets
```

Persistent data is kept in named Docker volumes:

| Volume               | Purpose                                |
|----------------------|----------------------------------------|
| `nextcloud_data`     | App data (files, config, apps)         |
| `mariadb_data`       | Database files                         |

---

## Installation

Assuming a fresh Debian 12 LXC with Docker installed:

```bash
# 1. clone this repo on the LXC (or copy the folder)
git clone https://github.com/s-wyrobek/homelab.git
cd homelab/services/nextcloud

# 2. prepare environment file
cp .env.example .env
# edit .env and set strong values for:
#   MYSQL_ROOT_PASSWORD
#   MYSQL_PASSWORD
#   NEXTCLOUD_ADMIN_PASSWORD

# 3. bring up the stack
docker compose up -d

# 4. follow logs until Nextcloud is initialized
docker compose logs -f nextcloud
```

First boot performs the schema setup automatically using the values from `.env`.
After that, the admin user defined in `NEXTCLOUD_ADMIN_USER` can log in.

---

## Access

| Endpoint              | URL                                  |
|-----------------------|--------------------------------------|
| Web UI (current)      | `http://nextcloud.home:8080`         |
| Web UI (planned)      | `https://nextcloud.home` (via Nginx) |
| LAN IP                | `192.168.1.120`                      |

`nextcloud.home` is resolved by AdGuard Home through a DNS rewrite — see
[services/dns/README.md](../dns/README.md).

The `trusted_domains` array in `config/config.php` is set so `nextcloud.home` is
accepted as a valid host.

---

## Operations

- **Updates**: `docker compose pull && docker compose up -d`. Always snapshot the LXC
  first.
- **Backup**: dump the database and copy the `nextcloud_data` volume.
  ```bash
  # Encrypted-at-rest backup recommended — pipe through gpg or use restic
  docker compose exec db mariadb-dump -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE}" \
    | gzip > /var/backups/nextcloud-$(date +%F).sql.gz
  ```
  Off-host backups to S3-compatible storage are planned.
- **Logs**: `docker compose logs -f nextcloud`.

---

## TODO

- [ ] Put Nginx in front (proxy `https://nextcloud.home` → `:8080`)
- [ ] Issue an internal TLS certificate (custom CA)
- [ ] Enable Redis for file locking and caching
- [ ] Configure cron via systemd timer instead of the in-app `AJAX` job
- [ ] Off-site encrypted backups (restic → S3)
- [ ] Move from local volumes to a dedicated dataset once storage is reorganized
