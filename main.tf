##############################################################################
# terraform-ibm-monitoring-agent
##############################################################################

# Lookup cluster name from ID. The is_vpc_cluster variable defines whether to use the VPC data block or the Classic data block
data "ibm_container_vpc_cluster" "cluster" {
  count             = var.is_vpc_cluster ? 1 : 0
  name              = var.cluster_id
  resource_group_id = var.cluster_resource_group_id
  wait_till         = var.wait_till
  wait_till_timeout = var.wait_till_timeout
}

data "ibm_container_cluster" "cluster" {
  count             = var.is_vpc_cluster ? 0 : 1
  name              = var.cluster_id
  resource_group_id = var.cluster_resource_group_id
  wait_till         = var.wait_till
  wait_till_timeout = var.wait_till_timeout
}

# Download cluster config which is required to connect to cluster
data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = var.is_vpc_cluster ? data.ibm_container_vpc_cluster.cluster[0].name : data.ibm_container_cluster.cluster[0].name
  resource_group_id = var.cluster_resource_group_id
  config_dir        = "${path.module}/kubeconfig"
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null # null value represents default
}

locals {
  cluster_name         = var.is_vpc_cluster ? data.ibm_container_vpc_cluster.cluster[0].resource_name : data.ibm_container_cluster.cluster[0].resource_name # Not publicly documented in provider. See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4485
  use_container_filter = length(var.container_filter) < 0 || var.container_filter == null ? false : true
  # construct ingestion and api endpoints based on inputs
  monitoring_api_endpoint = "${var.instance_region}.monitoring.cloud.ibm.com"
  scc_wp_api_endpoint     = "${var.instance_region}.security-compliance-secure.cloud.ibm.com"
  base_endpoint           = var.use_scc_wp_endpoint ? local.scc_wp_api_endpoint : local.monitoring_api_endpoint
  ingestion_endpoint      = var.use_private_endpoint ? "ingest.private.${local.base_endpoint}" : "ingest.${local.base_endpoint}"
  api_host                = replace(local.ingestion_endpoint, "ingest.", "")
  dynamic_set_access_key_secret = var.existing_access_key_secret_name != null && var.existing_access_key_secret_name != "" ? [{
    name  = "global.sysdig.accessKeySecret"
    type  = "string"
    value = var.existing_access_key_secret_name
  }] : []
  dynamic_agent_tags = [for k, v in var.agent_tags :
    {
      name  = "global.sysdig.tags.${k}"
      value = v
    }
  ]
}

