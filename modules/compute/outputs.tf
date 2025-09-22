output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.this.id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.this.name
}

output "vm_private_ip_address" {
  description = "Private IP address of the virtual machine"
  value       = azurerm_network_interface.this.private_ip_address
}

output "vm_public_ip_address" {
  description = "Public IP address of the virtual machine"
  value       = var.public_ip_id != null ? azurerm_linux_virtual_machine.this.public_ip_address : null
}

output "network_interface_id" {
  description = "ID of the network interface"
  value       = azurerm_network_interface.this.id
}

output "ssh_private_key" {
  description = "SSH private key (only available if generated automatically)"
  value       = var.authentication_type == "SSH" && var.ssh_public_key == null ? tls_private_key.this[0].private_key_pem : null
  sensitive   = true
}

output "ssh_public_key" {
  description = "SSH public key (only available if generated automatically)"
  value       = var.authentication_type == "SSH" && var.ssh_public_key == null ? tls_private_key.this[0].public_key_openssh : null
}