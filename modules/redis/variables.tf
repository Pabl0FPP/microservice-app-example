variable "name" {
  type        = string
  description = "Name of the Redis cache"
}

variable "location" {
  type        = string
  description = "Azure region where Redis will be created"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "sku_name" {
  type        = string
  description = "SKU name for Redis cache"
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku_name)
    error_message = "SKU name must be one of: Basic, Standard, Premium."
  }
}

variable "capacity" {
  type        = number
  description = "Capacity of the Redis cache"
  default     = 0
  validation {
    condition     = var.capacity >= 0 && var.capacity <= 6
    error_message = "Capacity must be between 0 and 6."
  }
}

variable "family" {
  type        = string
  description = "Family of the Redis cache"
  default     = "C"
  validation {
    condition     = contains(["C", "P"], var.family)
    error_message = "Family must be either 'C' (Basic/Standard) or 'P' (Premium)."
  }
}

variable "enable_non_ssl_port" {
  type        = bool
  description = "Whether to enable the non-SSL port"
  default     = false
}

variable "minimum_tls_version" {
  type        = string
  description = "Minimum TLS version"
  default     = "1.2"
  validation {
    condition     = contains(["1.0", "1.1", "1.2"], var.minimum_tls_version)
    error_message = "Minimum TLS version must be 1.0, 1.1, or 1.2."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the Redis cache"
  default     = {}
}