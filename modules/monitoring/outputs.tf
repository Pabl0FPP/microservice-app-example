output "id" {
  description = "ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "workspace_id" {
  description = "Workspace ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "primary_shared_key" {
  description = "Primary shared key of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "secondary_shared_key" {
  description = "Secondary shared key of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.secondary_shared_key
  sensitive   = true
}

output "name" {
  description = "Name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "location" {
  description = "Location of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.location
}