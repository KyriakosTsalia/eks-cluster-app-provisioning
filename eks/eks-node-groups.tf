resource "aws_eks_node_group" "monitoring-nodes" {
  cluster_name    = aws_eks_cluster.kube-cluster.name
  node_group_name = "monitoring"
  node_role_arn   = aws_iam_role.node-role.arn
  subnet_ids      = module.vpc.private_subnets

  capacity_type  = "SPOT"
  disk_size      = 50
  instance_types = ["t3.small"] # pod-per-limit = 11, with t3.micro (free-tier) it is 4 - too small for our needs

  labels = {
    group = "monitoring"
  }

  taint {
    key    = "group"
    value  = "monitoring"
    effect = "NO_SCHEDULE"
  }

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_eks_node_group" "application-nodes" {
  cluster_name    = aws_eks_cluster.kube-cluster.name
  node_group_name = "application"
  node_role_arn   = aws_iam_role.node-role.arn
  subnet_ids      = module.vpc.private_subnets

  capacity_type  = "SPOT"
  disk_size      = 100
  instance_types = ["t3.small"]

  labels = {
    group = "application"
  }

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]
}