resource "kubernetes_manifest" "app-servicemonitor" {
  manifest = {
    "apiVersion" = "monitoring.coreos.com/v1"
    "kind"       = "ServiceMonitor"
    "metadata" = {
      "labels" = {
        "name"    = "prometheus-app-servicemonitor"
        "release" = "prometheus"
      }
      "name"      = "prometheus-app-servicemonitor"
      "namespace" = "monitoring"
    }
    "spec" = {
      "endpoints" = [
        {
          "port" = "http"
        },
      ]
      "namespaceSelector" = {
        "matchNames" = [
          "app-space",
        ]
      }
      "selector" = {
        "matchLabels" = {
          "app"  = "sample-k8s-app"
          "name" = "app-svc"
        }
      }
    }
  }
}