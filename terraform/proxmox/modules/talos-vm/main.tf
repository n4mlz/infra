# Reusable module for creating a Talos VM on Proxmox.
# The VM is created in a stopped state with Talos ISO attached.

resource "proxmox_virtual_environment_vm" "this" {
  name        = var.vm_name
  node_name   = var.node_name
  vm_id       = var.vm_id
  description = "Talos Kubernetes node managed by Terraform"
  tags        = var.tags

  machine = "q35"

  started = var.started

  cpu {
    cores = var.cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_gb
    file_format  = "raw"
  }

  cdrom {
    file_id   = var.iso_file_id
    interface = "ide2"
  }

  network_device {
    bridge = var.bridge
  }

  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  serial_device {}
}
