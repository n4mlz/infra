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
  type = string
}

variable "bridge" {
  type = string
}

variable "started" {
  type        = bool
  default     = false
  description = "Whether the VM should be started after creation"
}
