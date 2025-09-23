resource "azurerm_redis_cache" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = var.capacity
  family              = var.family
  sku_name           = var.sku_name
  non_ssl_port_enabled = var.enable_non_ssl_port
  minimum_tls_version = var.minimum_tls_version

  tags = var.tags
}