variable "name" {
  type        = string
  description = "Name of the Log Analytics Workspace"
}

variable "location" {
  type        = string
  description = "Azure region where the workspace will be created"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "sku" {
  type        = string
  description = "SKU of the Log Analytics Workspace"
  default     = "PerGB2018"
  validation {
    condition     = contains(["Free", "PerNode", "Premium", "Standard", "Standalone", "Unlimited", "CapacityReservation", "PerGB2018"], var.sku)
    error_message = "SKU must be one of the valid Log Analytics pricing tiers."
  }
}

variable "retention_in_days" {
  type        = number
  description = "Data retention in days"
  default     = 30
  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "Retention must be between 30 and 730 days."
  }
}

variable "daily_quota_gb" {
  type        = number
  description = "Daily data ingestion quota in GB"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the workspace"
  default     = {}
}