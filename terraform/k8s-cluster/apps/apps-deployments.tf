
// Backend deployment & service

resource "kubernetes_deployment" "backend-deployment" {
  depends_on = [kubernetes_deployment.postgres-deployment]
  metadata {
    name      = "backend"
    namespace = var.namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "noteapp-backend"
      }
    }
    template {
      metadata {
        labels = {
          app = "noteapp-backend"
        }
      }
      spec {
        container {
          name  = "noteapp-backend"
          image = "houssinedahmane/todo_app_with_k8s_backend:1.0.024"
          port {
            name           = "http-web"
            container_port = 3001
          }
          env {
            name  = "DB_PORT"
            value = "5432"
          }
          env {
            name  = "DB_HOST"
            value = kubernetes_service.postgres-service.metadata.0.name
          }
          env {
            name  = "POSTGRES_DB"
            value = "todos"
          }
          env {
            name  = "POSTGRES_USER"
            value = "postgres"
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = "password"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "backend-service" {
  metadata {
    name      = "backend-service"
    namespace = var.namespace
  }
  spec {
    selector = {
      app = "${kubernetes_deployment.backend-deployment.spec.0.template.0.metadata.0.labels.app}"
    }
    port {
      port        = 3001
      target_port = 3001
      node_port   = 30001

    }
    type = "NodePort"
  }
}

// Frontend deployment & service

resource "kubernetes_deployment" "frontend-deployment" {
  metadata {
    name      = "frontend"
    namespace = var.namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "noteapp-frontend"
      }
    }
    template {
      metadata {
        labels = {
          app = "noteapp-frontend"
        }
      }
      spec {
        container {
          name  = "noteapp-frontend"
          image = "houssinedahmane/todo_app_with_k8s_frontend:latest"
          port {
            container_port = 3000
          }
          env {
            name  = "REACT_APP_API_URL"
            value = "http://192.168.49.2:30001/api"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "frontend-service" {
  metadata {
    name      = "frontend-service"
    namespace = var.namespace
  }
  spec {
    selector = {
      app = "${kubernetes_deployment.frontend-deployment.spec.0.template.0.metadata.0.labels.app}"
    }
    port {
      port        = 3000
      target_port = 3000
      node_port   = 30002

    }
    type = "NodePort"
  }
}

// postgres deployment & service

resource "kubernetes_deployment" "postgres-deployment" {
  metadata {
    name      = "postgres"
    namespace = var.namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "postgres"
      }
    }
    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }
      spec {
        container {
          name  = "postgres"
          image = "postgres:12"
          port {
            container_port = 5432
          }
          env {
            name  = "POSTGRES_DB"
            value = "todos"
          }
          env {
            name  = "POSTGRES_USER"
            value = "postgres"
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = "password"
          }
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }
          volume_mount {
            name       = "mendix-pgdata"
            mount_path = "/var/lib/postgresql/data"
          }
        }
        volume {
          name = "mendix-pgdata"
          host_path {
            path = "/home/houssine/workspace/Todo-gitlab/data"
            type = "DirectoryOrCreate"
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "postgres-service" {
  metadata {
    name      = "postgres-service"
    namespace = var.namespace
  }
  spec {
    selector = {
      app = "${kubernetes_deployment.postgres-deployment.spec.0.template.0.metadata.0.labels.app}"
    }
    port {
      port = 5432
    }
  }
}
