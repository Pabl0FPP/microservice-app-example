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

# Networking Outputs
output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = module.networking.subnet_id
}

output "public_ip_address" {
  description = "Public IP address of the VM"
  value       = module.networking.public_ip_address
}

output "network_security_group_id" {
  description = "ID of the network security group"
  value       = module.networking.network_security_group_id
}

# Compute Outputs
output "vm_id" {
  description = "ID of the virtual machine"
  value       = module.compute.vm_id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = module.compute.vm_name
}

output "vm_private_ip_address" {
  description = "Private IP address of the VM"
  value       = module.compute.vm_private_ip_address
}

output "vm_public_ip_address" {
  description = "Public IP address of the VM (from compute module)"
  value       = module.compute.vm_public_ip_address
}

output "ssh_private_key" {
  description = "SSH private key (only if generated automatically)"
  value       = module.compute.ssh_private_key
  sensitive   = true
}

output "ssh_public_key" {
  description = "SSH public key (only if generated automatically)"
  value       = module.compute.ssh_public_key
}

# Connection Information
output "ssh_connection_command" {
  description = "SSH command to connect to the VM"
  value = var.authentication_type == "SSH" ? (
    module.networking.public_ip_address != null ? 
    "ssh ${var.admin_username}@${module.networking.public_ip_address}" : 
    "ssh ${var.admin_username}@${module.compute.vm_private_ip_address}"
  ) : null
}
