resource "proxmox_virtual_environment_vm" "debian_01" {
  node_name = "Proxmox"
  vm_id     = 100
  name      = "deian-01"

  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "virtio0"
    size         = 20
  }

  network_device {
    bridge   = "vmbr0"
    firewall = true
  }

  operating_system {
    type = "l26"
  }

  lifecycle {
    ignore_changes = all
  }
}
