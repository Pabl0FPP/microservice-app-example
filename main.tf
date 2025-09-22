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

# Monitoring Module (Log Analytics)
module "monitoring" {
  source = "./modules/monitoring"

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
  log_analytics_workspace_id    = module.monitoring.id
  docker_username               = var.docker_username
  image_tag                     = var.image_tag
  tags                          = local.common_tags
}
