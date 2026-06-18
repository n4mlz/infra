# Root module. Provisions Talos VMs on Proxmox using the talos-vm module.
#
# Initial install (one-time):
#   tofu apply -var='talos_iso_file_id=local:iso/nocloud-amd64.iso' \
#     -var='talos_boot_order=["ide2","scsi0"]'
#
# Post-install (default):
#   tofu apply

module "talos_vm" {
  source = "./modules/talos-vm"

  for_each = local.talos_nodes

  node_name     = each.value.proxmox_node
  vm_name       = each.key
  vm_id         = each.value.vm_id
  cores         = each.value.cores
  memory        = each.value.memory
  disk_gb       = each.value.disk_gb
  tags          = each.value.tags
  datastore_id  = var.vm_datastore_id
  iso_file_id   = var.talos_iso_file_id
  bridge        = var.vm_bridge
  public_vlan_id = each.value.role == "worker" ? var.vm_public_vlan_id : null
  started       = true
  boot_order    = var.talos_boot_order
}
