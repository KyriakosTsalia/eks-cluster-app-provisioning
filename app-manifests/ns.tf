resource "kubernetes_namespace_v1" "app-space" {
  metadata {
    name = "app-space"
    labels = {
      name = "app-space"
    }
  }
}