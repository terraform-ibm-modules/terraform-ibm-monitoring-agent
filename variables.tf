##############################################################################
# Cluster variables
##############################################################################

variable "cluster_id" {
  type        = string
  description = "The ID of the cluster you wish to deploy the agent in."
  nullable    = false
}

variable "cluster_resource_group_id" {
  type        = string
  description = "The resource group ID of the cluster."
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
  description = "Specify true if the target cluster is a VPC cluster, false if it is a classic cluster."
  type        = bool
  default     = true
  nullable    = false
}

variable "wait_till" {
  description = "To avoid long wait times when you run your Terraform code, you can specify the stage when you want Terraform to mark the cluster resource creation as completed. Depending on what stage you choose, the cluster creation might not be fully completed and continues to run in the background. However, your Terraform code can continue to run without waiting for the cluster to be fully created. Supported values are `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady` and `Normal`"
  type        = string
  default     = "Normal"
  nullable    = false

  validation {
    error_message = "'wait_till' value must be one of 'MasterNodeReady', 'OneWorkerNodeReady', 'IngressReady' or 'Normal'."
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
  nullable    = false
}

##############################################################################
# Common agent variables
##############################################################################

variable "instance_region" {
  type        = string
  description = "The region of the IBM Cloud Monitoring instance that you want to send metrics to. The region value is used to construct the ingestion and api endpoints. If you are only using the agent for security and compliance monitoring, set this to the region of your IBM Cloud Security and Compliance Center Workload Protection instance. If you have both Cloud Monitoring and Security and Compliance Center Workload Protection instances, the instances must be connected and must be in the same region to use the same agent."
  nullable    = false
}

variable "use_private_endpoint" {
  type        = bool
  description = "Whether send data over a private endpoint or not. To use a private endpoint, you must enable virtual routing and forwarding (VRF) for your account. See https://cloud.ibm.com/docs/account?topic=account-vrf-service-endpoint."
  default     = true
  nullable    = false
}

variable "use_scc_wp_endpoint" {
  type        = bool
  description = "By default an IBM Cloud Monitoring endpoint is used and is constructed from the `instance_region` and `use_private_endpoint` inputs. To use an IBM Cloud Security and Compliance Center Workload Protection endpoint instead, set this to true."
  default     = false
  nullable    = false
}

variable "access_key" {
  type        = string
  description = "Access key used by the agent to communicate with the instance. Either `access_key` or `existing_access_key_secret_name` is required. This value will be stored in a new secret on the cluster if passed. If you want to use this agent for only metrics or metrics with security and compliance, use a manager key scoped to the IBM Cloud Monitoring instance. If you only want to use the agent for security and compliance use a manager key scoped to the Security and Compliance Center Workload Protection instance."
  sensitive   = true
  default     = null
  validation {
    condition = (
      (var.access_key != null && var.access_key != "") ||
      (var.existing_access_key_secret_name != null && var.existing_access_key_secret_name != "")
    )
    error_message = "Either 'access_key' or 'existing_access_key_secret_name' must be provided and non-empty."
  }
}

variable "existing_access_key_secret_name" {
  type        = string
  description = "An alternative to using `access_key`. Specify the name of an existing Kubernetes secret containing the access key in the same namespace that is defined in the `namespace` input. Either `access_key` or `existing_access_key_secret_name` is required."
  default     = null
}

variable "name" {
  description = "The name to give the agent helm release."
  type        = string
  default     = "sysdig-agent"
}

variable "agent_tags" {
  description = "Map of tags to associate to the agent. For example, {\"environment\": \"production\"}. NOTE: Use the `add_cluster_name` boolean variable to add the cluster name as a tag."
  type        = map(string)
  default     = {}
}

variable "add_cluster_name" {
  type        = bool
  description = "If true, configure the agent to associate a tag containing the cluster name. This tag is added in the format `ibm-containers-kubernetes-cluster-name: cluster_name`."
  default     = true
}

variable "namespace" {
  type        = string
  description = "Namespace to deploy the agent to."
  default     = "ibm-observe"
  nullable    = false
}

variable "tolerations" {
  description = "List of tolerations to apply to the agent."
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
  description = "The name of the Helm chart to deploy. Use `chart_location` to specify helm chart location."
  type        = string
  default     = "sysdig-deploy"
  nullable    = false
}

variable "chart_location" {
  description = "The location of the agent helm chart."
  type        = string
  default     = "https://charts.sysdig.com"
  nullable    = false
}

variable "chart_version" {
  description = "The version of the agent helm chart to deploy."
  type        = string
  # This version is automatically managed by renovate automation - do not remove the registryUrl comment on next line
  default  = "1.89.3" # registryUrl: charts.sysdig.com
  nullable = false
}

variable "image_registry_base_url" {
  description = "The image registry base URL to pull all images from. For example `icr.io` or `quay.io`."
  type        = string
  default     = "icr.io"
  nullable    = false
}

variable "image_registry_namespace" {
  description = "The namespace within the image registry to pull all images from."
  type        = string
  default     = "ext/sysdig"
  nullable    = false
}

variable "agent_image_repository" {
  description = "The image repository to pull the agent image from."
  type        = string
  default     = "agent-slim"
  nullable    = false
}

variable "agent_image_tag_digest" {
  description = "The image tag or digest of agent image to use. If using digest, it must be in the format of `X.Y.Z@sha256:xxxxx`."
  type        = string
  # This version is automatically managed by renovate automation - do not remove the datasource comment on next line
  default  = "14.0.1@sha256:b1f5bf4677632c715e9a5cde9af8d36dd66f5e79c80aadfd4b74dc5cc310a570" # datasource: icr.io/ext/sysdig/agent-slim
  nullable = false
}

variable "kernel_module_image_tag_digest" {
  description = "The image tag or digest to use for the agent kernel module used by the initContainer. If using digest, it must be in the format of `X.Y.Z@sha256:xxxxx`"
  type        = string
  # This version is automatically managed by renovate automation - do not remove the datasource comment on next line
  default  = "14.0.1@sha256:9b1e900e2cd47cabe31b36f6ed41705b33e849de0639b29b326fb73e67ed8b68" # datasource: icr.io/ext/sysdig/agent-kmodule
  nullable = false
}

variable "kernal_module_image_repository" {
  description = "The image repository to pull the agent kernal module initContainer image from."
  type        = string
  default     = "agent-kmodule"
  nullable    = false
}

variable "agent_requests_cpu" {
  type        = string
  description = "Specify CPU resource requests for the agent. For more info, see https://cloud.ibm.com/docs/monitoring?topic=monitoring-resource_requirements"
  default     = "1"
}

variable "agent_limits_cpu" {
  type        = string
  description = "Specify CPU resource limits for the agent. For more info, see https://cloud.ibm.com/docs/monitoring?topic=monitoring-resource_requirements"
  default     = "1"
}

variable "agent_requests_memory" {
  type        = string
  description = "Specify memory resource requests for the agent. For more info, see https://cloud.ibm.com/docs/monitoring?topic=monitoring-resource_requirements"
  default     = "1024Mi"
}

variable "agent_limits_memory" {
  type        = string
  description = "Specify memory resource limits for the agent. For more info, see https://cloud.ibm.com/docs/monitoring?topic=monitoring-resource_requirements"
  default     = "1024Mi"
}

variable "enable_universal_ebpf" {
  type        = bool
  description = "Deploy monitoring agent with universal extended Berkeley Packet Filter (eBPF) enabled. It requires kernel version 5.8+. Learn more: https://github.com/terraform-ibm-modules/terraform-ibm-monitoring-agent/blob/main/solutions/fully-configurable/DA-docs.md#when-to-enable-enable_universal_ebpf"
  default     = true
}

variable "deployment_tag" {
  type        = string
  description = "Sets a global tag that will be included in the components. It represents the mechanism from where the components have been installed (terraform, local...)."
  default     = "terraform"
}

##############################################################################
# Metrics related variables
##############################################################################

variable "blacklisted_ports" {
  type        = list(number)
  description = "To block network traffic and metrics from network ports, pass the list of ports from which you want to filter out any data. For more info, see https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_agent#ports"
  default     = []
}

variable "metrics_filter" {
  type = list(object({
    include = optional(string)
    exclude = optional(string)
  }))
  description = "To filter custom metrics you can specify which metrics to include and exclude. For more info, see https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics"
  default     = []
  # TODO: Add variable validation to ensure only include or exclude is in each item - not both
}

variable "container_filter" {
  type = list(object({
    type      = string
    parameter = string
    name      = string
  }))
  description = "Customize the agent to exclude containers from metrics collection. For more info, see https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_filter_data"
  default     = []
  validation {
    condition     = length(var.container_filter) == 0 || can(regex("^(include|exclude)$", var.container_filter[0].type))
    error_message = "Invalid input for 'container_filter'. Valid options for 'type' are: `include` and `exclude`."
  }
}

##############################################################################
# SCC-WP related variables
##############################################################################

variable "enable_host_scanner" {
  type        = bool
  description = "Enable host scanning to detect vulnerabilities and identify the resolution priority based on available fixed versions and severity. Requires a Security and Compliance Center Workload Protection instance to view results."
  default     = true
}

variable "enable_kspm_analyzer" {
  type        = bool
  description = "Enable Kubernetes Security Posture Management (KSPM) analyzer. Requires a Security and Compliance Center Workload Protection instance to view results."
  default     = true
}

variable "cluster_shield_deploy" {
  type        = bool
  description = "Deploy the Cluster Shield component to provide runtime detection and policy enforcement for Kubernetes workloads. If enabled, a Kubernetes Deployment will be deployed to your cluster using helm."
  default     = true
}

variable "cluster_shield_image_tag_digest" {
  description = "The image tag or digest to pull for the Cluster Shield component. If using digest, it must be in the format of `X.Y.Z@sha256:xxxxx`."
  type        = string
  # This version is automatically managed by renovate automation - do not remove the datasource comment on next line
  default = "1.13.0@sha256:0c8ee65a473e51b2a2c7bddf4e89008299cf203c50cd80fd97503cb121c1230a" # datasource: icr.io/ext/sysdig/cluster-shield
}

variable "cluster_shield_image_repository" {
  description = "The image repository to pull the Cluster Shield image from."
  type        = string
  default     = "cluster-shield"
}

variable "cluster_shield_requests_cpu" {
  type        = string
  description = "Specify CPU resource requests for the cluster shield pods."
  default     = "500m"
}

variable "cluster_shield_limits_cpu" {
  type        = string
  description = "Specify CPU resource limits for the cluster shield pods."
  default     = "1500m"
}

variable "cluster_shield_requests_memory" {
  type        = string
  description = "Specify memory resource requests for the cluster shield pods."
  default     = "512Mi"
}

variable "cluster_shield_limits_memory" {
  type        = string
  description = "Specify memory resource limits for the cluster shield pods."
  default     = "1536Mi"
}
