resource "proxmox_virtual_environment_container" "nextcloud" {
  node_name    = "Proxmox"
  vm_id        = 102
  unprivileged = true

  initialization {
    hostname = "nextcloud"
    ip_config {
      ipv4 {
        address = "192.168.1.120/24"
        gateway = "192.168.1.1"
      }
    }
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 2048
  }

  disk {
    datastore_id = "local-lvm"
    size         = 30
  }

  network_interface {
    name     = "eth0"
    bridge   = "vmbr0"
    firewall = true
  }

  operating_system {
    template_file_id = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
    type             = "debian"
  }

  lifecycle {
    ignore_changes = [operating_system, initialization[0].dns, console, features]
  }
}
