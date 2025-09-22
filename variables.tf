# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# General Variables
variable "prefix" {
  type        = string
  default     = "example"
  description = "The prefix which should be used for all resources in this example"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment name (dev, staging, prod)"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  type        = string
  default     = "vm-terraform"
  description = "Name of the project"
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "The Azure Region in which all resources in this example should be created."
}

# Networking Variables
variable "vnet_address_space" {
  type        = list(string)
  default     = ["10.0.0.0/22"]
  description = "Address space for the virtual network"
}

variable "subnet_address_prefixes" {
  type        = list(string)
  default     = ["10.0.2.0/24"]
  description = "Address prefixes for the subnet"
}

variable "enable_public_ip" {
  type        = bool
  default     = true
  description = "Whether to create and assign a public IP to the VM"
}

variable "enable_ssh_rule" {
  type        = bool
  default     = true
  description = "Whether to create SSH security rule"
}

variable "ssh_source_address_prefixes" {
  type        = list(string)
  default     = ["*"]
  description = "Source address prefixes for SSH access. Restrict to specific IPs for security"
}

variable "custom_security_rules" {
  type = map(object({
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  description = "Custom security rules to add to the NSG"
  default     = {}
}

# Compute Variables
variable "vm_size" {
  type        = string
  default     = "Standard_B1s"
  description = "Size of the virtual machine"
}

variable "admin_username" {
  type        = string
  default     = "UserAdmin"
  description = "The admin username for the VM being created."
}

variable "admin_password" {
  type        = string
  default     = "AdminP@ssword"
  description = "The password for the VM being created. Required if authentication_type is 'Password'"
  sensitive   = true
}

variable "authentication_type" {
  type        = string
  default     = "SSH"
  description = "Type of authentication to use (SSH or Password)"
  validation {
    condition     = contains(["SSH", "Password"], var.authentication_type)
    error_message = "Authentication type must be either 'SSH' or 'Password'."
  }
}

variable "ssh_public_key" {
  type        = string
  default     = null
  description = "SSH public key for authentication. If not provided and authentication_type is SSH, a key will be generated"
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

variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}
