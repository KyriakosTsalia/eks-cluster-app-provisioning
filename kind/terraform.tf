terraform {
  required_providers {
    kind = {
      source  = "kyma-incubator/kind"
      version = "0.0.11"
    }
    docker-utils = {
      source  = "Kaginari/docker-utils"
      version = "0.0.5"
    }
  }
}