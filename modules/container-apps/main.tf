# Container Apps Environment
resource "azurerm_container_app_environment" "this" {
  name                       = "${var.prefix}-containerapp-env"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  infrastructure_subnet_id   = var.subnet_id
  tags = var.tags
}

# Zipkin Container App (tracing distribuido)
resource "azurerm_container_app" "zipkin" {
  name                         = "${var.prefix}-zipkin"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = "zipkin"
      image  = "openzipkin/zipkin:latest"
      cpu    = "0.25"
      memory = "0.5Gi"

      env {
        name  = "JAVA_OPTS"
        value = "-Dserver.address=0.0.0.0 -Dserver.port=9411"
      }
      
    }
    min_replicas = 1
    max_replicas = 1
  }
  

  ingress {
    external_enabled = true
    target_port      = 9411
    transport       = "tcp" 

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = var.tags
  depends_on = [azurerm_container_app_environment.this]
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

      args = ["redis-server", "--appendonly", "yes"]

      env {
        name  = "ZIPKIN_URL"
        value = "http://myapp-zipkin:9411/api/v2/spans"
      }

      
    }
  }

    ingress {
      external_enabled = false
      target_port      = 6379
      transport        = "tcp"
          traffic_weight {
        percentage      = 100
        latest_revision = true
      }
    }

  # No ingress - solo comunicación interna
  tags = var.tags
  depends_on = [azurerm_container_app_environment.this]
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
        value = "http://myapp-auth-api:8000"
      }
      
      env {
        name  = "TODOS_API_URL"
        value = "http://myapp-todos-api:8082"
      }
      
      env {
        name  = "USERS_API_URL"
        value = "http://myapp-users-api:8083"
      }
      env {
        name  = "ZIPKIN_URL"
        value = "myapp-zipkin:9411" 
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
  depends_on = [azurerm_container_app_environment.this]
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
        value = "http://myapp-users-api:80"
      }
      
      env {
        name  = "REDIS_HOST"
        value = "myapp-redis"
      }
      
      env {
        name  = "REDIS_PORT"
        value = "6379"
      }
      
      env {
        name  = "JWT_SECRET"
        value = "myfancysecret"
      }

      env {
        name  = "ZIPKIN_URL"
        value = "http://myapp-zipkin:9411/api/v2/spans"
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
  depends_on = [azurerm_container_app_environment.this]
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
        value = "myapp-redis"
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

      env {
        name  = "ZIPKIN_URL"
        value = "http://myapp-zipkin:9411/api/v2/spans"
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
  depends_on = [azurerm_container_app_environment.this]
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

      env {
        name  = "ZIPKIN_URL"
        value = "http://myapp-zipkin:9411"
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
  depends_on = [azurerm_container_app_environment.this]
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
        value = "myapp-redis"
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
        name  = "ZIPKIN_URL"
        value = "http://myapp-zipkin:9411"
      }

    }
    
    min_replicas = var.log_processor_config.min_replicas
    max_replicas = var.log_processor_config.max_replicas
  }

  tags = var.tags
  depends_on = [azurerm_container_app_environment.this]
}