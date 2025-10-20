##############################################################################
# Cluster variables
##############################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API key."
  sensitive   = true
}

variable "prefix" {
  type        = string
  nullable    = true
  description = "The prefix to add to all resources that this solution creates (e.g `prod`, `test`, `dev`). To skip using a prefix, set this value to null or an empty string. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/prefix.md)."

  validation {
    # - null and empty string is allowed
    # - Must not contain consecutive hyphens (--): length(regexall("--", var.prefix)) == 0
    # - Starts with a lowercase letter: [a-z]
    # - Contains only lowercase letters (a–z), digits (0–9), and hyphens (-)
    # - Must not end with a hyphen (-): [a-z0-9]
    condition = (var.prefix == null || var.prefix == "" ? true :
      alltrue([
        can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.prefix)),
        length(regexall("--", var.prefix)) == 0
      ])
    )
    error_message = "Prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It must not end with a hyphen('-'), and cannot contain consecutive hyphens ('--')."
  }

  validation {
    # must not exceed 16 characters in length
    condition     = var.prefix == null || var.prefix == "" ? true : length(var.prefix) <= 16
    error_message = "Prefix must not exceed 16 characters."
  }
}

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

variable "instance_crn" {
  type        = string
  description = "The CRN of the IBM Cloud Monitoring instance that you want to send metrics to. This is used to construct the ingestion and api endpoints. If you are only using the agent for security and compliance monitoring, set this to the crn of your IBM Cloud Security and Compliance Center Workload Protection instance. If you are using this agent for both `monitoring` and `security and compliance` you can provide CRN of any one of them provided they are connected. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-monitoring-agent/blob/main/solutions/fully-configurable/DA-docs.md#key-considerations)."
  nullable    = false

  validation {
    condition     = var.instance_crn != ""
    error_message = "Instance CRN can not be empty."
  }
}

variable "use_private_endpoint" {
  type        = bool
  description = "Whether send data over a private endpoint or not. To use a private endpoint, you must enable [virtual routing and forwarding (VRF)](https://cloud.ibm.com/docs/account?topic=account-vrf-service-endpoint) for your account."
  default     = true
  nullable    = false
}

variable "access_key" {
  type        = string
  description = "Access key used by the agent to communicate with the instance. This value will be stored in a new secret on the cluster if passed. If you want to use this agent for only metrics or metrics with security and compliance, use a manager key scoped to the IBM Cloud Monitoring instance. If you only want to use the agent for security and compliance use a manager key scoped to the Security and Compliance Center Workload Protection instance. If neither `access_key` nor `existing_access_key_secret_name` is provided a new Manager Key will be created scoped to the instance provided in `instance_crn`."
  sensitive   = true
  default     = null
}

variable "existing_access_key_secret_name" {
  type        = string
  description = "An alternative to using `access_key`. Specify the name of an existing Kubernetes secret containing the access key in the same namespace that is defined in the `namespace` input. If neither `access_key` nor `existing_access_key_secret_name` is provided a new Manager Key will be created scoped to the instance provided in `instance_crn`."
  default     = null
}

variable "name" {
  description = "The name to give the helm release."
  type        = string
  default     = "sysdig-agent"
}

variable "agent_tags" {
  description = "Map of tags to associate to the agent. For example, `{\"environment\": \"production\"}`. NOTE: Use the `add_cluster_name` boolean variable to add the cluster name as a tag."
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
  description = "List of tolerations to apply to the agent. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-monitoring-agent/blob/main/solutions/fully-configurable/DA-types.md#tolerations)."
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
  default  = "1.95.5" # registryUrl: charts.sysdig.com
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
  default  = "14.2.2@sha256:8b9768427392315619c9f14a365e7461bb06c0b8b606a9dfee2e87dd32380c4b" # datasource: icr.io/ext/sysdig/agent-slim
  nullable = false
}

