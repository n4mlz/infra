# Local values defining Talos node specifications.
# Contains control-plane and worker node configurations.

locals {
  talos_nodes = {
    "cp-01" = {
      proxmox_node = var.proxmox_node_name
      vm_id        = 3101
      role         = "controlplane"
      cores        = 1
      memory       = 8192
      disk_gb      = 32
      bootstrap    = false
      tags         = ["talos", "k8s", "control-plane"]
    }
    "cp-02" = {
      proxmox_node = var.proxmox_node_name
      vm_id        = 3102
      role         = "controlplane"
      cores        = 1
      memory       = 8192
      disk_gb      = 32
      bootstrap    = false
      tags         = ["talos", "k8s", "control-plane"]
    }
    "cp-03" = {
      proxmox_node = var.proxmox_node_name
      vm_id        = 3103
      role         = "controlplane"
      cores        = 1
      memory       = 8192
      disk_gb      = 32
      bootstrap    = false
      tags         = ["talos", "k8s", "control-plane"]
    }
    "wk-01" = {
      proxmox_node              = var.proxmox_node_name
      vm_id                     = 3201
      role                      = "worker"
      cores                     = 1
      memory                    = 4096
      disk_gb                   = 32
      persistent_volume_disk_gb = 256
      object_storage_disk_gb    = 256
      bootstrap                 = false
      tags                      = ["talos", "k8s", "worker", "storage"]
    }
    "wk-02" = {
      proxmox_node              = var.proxmox_node_name
      vm_id                     = 3202
      role                      = "worker"
      cores                     = 1
      memory                    = 4096
      disk_gb                   = 32
      persistent_volume_disk_gb = 256
      object_storage_disk_gb    = 256
      bootstrap                 = false
      tags                      = ["talos", "k8s", "worker", "storage"]
    }
    "wk-03" = {
      proxmox_node              = var.proxmox_node_name
      vm_id                     = 3203
      role                      = "worker"
      cores                     = 1
      memory                    = 4096
      disk_gb                   = 32
      persistent_volume_disk_gb = 256
      object_storage_disk_gb    = 256
      bootstrap                 = false
      tags                      = ["talos", "k8s", "worker", "storage"]
    }
    "wk-04" = {
      proxmox_node              = var.proxmox_node_name
      vm_id                     = 3204
      role                      = "worker"
      cores                     = 1
      memory                    = 4096
      disk_gb                   = 32
      persistent_volume_disk_gb = 256
      object_storage_disk_gb    = 256
      bootstrap                 = false
      tags                      = ["talos", "k8s", "worker", "storage"]
    }
  }
}
