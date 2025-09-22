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

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
  default     = ["10.0.0.0/22"]
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet"
  default     = "internal"
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the subnet"
  default     = ["10.0.2.0/24"]
}

variable "enable_public_ip" {
  type        = bool
  description = "Whether to create a public IP"
  default     = true
}

variable "public_ip_allocation_method" {
  type        = string
  description = "Allocation method for the public IP"
  default     = "Static"
  validation {
    condition     = contains(["Static", "Dynamic"], var.public_ip_allocation_method)
    error_message = "Public IP allocation method must be either 'Static' or 'Dynamic'."
  }
}

variable "public_ip_sku" {
  type        = string
  description = "SKU for the public IP"
  default     = "Standard"
  validation {
    condition     = contains(["Basic", "Standard"], var.public_ip_sku)
    error_message = "Public IP SKU must be either 'Basic' or 'Standard'."
  }
}

variable "enable_ssh_rule" {
  type        = bool
  description = "Whether to create SSH security rule"
  default     = true
}

variable "ssh_source_address_prefixes" {
  type        = list(string)
  description = "Source address prefixes for SSH access. Use specific IPs instead of '*' for security"
  default     = ["*"]
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
  description = "Custom security rules"
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}