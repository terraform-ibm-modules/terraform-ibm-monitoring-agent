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
  # LOCALS
  cluster_name   = var.is_vpc_cluster ? data.ibm_container_vpc_cluster.cluster[0].resource_name : data.ibm_container_cluster.cluster[0].resource_name # Not publically documented in provider. See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4485
  collector_host = var.cloud_monitoring_instance_endpoint_type == "private" ? "ingest.private.${var.cloud_monitoring_instance_region}.monitoring.cloud.ibm.com" : "ingest.${var.cloud_monitoring_instance_region}.monitoring.cloud.ibm.com"
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

  set {
    name  = "agent.collectorSettings.collectorHost"
    type  = "string"
    value = local.collector_host
  }
  set {
    name  = "agent.slim.image.repository"
    type  = "string"
    value = var.agent_image_repository
  }
  set {
    name  = "agent.slim.kmoduleImage.repository"
    type  = "string"
    value = var.kernal_module_image_repository
  }
  set {
    name  = "agent.slim.enabled"
    value = true
  }
  set_sensitive {
    name  = "global.sysdig.accessKey"
    type  = "string"
    value = var.access_key
  }
  dynamic "set" {
    for_each = var.access_key_secret_name != null && var.access_key_secret_name != "" ? [1] : []
    content {
      name  = "global.sysdig.accessKeySecret"
      type  = "string"
      value = var.access_key_secret_name
    }
  }
  set {
    name  = "global.clusterConfig.name"
    type  = "string"
    value = local.cluster_name
  }
  set {
    name  = "agent.image.registry"
    type  = "string"
    value = var.image_registry_base_url
  }
  set {
    name  = "Values.image.repository"
    type  = "string"
    value = var.image_registry_base_url
  }
  set {
    name  = "global.imageRegistry"
    type  = "string"
    value = "${var.image_registry_base_url}/${var.image_registry_namespace}"
  }
  set {
    name  = "agent.image.tag"
    type  = "string"
    value = var.agent_image_tag_digest
  }
  set {
    name  = "agent.resources.requests.cpu"
    type  = "string"
    value = var.agent_requests_cpu
  }
  set {
    name  = "agent.resources.requests.memory"
    type  = "string"
    value = var.agent_requests_memory
  }
  set {
    name  = "agent.resources.limits.cpu"
    type  = "string"
    value = var.agent_limits_cpu
  }
  set {
    name  = "agent.resources.limits.memory"
    type  = "string"
    value = var.agent_limits_memory
  }
  set {
    name  = "agent.slim.kmoduleImage.digest"
    type  = "string"
    value = regex("@(.*)", var.kernel_module_image_tag_digest)[0]
  }
  # Specific to SCC WP, enabled by default
  set {
    name  = "nodeAnalyzer.enabled"
    type  = "auto"
    value = false
  }

  # Values to be passed to the agent config map, e.g `kubectl describe configmap sysdig-agent -n ibm-observe`
  values = [
    yamlencode({
      agent = {
        sysdig = {
          settings = {
            blacklisted_ports = var.blacklisted_ports
            metrics_filter    = var.metrics_filter
            container_filter  = var.container_filter
          }
          tags = merge(
            var.agent_tags,
            var.add_cluster_name ? {
              "ibm-containers-kubernetes-cluster-name" = local.cluster_name
            } : {}
          )
        },
        tolerations = var.tolerations
      }
    })
  ]

  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-rollout-status.sh ${var.name} ${var.namespace}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}
