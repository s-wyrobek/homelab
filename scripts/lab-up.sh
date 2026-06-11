#!/bin/bash
set -euo pipefail


echo "WAKE UP HOMELAB..."

echo "Proxmox (192.168.1.100)..."
wakeonlan a8:a1:59:47:50:4b

echo "T490/LocalStack (192.168.1.23)..."
wakeonlan 98:fa:9b:1b:cb:3a

echo "Waiting for response..."
sleep 40

for host in 192.168.1.100 192.168.1.23; do
  echo -n "  $host "
  for i in $(seq 1 15); do
    if ping -c 1 -W 2 $host &>/dev/null; then
      echo " online"
      break
    fi
    echo -n "."
    sleep 3
  done
done

echo "HOMELAB ready"
