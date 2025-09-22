provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}

# Resource Group Module
module "resource_group" {
  source = "./modules/resource-group"

  name     = "${var.prefix}-${var.environment}-resources"
  location = var.location
  tags     = local.common_tags
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  prefix                        = var.prefix
  location                      = var.location
  resource_group_name           = module.resource_group.name
  vnet_address_space           = var.vnet_address_space
  subnet_address_prefixes      = var.subnet_address_prefixes
  enable_public_ip             = var.enable_public_ip
  enable_ssh_rule              = var.enable_ssh_rule
  ssh_source_address_prefixes  = var.ssh_source_address_prefixes
  custom_security_rules        = var.custom_security_rules
  tags                         = local.common_tags
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  prefix                     = var.prefix
  location                   = var.location
  resource_group_name        = module.resource_group.name
  subnet_id                  = module.networking.subnet_id
  public_ip_id               = module.networking.public_ip_id
  network_security_group_id  = module.networking.network_security_group_id
  vm_size                    = var.vm_size
  admin_username             = var.admin_username
  admin_password             = var.admin_password
  authentication_type        = var.authentication_type
  ssh_public_key             = var.ssh_public_key
  source_image_reference     = var.source_image_reference
  os_disk                    = var.os_disk
  tags                       = local.common_tags
}
