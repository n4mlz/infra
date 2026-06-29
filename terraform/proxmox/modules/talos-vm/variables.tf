# Input variables for the talos-vm module.

variable "node_name" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "vm_id" {
  type = number
}

variable "tags" {
  type = list(string)
}

variable "cores" {
  type = number
}

variable "memory" {
  type = number
}

variable "disk_gb" {
  type = number
}

variable "datastore_id" {
  type = string
}

variable "iso_file_id" {
  type        = string
  default     = "none"
  description = "Proxmox file ID of Talos ISO. 'none' for empty CD-ROM."
}

variable "bridge" {
  type = string
}

variable "started" {
  type        = bool
  default     = false
  description = "Whether the VM should be started after creation"
}

variable "boot_order" {
  type        = list(string)
  default     = ["scsi0"]
  description = "Boot order for the VM. Default is disk-only."
}

variable "public_vlan_id" {
  type        = number
  default     = null
  description = "VLAN ID for the optional public NIC on gateway workers. Only set for gateway workers."
}

variable "persistent_volume_disk_gb" {
  type        = number
  default     = 0
  description = "Size in GiB for a dedicated persistent volume disk (scsi1). Set to 0 to skip."
}

variable "object_storage_disk_gb" {
  type        = number
  default     = 0
  description = "Size in GiB for a dedicated object storage disk (scsi2). Set to 0 to skip."
}

variable "bootstrap" {
  type        = bool
  default     = false
  description = "Attach Talos ISO and set cdrom boot order for initial installation."
}
