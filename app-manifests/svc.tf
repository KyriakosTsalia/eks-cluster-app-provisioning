resource "kubernetes_service_v1" "app-svc" {
  metadata {
    name      = "app-svc"
    namespace = kubernetes_namespace_v1.app-space.metadata[0].name
    labels = {
      name = "app-svc"
      app  = "sample-k8s-app"
    }
  }
  spec {
    type     = "ClusterIP"
    selector = kubernetes_deployment_v1.sample-k8s-app.spec[0].template[0].metadata[0].labels
    port {
      protocol    = "TCP"
      name        = "http"
      port        = 8080
      target_port = 8080
    }
  }
}