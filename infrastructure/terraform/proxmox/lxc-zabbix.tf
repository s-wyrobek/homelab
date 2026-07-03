resource "proxmox_virtual_environment_container" "ProxmoxZabbix" {
  node_name    = "Proxmox"
  vm_id        = 105
  unprivileged = true

  initialization {
    hostname = "zabbix"
    ip_config {
      ipv4 {
        address = "192.168.1.150/24"
        gateway = "192.168.1.1"
      }
    }
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 6
  }

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = "BC:24:11:CA:46:CB"  # sztywno, żeby import nie próbował zmieniać MAC
  }

  features {
    nesting = true
    keyctl  = true
  }

  operating_system {
    template_file_id = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
    type             = "debian"
  }

  lifecycle {
    ignore_changes = [
      operating_system,
      initialization[0].dns,
      console,
      features,
      description,  # community-script HTML blob — nie ma sensu tego trzymać w .tf
      tags,
    ]
  }
}	
