resource "proxmox_virtual_environment_container" "floci" {
  node_name    = "Proxmox"
  vm_id        = 107
  unprivileged = true

  initialization {
    hostname = "Cloud-Floci"
    ip_config {
      ipv4 {
        address = "192.168.1.107/24"
        gateway = "192.168.1.1"
      }
    }
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 1024
  }

  disk {
    datastore_id = "local-lvm"
    size         = 12
  }

  network_interface {
    name     = "eth0"
    bridge   = "vmbr0"
    firewall = true
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
    ignore_changes = [operating_system, initialization[0].dns, console, features]
  }
}
