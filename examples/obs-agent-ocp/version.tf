terraform {
  required_version = ">= 1.9.0"

  # Ensure that there is always 1 example locked into the lowest provider version of the range defined in the main
  # module's version.tf (obs-agent-iks), and 1 example that will always use the latest provider version (this example).
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      version = ">= 1.79.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 3.0.0, <4.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.16.1"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = ">= 2.0.1"
    }
  }
}
