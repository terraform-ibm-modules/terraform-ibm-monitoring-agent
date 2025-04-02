##############################################################################
# Outputs
##############################################################################

output "region" {
  value       = var.region
  description = "Region where SLZ ROKS Cluster is deployed."
}

output "cluster_id" {
  value       = module.ocp_base.cluster_id
  description = "ID of the cluster."
}

output "cluster_crn" {
  value       = local.cluster_crn
  description = "CRN of the workload cluster."
}

output "cluster_name" {
  value       = local.cluster_name
  description = "CRN of the workload cluster."
}

output "cluster_resource_group_id" {
  value       = local.cluster_resource_group_id
  description = "Resource group ID of the workload cluster."
}

output "cloud_monitoring_instance_id" {
  value       = module.cloud_monitoring.cloud_monitoring_id
  description = "The name of the provisioned IBM Cloud Logs instance."
}

output "cloud_monitoring_access_key" {
  value       = module.cloud_monitoring.cloud_monitoring_access_key
  description = "The access key of the provisioned IBM Cloud Logs instance."
  sensitive   = true
}
