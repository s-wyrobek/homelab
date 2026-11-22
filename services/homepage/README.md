# Homepage

Dashboard labu. Działa jako kontener Docker na **LXC 108 `Dash-Homepage`**
(`192.168.1.108:3000`, SSH alias `dash-homepage`), katalog `~/homepage`.

Dostęp: **https://dash.home** (AdGuard → Nginx LXC 103 → `192.168.1.108:3000`).

## Pliki

| Plik | Na serwerze |
|------|-------------|
| `docker-compose.yml` | `~/homepage/docker-compose.yml` |
| `config/*.yaml` | `~/homepage/config/` |
| `.env.example` | wzór dla `~/homepage/.env` (prawdziwy `.env` nigdy nie trafia do gita) |

Hasła i tokeny w `config/services.yaml` są wyłącznie referencjami
`{{HOMEPAGE_VAR_*}}` — wartości siedzą w `.env` na serwerze.

## Wdrożenie zmian

```bash
scp config/*.yaml dash-homepage:homepage/config/
```

Homepage przeładowuje konfigurację sam, restart kontenera nie jest potrzebny.

## Legacy

`homepage-values.yaml` to stare wartości Helm z czasów, gdy Homepage działał
na k3s (debian-01, `192.168.1.24`). Zawiera IP sprzed renumeracji. Instancja
na k3s jest do wyłączenia — wtedy ten plik można usunąć.
