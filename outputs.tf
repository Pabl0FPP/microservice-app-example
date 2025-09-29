# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.resource_group.id
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = module.resource_group.location
}

# Monitoring Outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.this.id
}

# Container Apps Outputs
output "container_app_environment_id" {
  description = "ID of the Container Apps Environment"
  value       = module.container_apps.container_app_environment_id
}

output "container_app_environment_name" {
  description = "Name of the Container Apps Environment"
  value       = module.container_apps.container_app_environment_name
}

output "frontend_url" {
  description = "URL of the frontend application"
  value       = module.container_apps.frontend_url
}

output "auth_api_url" {
  description = "URL of the auth API"
  value       = module.container_apps.auth_api_url
}

output "todos_api_url" {
  description = "URL of the todos API"
  value       = module.container_apps.todos_api_url
}

output "users_api_url" {
  description = "URL of the users API"
  value       = module.container_apps.users_api_url
}

# Application URLs
output "application_urls" {
  description = "URLs to access the microservices"
  value       = module.container_apps.application_urls
}

output "container_app_ids" {
  description = "IDs of all container apps"
  value       = module.container_apps.container_app_ids
}
