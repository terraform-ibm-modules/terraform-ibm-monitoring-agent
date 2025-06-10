##############################################################################
# Cluster variables
##############################################################################

variable "cluster_id" {
  type        = string
  description = "The ID of the cluster you wish to deploy the agent in"
  nullable    = false
}

variable "cluster_resource_group_id" {
  type        = string
  description = "The Resource Group ID of the cluster"
  nullable    = false
}

variable "cluster_config_endpoint_type" {
  description = "Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster."
  type        = string
  default     = "default"
  nullable    = false # use default if null is passed in
  validation {
    error_message = "Invalid Endpoint Type! Valid values are 'default', 'private', 'vpe', or 'link'"
    condition     = contains(["default", "private", "vpe", "link"], var.cluster_config_endpoint_type)
  }
}

variable "is_vpc_cluster" {
  description = "Specify true if the target cluster for the monitoring agent is a VPC cluster, false if it is a classic cluster."
  type        = bool
  default     = true
}

variable "wait_till" {
  description = "To avoid long wait times when you run your Terraform code, you can specify the stage when you want Terraform to mark the cluster resource creation as completed. Depending on what stage you choose, the cluster creation might not be fully completed and continues to run in the background. However, your Terraform code can continue to run without waiting for the cluster to be fully created. Supported args are `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady` and `Normal`"
  type        = string
  default     = "Normal"

  validation {
    error_message = "`wait_till` value must be one of `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady` or `Normal`."
    condition = contains([
      "MasterNodeReady",
      "OneWorkerNodeReady",
      "IngressReady",
      "Normal"
    ], var.wait_till)
  }
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
  description = "Access key used by the IBM Cloud Monitoring agent to communicate with the instance. Either `access_key` or `existing_access_key_secret_name` is required."
  sensitive   = true
  default     = null
  validation {
    condition = (
      (var.access_key != null && var.access_key != "") ||
      (var.existing_access_key_secret_name != null && var.existing_access_key_secret_name != "")
    )
    error_message = "Either `access_key` or `existing_access_key_secret_name` must be provided and non-empty."
  }
}

variable "existing_access_key_secret_name" {
  type        = string
  description = "An alternative to using the Sysdig Agent `access_key`. Specify the name of a Kubernetes secret containing an access-key entry. Either `access_key` or `existing_access_key_secret_name` is required."
  default     = null
}

variable "cloud_monitoring_instance_region" {
  type        = string
  description = "The IBM Cloud Monitoring instance region. Used to construct the ingestion endpoint."
  nullable    = false
}

variable "cloud_monitoring_instance_endpoint_type" {
  type        = string
  description = "Specify the IBM Cloud Monitoring instance endpoint type (public or private) to use. Used to construct the ingestion endpoint."
  default     = "private"
  validation {
    error_message = "The specified endpoint type can be private or public only."
    condition     = contains(["private", "public"], var.cloud_monitoring_instance_endpoint_type)
  }
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
  description = "To filter custom metrics, specify the Cloud Monitoring metrics to include or to exclude. See https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics."
  default     = []
}

variable "container_filter" {
  type = list(object({
    type      = string
    parameter = string
    name      = string
  }))
  description = "To filter custom containers, specify which containers to include or exclude from metrics collection for the cloud monitoring agent. See https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_filter_data."
  default     = []
  validation {
    condition     = length(var.container_filter) == 0 || can(regex("^(include|exclude)$", var.container_filter[0].type))
    error_message = "Invalid input for `container_filter`. Valid options for 'type' are: `include` and `exclude`. If empty, no containers are included or excluded."
  }
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
  description = "Cloud Monitoring agent name. Used for naming all kubernetes and helm resources on the cluster."
  type        = string
  default     = "sysdig-agent"
}

variable "namespace" {
  type        = string
  description = "Namespace where to deploy the Cloud Monitoring agent. Default value is 'ibm-observe'"
  default     = "ibm-observe"
  nullable    = false
}

variable "tolerations" {
  description = "List of tolerations to apply to Cloud Monitoring agent."
  type = list(object({
    key               = optional(string)
    operator          = optional(string)
    value             = optional(string)
    effect            = optional(string)
    tolerationSeconds = optional(number)
  }))
  default = [{
    operator = "Exists"
    },
    {
      operator = "Exists"
      effect   = "NoSchedule"
      key      = "node-role.kubernetes.io/master"
  }]
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
  default     = "1.85.1" # registryUrl: charts.sysdig.com
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
  description = "The image tag digest to use for the Cloud Monitoring agent."
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
