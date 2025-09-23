output "id" {
  description = "ID of the Redis cache"
  value       = azurerm_redis_cache.this.id
}

output "name" {
  description = "Name of the Redis cache"
  value       = azurerm_redis_cache.this.name
}

output "hostname" {
  description = "Hostname of the Redis cache"
  value       = azurerm_redis_cache.this.hostname
}

output "ssl_port" {
  description = "SSL port of the Redis cache"
  value       = azurerm_redis_cache.this.ssl_port
}

output "port" {
  description = "Non-SSL port of the Redis cache"
  value       = azurerm_redis_cache.this.port
}

output "primary_access_key" {
  description = "Primary access key for the Redis cache"
  value       = azurerm_redis_cache.this.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "Secondary access key for the Redis cache"
  value       = azurerm_redis_cache.this.secondary_access_key
  sensitive   = true
}

output "connection_string" {
  description = "Primary Redis connection string"
  value       = "rediss://:${azurerm_redis_cache.this.primary_access_key}@${azurerm_redis_cache.this.hostname}:${azurerm_redis_cache.this.ssl_port}"
  sensitive   = true
}