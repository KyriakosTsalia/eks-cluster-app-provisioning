terraform {
  required_version = "~> 1.2.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.18.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.6.0"
    }
  }
}

provider "aws" {
  region = var.AWS_REGION
}

locals {
  eks_cluster_name = "kube-cluster"
}

data "aws_eks_cluster" "cluster" {
  count = var.env == "aws" ? 1 : 0
  name  = local.eks_cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  count = var.env == "aws" ? 1 : 0
  name  = local.eks_cluster_name
}

provider "helm" {
  kubernetes {
    host                   = var.env == "aws" && length(data.aws_eks_cluster.cluster) > 0 ? data.aws_eks_cluster.cluster[0].endpoint : ""
    cluster_ca_certificate = var.env == "aws" && length(data.aws_eks_cluster.cluster) > 0 ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data) : ""
    token                  = var.env == "aws" && length(data.aws_eks_cluster_auth.cluster) > 0 ? data.aws_eks_cluster_auth.cluster[0].token : ""
    config_path            = var.env == "kind" ? pathexpand(var.k8s_config_path) : ""
  }
}