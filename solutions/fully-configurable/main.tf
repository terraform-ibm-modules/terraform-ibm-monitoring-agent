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
  # Cloud Monitoring (Sysdig) Agent
  cloud_monitoring_agent_name        = var.cloud_monitoring_agent_name
  cloud_monitoring_agent_namespace   = var.cloud_monitoring_agent_namespace
  cloud_monitoring_endpoint_type     = var.cloud_monitoring_endpoint_type
  cloud_monitoring_access_key        = var.cloud_monitoring_access_key
  cloud_monitoring_metrics_filter    = var.cloud_monitoring_metrics_filter
  cloud_monitoring_instance_region   = var.cloud_monitoring_instance_region
  cloud_monitoring_agent_tolerations = var.cloud_monitoring_agent_tolerations
  chart_location                     = var.chart_location
  chart_repository                   = var.chart_repository
  chart_version                      = var.chart_version
}
