resource "kubernetes_role_v1" "pod-reader" {
  metadata {
    name      = "pod-reader"
    namespace = kubernetes_namespace_v1.app-space.metadata[0].name
    labels = {
      name = "pod-reader"
      app  = "sample-k8s-app"
    }
  }
  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_role_binding_v1" "pod-reader-binding" {
  metadata {
    name      = "pod-reader-binding"
    namespace = kubernetes_namespace_v1.app-space.metadata[0].name
    labels = {
      name = "pod-reader-binding"
      app  = "sample-k8s-app"
    }
  }
  role_ref {
    name      = kubernetes_role_v1.pod-reader.metadata[0].name
    kind      = "Role"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    name      = kubernetes_service_account_v1.dashboard-sa.metadata[0].name
    namespace = kubernetes_service_account_v1.dashboard-sa.metadata[0].namespace
    kind      = "ServiceAccount"
  }
}