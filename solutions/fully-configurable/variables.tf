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
  description = "Access key used by the IBM Cloud Monitoring agent to communicate with the instance. Either `access_key` or `existing_access_key_secret_name` is required. This value will be stored on a new secret on the cluster if passed."
  sensitive   = true
  default     = null
}

variable "existing_access_key_secret_name" {
  type        = string
  description = "An alternative to using the Sysdig Agent access key. Specify the name of a Kubernetes secret containing an access-key entry."
  default     = null
  validation {
    condition = (
      (var.access_key != null && var.access_key != "") ||
      (var.existing_access_key_secret_name != null && var.existing_access_key_secret_name != "")
    )
    error_message = "Either `access_key` or `existing_access_key_secret_name` must be provided and non-empty."
  }
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

variable "blacklisted_ports" {
  type        = list(number)
  description = "To block network traffic and metrics from network ports, pass the list of ports from which you want to filter out any data. [Learn more](https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_block_ports)."
  default     = []
}

variable "metrics_filter" {
  type = list(object({
    include = optional(string)
    exclude = optional(string)
  }))
  description = "To filter on custom metrics, specify the IBM Cloud Monitoring metrics to include or exclude. [Learn more](https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics) and [here](https://github.com/terraform-ibm-modules/terraform-ibm-monitoring-agent/tree/main/solutions/fully-configurable/DA-types.md)."
  default     = [] # [{ exclude = "metricA.*", include = "metricB.*" }]
}

variable "agent_tags" {
  description = "Map of tags to associate to all metrics that the agent collects. NOTE: Use the `add_cluster_name` boolean variable to add the cluster name as a tag, e.g `{'environment': 'production'}."
  type        = map(string)
  default     = {}
}

variable "add_cluster_name" {
  type        = bool
  description = "If true, configure the cloud monitoring agent to attach a tag containing the cluster name to all metric data. This tag is added in the format `ibm-containers-kubernetes-cluster-name: cluster_name`."
  default     = true
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
  default     = "1.85.3" # registryUrl: charts.sysdig.com
  nullable    = false
}

variable "image_registry_base_url" {
  description = "The image registry base URL to pull the Cloud Monitoring agent images from. For example `icr.io`, `quay.io`, etc."
  type        = string
  default     = "icr.io"
  nullable    = false
}

variable "image_registry_namespace" {
  description = "The namespace within the image registry to pull the Cloud Monitoring agent images from."
  type        = string
  default     = "ext/sysdig"
  nullable    = false
}

variable "agent_image_repository" {
  description = "The image repository to pull the Cloud Monitoring agent image from."
  type        = string
  default     = "agent-slim"
  nullable    = false
}

variable "agent_image_tag_digest" {
  description = "The namespace within the image registry to pull the Cloud Monitoring agent images from."
  type        = string
  default     = "13.9.2@sha256:0dcdb6d70bab60dae4bf5f70c338f2feb9daeba514f1b8ad513ed24724c2a04d" # datasource: icr.io/ext/sysdig/agent-slim
  nullable    = false
}

variable "kernel_module_image_tag_digest" {
  description = "The image tag digest to use for the Cloud Monitoring agent kernel module used by the initContainer."
  type        = string
  default     = "13.9.2@sha256:a6b301f24557c5e14ab5abe62577340e7ab33ce11f33cfcd4797296d1603184a" # datasource: icr.io/ext/sysdig/agent-kmodule
  nullable    = false
}

variable "kernal_module_image_repository" {
  description = "The image repository to pull the Cloud Monitoring agent kernal module initContainer image from."
  type        = string
  default     = "agent-kmodule"
  nullable    = false
}

########################################################################################################################
# Resource Management Variables
########################################################################################################################

variable "agent_requests_cpu" {
  type        = string
  description = "Specifies the CPU requested to run in a node for the agent."
  default     = "1"
}

variable "agent_limits_cpu" {
  type        = string
  description = "Specifies the CPU limit for the agent."
  default     = "1"
}

variable "agent_requests_memory" {
  type        = string
  description = "Specifies the memory requested to run in a node for the agent."
  default     = "1024Mi"
}

variable "agent_limits_memory" {
  type        = string
  description = "Specifies the memory limit for the agent."
  default     = "1024Mi"
}
