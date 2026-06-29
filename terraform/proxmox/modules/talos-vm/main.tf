# Reusable module for creating a Talos VM on Proxmox.
# scsi0: system disk. scsi1: persistent volume disk. scsi2: object storage disk.
# Set bootstrap=true for initial ISO installation (attaches ISO, enables cdrom boot, does not start).
# bootstrap=false (default): disk boot only, empty CD-ROM, starts automatically.

resource "proxmox_virtual_environment_vm" "this" {
  name        = var.vm_name
  node_name   = var.node_name
  vm_id       = var.vm_id
  description = "Talos Kubernetes node managed by Terraform"
  tags        = var.tags

  machine = "q35"

  started    = var.bootstrap ? false : var.started
  boot_order = var.bootstrap ? ["ide2", "scsi0"] : var.boot_order

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

  dynamic "disk" {
    for_each = var.persistent_volume_disk_gb > 0 ? { scsi1 = var.persistent_volume_disk_gb } : {}
    content {
      datastore_id = var.datastore_id
      interface    = disk.key
      size         = disk.value
      file_format  = "raw"
      discard      = "on"
      serial       = "${var.vm_name}-pv-0"
    }
  }

  dynamic "disk" {
    for_each = var.object_storage_disk_gb > 0 ? { scsi2 = var.object_storage_disk_gb } : {}
    content {
      datastore_id = var.datastore_id
      interface    = disk.key
      size         = disk.value
      file_format  = "raw"
      discard      = "on"
      serial       = "${var.vm_name}-object-0"
    }
  }

  cdrom {
    file_id   = var.bootstrap ? var.iso_file_id : "none"
    interface = "ide2"
  }

  network_device {
    bridge = var.bridge
  }

  dynamic "network_device" {
    for_each = var.public_vlan_id != null ? [1] : []
    content {
      bridge  = var.bridge
      vlan_id = var.public_vlan_id
    }
  }

  agent {
    enabled = true
    timeout = "30s"
  }

  operating_system {
    type = "l26"
  }

  serial_device {}
}
