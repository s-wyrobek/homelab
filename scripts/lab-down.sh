#!/bin/bash
set -euo pipefail

echo "Closing lab..."

echo "Shutting down T490/LocalStack..."
ssh semen@192.168.1.23 "sudo poweroff" 2>/dev/null || echo "T490 unreachable"

echo "Shutting down Proxmox..."
ssh root@192.168.1.100 "poweroff" 2>/dev/null || echo "Proxmox unreachable"

echo "Lab successfuly down"
