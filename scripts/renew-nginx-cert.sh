#!/usr/bin/env bash
# Wystawia nowy certyfikat *.home z Vault PKI i instaluje go na Nginx (LXC 103).
#
# Wymaga: odpieczętowanego Vaulta oraz tokena z prawem do <PKI_PATH>/issue/<PKI_ROLE>.
# Token czytany z $VAULT_TOKEN albo pytany interaktywnie (nie jest nigdzie zapisywany).
#
#   ./scripts/renew-nginx-cert.sh            # domyślne SAN-y
#   PKI_TTL=168h ./scripts/renew-nginx-cert.sh   # krótszy certyfikat
set -euo pipefail

VAULT_ADDR="${VAULT_ADDR:-http://192.168.1.106:8200}"
PKI_PATH="${PKI_PATH:-pki}"
PKI_ROLE="${PKI_ROLE:-homelab-dot-home}"
PKI_TTL="${PKI_TTL:-720h}"           # = max_ttl roli homelab-dot-home
NGINX_HOST="${NGINX_HOST:-proxy-nginx}"
CERT_DIR="/etc/nginx/ssl"

COMMON_NAME="*.home"
ALT_NAMES="dash.home,homepage.home,dns.home,dysk.home,nextcloud.home,floci.home,localstack.home,nginx.home,proxmox.home,vault.home,zabbix.home"

sealed=$(curl -sf "$VAULT_ADDR/v1/sys/seal-status" | python3 -c 'import sys,json; print(json.load(sys.stdin)["sealed"])')
if [[ "$sealed" != "False" ]]; then
  echo "Vault jest zapieczętowany — najpierw: vault operator unseal (3 z 5 kluczy)." >&2
  exit 1
fi

if [[ -z "${VAULT_TOKEN:-}" ]]; then
  read -rsp "Vault token: " VAULT_TOKEN; echo
fi

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
chmod 700 "$workdir"

payload=$(python3 -c 'import json,sys; print(json.dumps({"common_name":sys.argv[1],"alt_names":sys.argv[2],"ttl":sys.argv[3]}))' \
  "$COMMON_NAME" "$ALT_NAMES" "$PKI_TTL")

curl -sS --fail-with-body -H "X-Vault-Token: $VAULT_TOKEN" -X POST \
  -d "$payload" "$VAULT_ADDR/v1/$PKI_PATH/issue/$PKI_ROLE" > "$workdir/resp.json" || {
  echo "Vault odrzucił żądanie:" >&2; python3 -c 'import sys,json; print(json.load(open(sys.argv[1])).get("errors"))' "$workdir/resp.json" >&2; exit 1; }
unset VAULT_TOKEN

python3 - "$workdir" <<'EOF'
import json, sys, os
d = sys.argv[1]
r = json.load(open(f"{d}/resp.json"))
for w in r.get("warnings") or []:
    print("Vault warning:", w)
data = r["data"]
chain = [data["certificate"]] + (data.get("ca_chain") or [data["issuing_ca"]])
open(f"{d}/homelab.crt", "w").write("\n".join(c.strip() for c in chain) + "\n")
fd = os.open(f"{d}/homelab.key", os.O_WRONLY | os.O_CREAT, 0o600)
os.write(fd, (data["private_key"].strip() + "\n").encode()); os.close(fd)
EOF
rm -f "$workdir/resp.json"

echo "Nowy certyfikat:"
openssl x509 -in "$workdir/homelab.crt" -noout -subject -issuer -enddate -ext subjectAltName

scp -q "$workdir/homelab.crt" "$workdir/homelab.key" "$NGINX_HOST:/tmp/"
ssh "$NGINX_HOST" "set -e
  ts=\$(date +%Y%m%d-%H%M%S)
  sudo cp $CERT_DIR/homelab.crt $CERT_DIR/homelab.crt.bak-\$ts
  sudo cp $CERT_DIR/homelab.key $CERT_DIR/homelab.key.bak-\$ts
  sudo install -m 644 -o root -g root /tmp/homelab.crt $CERT_DIR/homelab.crt
  sudo install -m 600 -o root -g root /tmp/homelab.key $CERT_DIR/homelab.key
  rm -f /tmp/homelab.crt /tmp/homelab.key
  if sudo nginx -t; then
    sudo systemctl reload nginx && echo 'nginx przeładowany'
  else
    echo 'nginx -t FAILED — przywracam poprzedni certyfikat' >&2
    sudo cp $CERT_DIR/homelab.crt.bak-\$ts $CERT_DIR/homelab.crt
    sudo cp $CERT_DIR/homelab.key.bak-\$ts $CERT_DIR/homelab.key
    exit 1
  fi"

echo "Sprawdzenie na żywo:"
sleep 2   # reload jest asynchroniczny — daj workerom chwilę na wymianę
echo | openssl s_client -connect 192.168.1.103:443 -servername dash.home 2>/dev/null \
  | openssl x509 -noout -enddate
