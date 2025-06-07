##############################################################################
# Monitoring Agents
##############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = var.is_vpc_cluster ? data.ibm_container_vpc_cluster.cluster[0].name : data.ibm_container_cluster.cluster[0].name
  resource_group_id = var.cluster_resource_group_id
  config_dir        = "${path.module}/kubeconfig"
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null
}

module "monitoring_agent" {
  source                       = "../.."
  cluster_id                   = var.cluster_id
  cluster_resource_group_id    = var.cluster_resource_group_id
  cluster_config_endpoint_type = var.cluster_config_endpoint_type
  wait_till                    = var.wait_till
  wait_till_timeout            = var.wait_till_timeout
  is_vpc_cluster               = var.is_vpc_cluster
  # Cloud Monitoring Agent
  name                                    = var.name
  namespace                               = var.namespace
  cloud_monitoring_instance_endpoint_type = var.cloud_monitoring_instance_endpoint_type
  access_key                              = var.access_key
  access_key_secret_name                  = var.access_key_secret_name
  agent_tags                              = var.agent_tags
  add_cluster_name                        = var.add_cluster_name
  blacklisted_ports                       = var.blacklisted_ports
  metrics_filter                          = var.metrics_filter
  cloud_monitoring_instance_region        = var.cloud_monitoring_instance_region
  tolerations                             = var.tolerations
  chart                                   = var.chart
  chart_location                          = var.chart_location
  chart_version                           = var.chart_version
  image_registry_base_url                 = var.image_registry_base_url
  image_registry_namespace                = var.image_registry_namespace
  agent_image_repository                  = var.agent_image_repository
  agent_image_tag_digest                  = var.agent_image_tag_digest
  kernel_module_image_tag_digest          = var.kernel_module_image_tag_digest
  kernal_module_image_repository          = var.kernal_module_image_repository
  agent_limits_cpu                        = var.agent_limits_cpu
  agent_limits_memory                     = var.agent_limits_memory
  agent_requests_cpu                      = var.agent_requests_cpu
  agent_requests_memory                   = var.agent_requests_memory
}
