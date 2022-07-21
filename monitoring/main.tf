resource "helm_release" "prom-chart" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "36.6.1"

  namespace        = "monitoring"
  create_namespace = true

  values = [file("values.yaml")]

  # in case of EKS, disable the components scraping the kubeControllerManager and kubeScheduler,
  # which are scheduled on the master node and are "hidden" by AWS, due to it being a managed kubernetes solution -
  # by doing so, we remove the "KubeControllerManagerDown" and "KubeSchedulerDown" alerts.
  dynamic "set" {
    for_each = var.env == "aws" ? ["kubeControllerManager.enabled", "kubeScheduler.enabled"] : []
    content {
      name = set.value
      value = "false"
    }
  }

  timeout = 600 # instead of the default 300 seconds - the grafana pod seems to need longer to download all 3 images

}