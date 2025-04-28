variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API key."
  sensitive   = true
}

##############################################################################
# Cluster variables
##############################################################################

variable "cluster_id" {
  type        = string
  description = "The ID of the cluster to deploy the agent in."
  nullable    = false
}

variable "cluster_resource_group_id" {
  type        = string
  description = "The resource group ID of the cluster."
  nullable    = false
}

variable "cluster_config_endpoint_type" {
  description = "Specify the type of endpoint to use to access the cluster configuration. Possible values: `default`, `private`, `vpe`, `link`. The `default` value uses the default endpoint of the cluster."
  type        = string
  default     = "private"
  nullable    = false # use default if null is passed in
}

variable "is_vpc_cluster" {
  type        = bool
  description = "Specify true if the target cluster for the DA is a VPC cluster, false if it is classic cluster."
  default     = true
}

variable "wait_till" {
  description = "Specify the stage when Terraform should mark the cluster resource creation as completed. Supported values: `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady`, `Normal`."
  type        = string
  default     = "Normal"
}

variable "wait_till_timeout" {
  description = "Timeout for wait_till in minutes."
  type        = number
  default     = 90
}

##############################################################################
# Cloud Monitoring variables
##############################################################################

variable "access_key" {
  type        = string
  description = "The access key that is used by the IBM Cloud Monitoring agent to communicate with the instance."
  sensitive   = true
  nullable    = false
}

variable "cloud_monitoring_instance_region" {
  type        = string
  description = "The name of the region where the IBM Cloud Monitoring instance is created. This name is used to construct the ingestion endpoint."
  nullable    = false
}

variable "cloud_monitoring_instance_endpoint_type" {
  type        = string
  description = "Specify the IBM Cloud Monitoring instance endpoint type (`public` or `private`) to use to construct the ingestion endpoint."
  default     = "private"
}

variable "metrics_filter" {
  type = list(object({
    type = string
    name = string
  }))
  description = "To filter on custom metrics, specify the IBM Cloud Monitoring metrics to include or exclude. [Learn more](https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics) and [here](https://github.com/terraform-ibm-modules/terraform-ibm-monitoring-agent/tree/main/solutions/fully-configurable/DA-types.md)."
  default     = [] # [{ type = "exclude", name = "metricA.*" }, { type = "include", name = "metricB.*" }]
}

variable "name" {
  description = "The name of the IBM Cloud Monitoring agent that is used to name the Kubernetes and Helm resources on the cluster."
  type        = string
  default     = "sysdig-agent"
}

variable "namespace" {
  type        = string
  description = "The namespace to deploy the IBM Cloud Monitoring agent in. Default value: `ibm-observe`."
  default     = "ibm-observe"
  nullable    = false
}

variable "tolerations" {
  description = "The list of tolerations to apply to the IBM Cloud Monitoring agent. The default operator value `Exists` matches any taint on any node except the master node. [Learn more](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)"
  type = list(object({
    key               = optional(string)
    operator          = optional(string)
    value             = optional(string)
    effect            = optional(string)
    tolerationSeconds = optional(number)
  }))
  default = [
    {
      operator = "Exists"
    },
    {
      operator = "Exists"
      effect   = "NoSchedule"
      key      = "node-role.kubernetes.io/master"
    }
  ]
}

variable "chart" {
  description = "The name of the Helm chart to deploy."
  type        = string
  default     = "sysdig-deploy" # Replace with the actual chart location if different
  nullable    = false
}

variable "chart_location" {
  description = "The location of the Cloud Monitoring agent helm chart."
  type        = string
  default     = "https://charts.sysdig.com" # Replace with the actual repository URL if different
  nullable    = false
}

variable "chart_version" {
  description = "The version of the Cloud Monitoring agent helm chart to deploy."
  type        = string
  default     = "1.80.3" # registryUrl: charts.sysdig.com
  nullable    = false
}

variable "image_registry" {
  description = "The image registry to use for the Cloud Monitoring agent."
  type        = string
  default     = "icr.io/ext/sysdig/agent"
  nullable    = false
}

variable "image_tag_digest" {
  description = "The image tag digest to use for the Cloud Monitoring agent."
  type        = string
  default     = "13.8.1@sha256:e5d1c63edf07c9f861249432c00873e32141381c15fbcff80b90a12b272dc0b9" # datasource: icr.io/ext/sysdig/agent
  nullable    = false
}
