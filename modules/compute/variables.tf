variable "prefix" {
  type        = string
  description = "Prefix for resource names"
}

variable "location" {
  type        = string
  description = "Azure region where resources will be created"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet where the VM will be placed"
}

variable "public_ip_id" {
  type        = string
  description = "ID of the public IP to associate with the VM"
  default     = null
}

variable "network_security_group_id" {
  type        = string
  description = "ID of the network security group to associate with the NIC"
  default     = null
}

variable "vm_size" {
  type        = string
  description = "Size of the virtual machine"
  default     = "Standard_B1s"
}

variable "admin_username" {
  type        = string
  description = "Admin username for the VM"
}

variable "admin_password" {
  type        = string
  description = "Admin password for the VM (used only if authentication_type is Password)"
  default     = null
  sensitive   = true
}

variable "authentication_type" {
  type        = string
  description = "Type of authentication to use (SSH or Password)"
  default     = "SSH"
  validation {
    condition     = contains(["SSH", "Password"], var.authentication_type)
    error_message = "Authentication type must be either 'SSH' or 'Password'."
  }
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for authentication (optional, will generate if not provided)"
  default     = null
}

variable "private_ip_address_allocation" {
  type        = string
  description = "Private IP address allocation method"
  default     = "Dynamic"
  validation {
    condition     = contains(["Static", "Dynamic"], var.private_ip_address_allocation)
    error_message = "Private IP allocation method must be either 'Static' or 'Dynamic'."
  }
}

variable "source_image_reference" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  description = "Source image reference for the VM"
  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

variable "os_disk" {
  type = object({
    storage_account_type = string
    caching              = string
    disk_size_gb         = optional(number)
  })
  description = "OS disk configuration"
  default = {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = null
  }
}

variable "enable_boot_diagnostics" {
  type        = bool
  description = "Whether to enable boot diagnostics"
  default     = false
}

variable "boot_diagnostics_storage_account_uri" {
  type        = string
  description = "URI of the storage account for boot diagnostics"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}