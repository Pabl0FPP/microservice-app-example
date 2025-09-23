# Container Apps Environment
resource "azurerm_container_app_environment" "this" {
  name                       = "${var.prefix}-containerapp-env"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id

  tags = var.tags
}

# Redis Container App (Internal)
resource "azurerm_container_app" "redis" {
  name                         = "${var.prefix}-redis"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    min_replicas = 1
    max_replicas = 1

    container {
      name   = "redis"
      image  = "redis:7.0-alpine"
      cpu    = "0.25"
      memory = "0.5Gi"

      args = ["redis-server", "--requirepass", "redispassword123", "--appendonly", "yes"]

      env {
        name  = "REDIS_PASSWORD"
        value = "redispassword123"
      }
    }
  }

  # No ingress - solo comunicación interna
  tags = var.tags
}

# Frontend Container App
resource "azurerm_container_app" "frontend" {
  name                         = "${var.prefix}-frontend"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode               = "Single"

  template {
    container {
      name   = "frontend"
      image  = "${var.docker_username}/frontend:${var.image_tag}"
      cpu    = var.frontend_config.cpu
      memory = var.frontend_config.memory
      
      # Variables de entorno con URLs de APIs para envsubst
      env {
        name  = "AUTH_API_URL"
        value = azurerm_container_app.auth_api.latest_revision_fqdn
      }
      
      env {
        name  = "TODOS_API_URL"
        value = azurerm_container_app.todos_api.latest_revision_fqdn
      }
      
      env {
        name  = "USERS_API_URL"
        value = azurerm_container_app.users_api.latest_revision_fqdn
      }
    }
    
    min_replicas = var.frontend_config.min_replicas
    max_replicas = var.frontend_config.max_replicas
  }

  ingress {
    external_enabled = true
    target_port     = 80
    
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = var.tags
}

# Auth API Container App
resource "azurerm_container_app" "auth_api" {
  name                         = "${var.prefix}-auth-api"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode               = "Single"

  template {
    container {
      name   = "auth-api"
      image  = "${var.docker_username}/auth-api:${var.image_tag}"
      cpu    = var.api_config.cpu
      memory = var.api_config.memory
      
      env {
        name  = "USERS_API_ADDRESS"
        value = "https://${azurerm_container_app.users_api.latest_revision_fqdn}"
      }
      
      env {
        name  = "REDIS_HOST"
        value = "${var.prefix}-redis"
      }
      
      env {
        name  = "REDIS_PORT"
        value = "6379"
      }
      
      env {
        name  = "REDIS_PASSWORD"
        value = "redispassword123"
      }
      
      env {
        name  = "JWT_SECRET"
        value = "myfancysecret"
      }
    }
    
    min_replicas = var.api_config.min_replicas
    max_replicas = var.api_config.max_replicas
  }

  ingress {
    external_enabled = true
    target_port     = 8000
    
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = var.tags
}

# Todos API Container App
resource "azurerm_container_app" "todos_api" {
  name                         = "${var.prefix}-todos-api"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode               = "Single"

  template {
    container {
      name   = "todos-api"
      image  = "${var.docker_username}/todos-api:${var.image_tag}"
      cpu    = var.api_config.cpu
      memory = var.api_config.memory
      
      env {
        name  = "REDIS_HOST"
        value = "${var.prefix}-redis"
      }
      
      env {
        name  = "REDIS_PORT"
        value = "6379"
      }
      
      env {
        name  = "REDIS_CHANNEL"
        value = "log_channel"
      }
      
      env {
        name  = "JWT_SECRET"
        value = "myfancysecret"
      }
    }
    
    min_replicas = var.api_config.min_replicas
    max_replicas = var.api_config.max_replicas
  }

  ingress {
    external_enabled = true
    target_port     = 8082
    
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = var.tags
}

# Users API Container App
resource "azurerm_container_app" "users_api" {
  name                         = "${var.prefix}-users-api"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode               = "Single"

  template {
    container {
      name   = "users-api"
      image  = "${var.docker_username}/users-api:${var.image_tag}"
      cpu    = var.api_config.cpu
      memory = var.api_config.memory
      
      env {
        name  = "JWT_SECRET"
        value = "myfancysecret"
      }
    }
    
    min_replicas = var.api_config.min_replicas
    max_replicas = var.api_config.max_replicas
  }

  ingress {
    external_enabled = true
    target_port     = 8083
    
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = var.tags
}

# Log Processor Container App (interno, sin ingress)
resource "azurerm_container_app" "log_processor" {
  name                         = "${var.prefix}-log-processor"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode               = "Single"

  template {
    container {
      name   = "log-processor"
      image  = "${var.docker_username}/log-message-processor:${var.image_tag}"
      cpu    = var.log_processor_config.cpu
      memory = var.log_processor_config.memory
      
      env {
        name  = "REDIS_HOST"
        value = "${var.prefix}-redis"
      }
      
      env {
        name  = "REDIS_PORT"
        value = "6379"
      }
      
      env {
        name  = "REDIS_CHANNEL"
        value = "log_channel"
      }
    }
    
    min_replicas = var.log_processor_config.min_replicas
    max_replicas = var.log_processor_config.max_replicas
  }

  tags = var.tags
}