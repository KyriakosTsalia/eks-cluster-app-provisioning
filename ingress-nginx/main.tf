resource "helm_release" "ingress-nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.1.4"

  namespace        = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.updateStrategy.type"
    value = "RollingUpdate"
  }

  set {
    name  = "controller.updateStrategy.rollingUpdate.maxUnavailable"
    value = 1
  }

  values = var.env == "aws" ? [] : [file("values.yaml")]
}