resource "helm_release" "cloud_monitoring_agent" {
  name             = var.name
  chart            = var.chart
  repository       = var.chart_location
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true
  timeout          = 1200
  wait             = true
  recreate_pods    = true
  force_update     = true
  reset_values     = true

  set = concat([
    # Values
    {
      name  = "Values.image.repository"
      type  = "string"
      value = var.image_registry_base_url
    },
    # Global
    {
      name  = "global.imageRegistry"
      type  = "string"
      value = "${var.image_registry_base_url}/${var.image_registry_namespace}"
    },
    {
      name  = "global.sysdig.apiHost"
      value = local.api_host
    },
    {
      name  = "global.clusterConfig.name"
      type  = "string"
      value = local.cluster_name
    },
    {
      name  = "global.sysdig.tags.deployment"
      type  = "string"
      value = var.deployment_tag
    },
    {
      name  = "global.sysdig.tags.ibm-containers-kubernetes-cluster-name"
      type  = "string"
      value = var.add_cluster_name ? local.cluster_name : null
    },
    # Cluster shield
    {
      name  = "clusterShield.enabled"
      value = var.cluster_shield_deploy
    },
    {
      name  = "clusterShield.image.repository"
      value = var.cluster_shield_image_repository
    },
    {
      name  = "clusterShield.image.tag"
      value = var.cluster_shield_image_tag_digest
    },
    {
      name  = "clusterShield.resources.requests.cpu"
      type  = "string"
      value = var.cluster_shield_requests_cpu
    },
    {
      name  = "clusterShield.resources.requests.memory"
      type  = "string"
      value = var.cluster_shield_requests_memory
    },
    {
      name  = "clusterShield.resources.limits.cpu"
      type  = "string"
      value = var.cluster_shield_limits_cpu
    },
    {
      name  = "clusterShield.resources.limits.memory"
      type  = "string"
      value = var.cluster_shield_limits_memory
    },
    {
      name  = "clusterShield.cluster_shield.sysdig_endpoint.region"
      type  = "string"
      value = "custom"
    },
    {
      name  = "clusterShield.cluster_shield.log_level"
      type  = "string"
      value = "info"
    },
    {
      name  = "clusterShield.cluster_shield.features.admission_control.enabled"
      value = var.cluster_shield_deploy
    },
    {
      name  = "clusterShield.cluster_shield.features.container_vulnerability_management.enabled"
      value = var.cluster_shield_deploy
    },
    {
      name  = "clusterShield.cluster_shield.features.audit.enabled"
      value = var.cluster_shield_deploy
    },
    {
      name  = "clusterShield.cluster_shield.features.posture.enabled"
      value = var.cluster_shield_deploy
    },
    # nodeAnalyzer has been replaced by the host_scanner and kspm_analyzer functionality of main agent daemonset
    {
      name  = "nodeAnalyzer.enabled"
      value = false
    },
    # clusterScanner has been replaced by cluster_shield component
    {
      name  = "clusterScanner.enabled"
      value = false
    }
  ], local.dynamic_agent_tags, local.dynamic_set_access_key_secret)

  set_sensitive = var.access_key != null && var.access_key != "" ? [{
    name  = "global.sysdig.accessKey"
    type  = "string"
    value = var.access_key
  }] : []

  # Had to use raw yaml here instead of converting HCL to yaml due to this issue with boolean getting converted to string which sysdig helm chart rejects:
  # https://github.com/hashicorp/terraform-provider-helm/issues/1677
  values = [<<EOT
"agent":
  "collectorSettings":
    "collectorHost": ${local.ingestion_endpoint}
  "slim":
    "image":
      "repository": ${var.agent_image_repository}
    "kmoduleImage":
      "repository": ${var.kernal_module_image_repository}
      "tag": ${var.kernel_module_image_tag_digest}
  "image":
    "registry": ${var.image_registry_base_url}
    "tag": ${var.agent_image_tag_digest}
  "resources":
    "requests":
      "cpu": ${var.agent_requests_cpu}
      "memory": ${var.agent_requests_memory}
    "limits":
      "cpu": ${var.agent_limits_cpu}
      "memory": ${var.agent_limits_memory}
  "ebpf":
    "enabled": ${var.enable_universal_ebpf}
    "kind": "universal_ebpf"
  "tolerations":
%{for toleration in var.tolerations~}
    -%{if toleration.key != null} key: "${toleration.key}"%{endif}
%{if toleration.operator != null}      operator: "${toleration.operator}"%{endif}
%{if toleration.value != null}      value: "${toleration.value}"%{endif}
%{if toleration.effect != null}      effect: "${toleration.effect}"%{endif}
%{if toleration.tolerationSeconds != null}      tolerationSeconds: ${toleration.tolerationSeconds}%{endif}
%{endfor~}
  "sysdig":
    "settings":
      "host_scanner":
        "enabled": ${var.enable_host_scanner}
      "kspm_analyzer":
        "enabled": ${var.enable_kspm_analyzer}
      "sysdig_api_endpoint": ${local.api_host}
      "blacklisted_ports":
%{for port in var.blacklisted_ports~}
        - ${port}
%{endfor~}
      "metrics_filter":
%{for filter in var.metrics_filter~}
%{if filter.include != null~}
        - "include": ${filter.include}
%{endif~}
%{if filter.exclude != null~}
        - "exclude": ${filter.exclude}
%{endif~}
%{endfor~}
      "use_container_filter": ${local.use_container_filter}
      "container_filter":
%{for filter in var.container_filter~}
        - ${filter.type}:
            ${filter.parameter}: ${filter.name}
%{endfor~}
%{if var.enable_host_scanner || var.enable_kspm_analyzer~}
  "extraVolumes":
    "mounts":
    - "mountPath": "/host"
      "name": "root-vol"
      "readOnly": true
    - "mountPath": "/host/tmp"
      "name": "tmp-vol"
    "volumes":
    - "hostPath":
        "path": "/"
      "name": "root-vol"
    - "hostPath":
        "path": "/tmp"
      "name": "tmp-vol"
%{endif~}
  "prometheus":
    "file": ${length(var.prometheus_config) > 0}
    "yaml":
%{for line in split("\n", yamlencode(var.prometheus_config))~}
      ${line}
%{endfor~}
%{if var.priority_class_name != null}
  "createPriorityClass": true
  "priorityClassName": ${var.priority_class_name}
  "priorityClassValue": ${var.priority_class_value}
%{endif}
  "daemonset":
    "kmodule":
      "env": ${var.kmodule_env}
    "updateStrategy":
      "type": "RollingUpdate"
      "rollingUpdate":
        "maxUnavailable": ${var.max_unavailable}
%{if var.max_surge != null}
        "maxSurge": ${var.max_surge}
%{endif}
EOT
  ]

  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-rollout-status.sh ${var.name} ${var.namespace}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}
