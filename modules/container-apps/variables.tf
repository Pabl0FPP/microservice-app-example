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

variable "docker_username" {
  type        = string
  description = "Docker Hub username for container images"
}

variable "image_tag" {
  type        = string
  description = "Docker image tag to deploy"
  default     = "latest"
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics Workspace ID for Container Apps Environment"
}

# Container resource configuration
variable "frontend_config" {
  type = object({
    cpu         = string
    memory      = string
    min_replicas = number
    max_replicas = number
  })
  description = "Frontend container configuration"
  default = {
    cpu         = "0.25"
    memory      = "0.5Gi"
    min_replicas = 1
    max_replicas = 3
  }
}

variable "api_config" {
  type = object({
    cpu         = string
    memory      = string
    min_replicas = number
    max_replicas = number
  })
  description = "API containers configuration"
  default = {
    cpu         = "0.5"
    memory      = "1Gi"
    min_replicas = 1
    max_replicas = 5
  }
}

variable "log_processor_config" {
  type = object({
    cpu         = string
    memory      = string
    min_replicas = number
    max_replicas = number
  })
  description = "Log processor container configuration"
  default = {
    cpu         = "0.25"
    memory      = "0.5Gi"
    min_replicas = 1
    max_replicas = 2
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}