variable "kernel_module_image_tag_digest" {
  description = "The image tag or digest to use for the agent kernel module used by the initContainer. If using digest, it must be in the format of `X.Y.Z@sha256:xxxxx`"
  type        = string
  # This version is automatically managed by renovate automation - do not remove the datasource comment on next line
  default  = "14.2.2@sha256:934c151ccc3bb12e2d5764ea2211afd052717a70628e7f4ca164ea553e38b373" # datasource: icr.io/ext/sysdig/agent-kmodule
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
  description = "Specify CPU resource requests for the agent. [Learn more](https://cloud.ibm.com/docs/monitoring?topic=monitoring-resource_requirements)."
  default     = "1"
}

variable "agent_limits_cpu" {
  type        = string
  description = "Specify CPU resource limits for the agent. [Learn more](https://cloud.ibm.com/docs/monitoring?topic=monitoring-resource_requirements)."
  default     = "1"
}

variable "agent_requests_memory" {
  type        = string
  description = "Specify memory resource requests for the agent. [Learn more](https://cloud.ibm.com/docs/monitoring?topic=monitoring-resource_requirements)."
  default     = "1024Mi"
}

variable "agent_limits_memory" {
  type        = string
  description = "Specify memory resource limits for the agent. [Learn more](https://cloud.ibm.com/docs/monitoring?topic=monitoring-resource_requirements)."
  default     = "1024Mi"
}

variable "enable_universal_ebpf" {
  type        = bool
  description = "Deploy monitoring agent with universal extended Berkeley Packet Filter (eBPF) enabled. It requires kernel version 5.8+. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-monitoring-agent/blob/main/solutions/fully-configurable/DA-docs.md#when-to-enable-enable_universal_ebpf)."
  default     = true
}

variable "deployment_tag" {
  type        = string
  description = "Sets a global tag that will be included in the components. It represents the mechanism from where the components have been installed (terraform, local...)."
  default     = "terraform"
}

variable "max_unavailable" {
  type        = string
  description = "The maximum number of pods that can be unavailable during a DaemonSet rolling update. Accepts absolute number or percentage (e.g., '1' or '10%')."
  default     = "1"
  nullable    = false
}

variable "max_surge" {
  type        = string
  description = "The number of pods that can be created above the desired amount of daemonset pods during an update. If `max_surge` is set to null, the `max_surge` setting is ignored. The variable accepts absolute number or percentage value(e.g., '1' or '10%')."
  default     = null
}

variable "priority_class_name" {
  type        = string
  description = "The priority class name for the PriorityClasses assigned to the monitoring agent daemonset. If no value is passed, priority class is not used."
  default     = null
}

variable "priority_class_value" {
  type        = number
  nullable    = false
  description = "The numerical priority assigned to PriorityClass, which determines the importance of monitoring agent daemonset pod within the cluster for both scheduling and eviction decisions. The value only applies if a value was passed for `priority_class_name`"
  default     = 10
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
  description = "To filter custom metrics you can specify which metrics to include and exclude. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-monitoring-agent/blob/main/solutions/fully-configurable/DA-types.md#metrics_filter)."
  default     = []
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
  default = "1.16.1@sha256:a9263bff3bbf22dc3594f83029562e3a0036f08d3978b1bd3f7ddeeb397921c7" # datasource: icr.io/ext/sysdig/cluster-shield
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

variable "prometheus_config" {
  description = "Prometheus configuration for the agent. If you want to enable Prometheus configuration provide the prometheus.yaml file content in `hcl` format. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-monitoring-agent/blob/main/solutions/fully-configurable/DA-types.md#prometheus_config)."
  type        = map(any)
  default     = {}
  nullable    = false
}

variable "provider_visibility" {
  description = "Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints)."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private", "public-and-private"], var.provider_visibility)
    error_message = "Invalid visibility option. Allowed values are 'public', 'private', or 'public-and-private'."
  }
}
