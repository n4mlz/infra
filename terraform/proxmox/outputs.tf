# Output values for provisioned Talos nodes.

output "talos_nodes" {
  value = {
    for name, vm in module.talos_vm : name => {
      vm_id = vm.vm_id
      name  = vm.name
    }
  }
}
