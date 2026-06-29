# Root module. Provisions Talos VMs on Proxmox using the talos-vm module.
# talos_iso_file_id is defined in terraform.tfvars.
# Node-level bootstrap flag controls ISO attachment: true = install, false = disk-only.

module "talos_vm" {
  source = "./modules/talos-vm"

  for_each = local.talos_nodes

  node_name                 = each.value.proxmox_node
  vm_name                   = each.key
  vm_id                     = each.value.vm_id
  cores                     = each.value.cores
  memory                    = each.value.memory
  disk_gb                   = each.value.disk_gb
  persistent_volume_disk_gb = lookup(each.value, "persistent_volume_disk_gb", 0)
  object_storage_disk_gb    = lookup(each.value, "object_storage_disk_gb", 0)
  bootstrap                 = lookup(each.value, "bootstrap", false)
  tags                      = each.value.tags
  datastore_id              = var.vm_datastore_id
  iso_file_id               = var.talos_iso_file_id
  bridge                    = var.vm_bridge
  public_vlan_id            = each.value.role == "worker" ? var.vm_public_vlan_id : null
  started                   = true
  boot_order                = var.talos_boot_order
}
