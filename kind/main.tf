variable "k8s_config_path" {
  type    = string
  default = "~/.kube/config"
}

resource "kind_cluster" "default" {
  name            = "test-cluster"
  kubeconfig_path = pathexpand(var.k8s_config_path)
  wait_for_ready  = true
  node_image      = "kindest/node:v1.22.9"

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n",
        "kind: ClusterConfiguration\ncontrollerManager:\n  extraArgs:\n    bind-address: 0.0.0.0\netcd:\n  local:\n    extraArgs:\n      listen-metrics-urls: http://0.0.0.0:2381\nscheduler:\n  extraArgs:\n    bind-address: 0.0.0.0\n",
        "kind: KubeProxyConfiguration\nmetricsBindAddress: 0.0.0.0\n",
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }
    }

    node {
      role = "worker"
      kubeadm_config_patches = [
        "kind: JoinConfiguration\nnodeRegistration:\n  taints:\n  - key: group\n    value: monitoring\n    effect: NoSchedule\n  kubeletExtraArgs:\n    node-labels: \"group=monitoring\"\n",
        "kind: KubeProxyConfiguration\nmetricsBindAddress: 0.0.0.0\n",
      ]
    }

    node {
      role = "worker"
      kubeadm_config_patches = [
        "kind: JoinConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"group=application\"\n",
        "kind: KubeProxyConfiguration\nmetricsBindAddress: 0.0.0.0\n",
      ]
    }
  }

}

# comment out the "--port=0" in the kube-controller-manager and kube-scheduller manifest files
resource "docker-utils_exec" "exec" {
  container_name = "test-cluster-control-plane"
  commands = [
    "/bin/bash",
    "-c",
    format("%s; %s; %s",
      "sed -i 's/- --port=0/# - --port=0/g' /etc/kubernetes/manifests/kube-controller-manager.yaml",
      "sed -i 's/- --port=0/# - --port=0/g' /etc/kubernetes/manifests/kube-scheduler.yaml",
      "systemctl restart kubelet.service"
    )
  ]

  depends_on = [
    kind_cluster.default
  ]
}