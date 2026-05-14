# Root module. Provisions Talos VMs on Proxmox using the talos-vm module.

module "talos_vm" {
  source = "./modules/talos-vm"

  for_each = local.talos_nodes

  node_name    = each.value.proxmox_node
  vm_name      = each.key
  vm_id        = each.value.vm_id
  cores        = each.value.cores
  memory       = each.value.memory
  disk_gb      = each.value.disk_gb
  tags         = each.value.tags
  datastore_id = var.vm_datastore_id
  iso_file_id  = var.talos_iso_file_id
  bridge       = var.vm_bridge
  started      = true
}
