##############################################################################
# Outputs
##############################################################################

output "region" {
  value       = var.region
  description = "Region where OCP Cluster is deployed."
}

output "cluster_id" {
  value       = module.ocp_base.cluster_id
  description = "ID of the cluster."
}

output "cluster_resource_group_id" {
  value       = module.ocp_base.resource_group_id
  description = "Resource group ID of the cluster."
}

output "cluster_name" {
  value       = module.ocp_base.cluster_name
  description = "Name of the cluster."
}

output "access_key" {
  value       = module.cloud_monitoring.access_key
  description = "The access key of the provisioned IBM Cloud Monitoring instance."
  sensitive   = true
}
