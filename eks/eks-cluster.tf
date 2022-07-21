locals {
  eks_cluster_name = "kube-cluster"
}

resource "aws_eks_cluster" "kube-cluster" {
  name     = local.eks_cluster_name
  role_arn = aws_iam_role.kube-cluster-role.arn

  version = "1.22"

  vpc_config {
    subnet_ids              = flatten([module.vpc.public_subnets, module.vpc.private_subnets])
    endpoint_private_access = true # private intra-cluster communication
    endpoint_public_access  = true # public cluster API server - for ease of use
  }

  kubernetes_network_config {
    service_ipv4_cidr = "172.16.0.0/12"
  }

  depends_on = [
    aws_iam_role_policy_attachment.kube-cluster-AmazonEKSClusterPolicy
  ]
}

output "endpoint" {
  value = aws_eks_cluster.kube-cluster.endpoint
}

# Base64 encoded certificate data required to communicate with your cluster. 
# Add this to the certificate-authority-data section of the kubeconfig file for your cluster
output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.kube-cluster.certificate_authority[0].data
}

resource "null_resource" "kubeconfig" {
  triggers = {
    always = timestamp()
  }

  depends_on = [aws_eks_cluster.kube-cluster]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      set -e
      aws eks wait cluster-active --name '${local.eks_cluster_name}'
      aws eks update-kubeconfig --name '${local.eks_cluster_name}' --region=${var.AWS_REGION}
    EOT
  }
}