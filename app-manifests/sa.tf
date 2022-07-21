resource "kubernetes_service_account_v1" "dashboard-sa" {
  metadata {
    name      = "dashboard-sa"
    namespace = kubernetes_namespace_v1.app-space.metadata[0].name
    labels = {
      name = "dashboard-sa"
      app  = "sample-k8s-app"
    }
  }
}