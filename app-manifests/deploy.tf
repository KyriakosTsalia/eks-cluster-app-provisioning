resource "kubernetes_deployment_v1" "sample-k8s-app" {
  metadata {
    name      = "sample-k8s-app"
    namespace = kubernetes_namespace_v1.app-space.metadata[0].name
    labels = {
      name = "sample-k8s-app"
      app  = "sample-k8s-app"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "sample-k8s-app"
      }
    }
    template {
      metadata {
        labels = {
          app = "sample-k8s-app"
        }
      }
      spec {
        security_context {
          run_as_user     = 1000
          run_as_group    = 3000
          run_as_non_root = true
          fs_group        = 2000
        }
        service_account_name = kubernetes_service_account_v1.dashboard-sa.metadata[0].name
        container {
          image = "ktsaliagkos/sample-k8s-app"
          name  = "sample-k8s-app"
          port {
            name           = "http"
            protocol       = "TCP"
            container_port = 8080
          }
          args = [
            "-delay=$(APP_START_DELAY)"
          ]
          env {
            name  = "APP_START_DELAY"
            value = "10"
          }
          resources {
            limits = {
              cpu    = "1"
              memory = "1Gi"
            }
            requests = {
              cpu    = "0.5"
              memory = "512Mi"
            }
          }
          readiness_probe {
            http_get {
              path = "/api/ready"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            failure_threshold     = 6
          }
          liveness_probe {
            http_get {
              path = "/api/healthy"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            failure_threshold     = 6
          }
        }
      }
    }
  }
}