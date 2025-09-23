output "container_app_environment_id" {
  description = "ID of the Container Apps Environment"
  value       = azurerm_container_app_environment.this.id
}

output "container_app_environment_name" {
  description = "Name of the Container Apps Environment"
  value       = azurerm_container_app_environment.this.name
}

output "frontend_url" {
  description = "URL of the frontend application"
  value       = "https://${azurerm_container_app.frontend.latest_revision_fqdn}"
}

output "auth_api_url" {
  description = "URL of the auth API"
  value       = "https://${azurerm_container_app.auth_api.latest_revision_fqdn}"
}

output "todos_api_url" {
  description = "URL of the todos API"
  value       = "https://${azurerm_container_app.todos_api.latest_revision_fqdn}"
}

output "users_api_url" {
  description = "URL of the users API"
  value       = "https://${azurerm_container_app.users_api.latest_revision_fqdn}"
}

output "application_urls" {
  description = "All application URLs"
  value = {
    frontend  = "https://${azurerm_container_app.frontend.latest_revision_fqdn}"
    auth_api  = "https://${azurerm_container_app.auth_api.latest_revision_fqdn}"
    todos_api = "https://${azurerm_container_app.todos_api.latest_revision_fqdn}"
    users_api = "https://${azurerm_container_app.users_api.latest_revision_fqdn}"
  }
}

output "redis_internal_url" {
  description = "Internal Redis URL for debugging"
  value       = "${azurerm_container_app.redis.name}:6379"
}

output "container_app_ids" {
  description = "IDs of all container apps"
  value = {
    frontend      = azurerm_container_app.frontend.id
    auth_api      = azurerm_container_app.auth_api.id
    todos_api     = azurerm_container_app.todos_api.id
    users_api     = azurerm_container_app.users_api.id
    log_processor = azurerm_container_app.log_processor.id
    redis         = azurerm_container_app.redis.id
  }
}