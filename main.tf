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


resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.prefix}-${var.environment}-logs"
  location            = var.location
  resource_group_name = module.resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags
}

# Container Apps Module
module "container_apps" {
  source = "./modules/container-apps"

  prefix                        = var.prefix
  location                      = var.location
  resource_group_name           = module.resource_group.name
  log_analytics_workspace_id    = azurerm_log_analytics_workspace.this.id
  docker_username               = var.docker_username
  image_tag                     = var.image_tag
  tags                          = local.common_tags
  subnet_id                     = module.networking.subnet_id
}

module "networking" {
  source                  = "./modules/networking"
  prefix                  = var.prefix
  location                = var.location
  resource_group_name     = module.resource_group.name
  vnet_address_space      = var.vnet_address_space
  subnet_name             = "internal"
  subnet_address_prefixes = var.subnet_address_prefixes
  enable_public_ip        = var.enable_public_ip
  public_ip_allocation_method = "Static"
  public_ip_sku           = "Standard"
  enable_ssh_rule         = var.enable_ssh_rule
  ssh_source_address_prefixes = var.ssh_source_address_prefixes
  custom_security_rules   = {
    zipkin_tcp = {
      priority                   = 1010
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "9411"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }
  tags = local.common_tags
}