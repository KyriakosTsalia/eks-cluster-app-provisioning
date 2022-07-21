resource "kubernetes_ingress_v1" "app-ingress" {
  metadata {
    name      = "app-ingress"
    namespace = kubernetes_namespace_v1.app-space.metadata[0].name
    labels = {
      name = "app-ingress"
      app  = "sample-k8s-app"
    }
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
      "nginx.ingress.kubernetes.io/ssl-redirect"   = "false"
    }
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      http {
        path {
          path      = "/app(/|$)(.*)"
          path_type = "Prefix"
          backend {
            service {
              name = "app-svc"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}