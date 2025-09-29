output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.this.name
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = azurerm_subnet.this.id
}

output "subnet_name" {
  description = "Name of the subnet"
  value       = azurerm_subnet.this.name
}

output "public_ip_id" {
  description = "ID of the public IP"
  value       = var.enable_public_ip ? azurerm_public_ip.this[0].id : null
}

output "public_ip_address" {
  description = "The public IP address"
  value       = var.enable_public_ip ? azurerm_public_ip.this[0].ip_address : null
}

output "network_security_group_id" {
  description = "ID of the network security group"
  value       = azurerm_network_security_group.this.id
}

output "network_security_group_name" {
  description = "Name of the network security group"
  value       = azurerm_network_security_group.this.name
}