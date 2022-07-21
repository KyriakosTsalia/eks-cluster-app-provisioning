variable "env" {
  type        = string
  description = "Defines whether the K8S cluster runs remotely on AWS or locally with kind."
  default     = "aws"

  validation {
    condition     = var.env == "aws" || var.env == "kind"
    error_message = "The env value must be one of two possible values, \"aws\" or \"kind\"."
  }
}

variable "AWS_REGION" {
  type    = string
  default = "eu-central-1"
}

variable "k8s_config_path" {
  type    = string
  default = "~/.kube/config"
}