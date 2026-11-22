resource "proxmox_virtual_environment_container" "homepage" {
  node_name    = "Proxmox"
  vm_id        = 108
  unprivileged = true

  initialization {
    hostname = "Dash-Homepage"
    ip_config {
      ipv4 {
        address = "192.168.1.108/24"
        gateway = "192.168.1.1"
      }
    }
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 1024
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 8
  }

  network_interface {
    name     = "eth0"
    bridge   = "vmbr0"
    firewall = true
  }

  features {
    nesting = true
  }

  operating_system {
    template_file_id = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
    type             = "debian"
  }

  lifecycle {
    ignore_changes = [operating_system, initialization[0].dns, console, features]
  }
}
