# Input variables for the Proxmox environment.
# Sensitive values (e.g. API token) are injected via environment variables.

variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox API endpoint, e.g. https://pve.example.internal:8006/"
}

variable "proxmox_api_token_id" {
  type        = string
  description = "Proxmox API token ID (e.g. root@pam!opentofu)"
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  type        = string
  description = "Proxmox API token secret (UUID)"
  sensitive   = true
}

variable "proxmox_insecure" {
  type        = bool
  description = "Skip TLS verification for Proxmox self-signed certificate"
  default     = true
}

variable "proxmox_node_name" {
  type        = string
  description = "Proxmox node name (hostname of the Proxmox server)"
}

variable "vm_bridge" {
  type        = string
  description = "Linux bridge for Kubernetes VMs"
  default     = "vmbr0"
}

variable "vm_datastore_id" {
  type        = string
  description = "Datastore for VM disks"
  default     = "local-zfs"
}

variable "iso_datastore_id" {
  type        = string
  description = "Datastore containing Talos ISO"
  default     = "local"
}

variable "talos_iso_file_id" {
  type        = string
  description = "Proxmox file ID of Talos ISO. 'none' for empty CD-ROM (post-install)."
  default     = "none"
}

variable "talos_boot_order" {
  type        = list(string)
  description = "Boot order for Talos VMs. Default is disk-only (post-install)."
  default     = ["scsi0"]
}
