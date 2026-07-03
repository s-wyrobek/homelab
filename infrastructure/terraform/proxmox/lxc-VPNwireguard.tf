resource "proxmox_virtual_environment_container" "VPNwireguard" {
  node_name    = "Proxmox"
  vm_id        = 104
  unprivileged = true

  initialization {
    hostname = "VPNwireguard"
    ip_config {
      ipv4 {
        address = "192.168.1.140/24"
        gateway = "192.168.1.1"
      }
    }
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 256
    swap      = 256
  }

  disk {
    datastore_id = "local-lvm"
    size         = 4
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


