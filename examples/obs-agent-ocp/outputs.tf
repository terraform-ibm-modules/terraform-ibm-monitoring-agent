##############################################################################
# Outputs
##############################################################################

output "region" {
  description = "The region where the resources are deployed."
  value       = var.region
}

output "cloud_monitoring_name" {
  description = "The name of the IBM Cloud Monitoring instance."
  value       = module.cloud_monitoring.name
}

output "cloud_monitoring_access_key" {
  description = "The access key that is used by the IBM Cloud Monitoring agent to communicate with the instance."
  value       = module.cloud_monitoring.access_key
  sensitive   = true
}

output "cluster_name" {
  description = "The name of the OpenShift cluster."
  value       = module.ocp_base.cluster_name
}

output "cluster_id" {
  description = "The ID of the OpenShift cluster."
  value       = module.ocp_base.cluster_id
}

output "cluster_resource_group_id" {
  description = "The resource group ID of the cluster."
  value       = module.resource_group.resource_group_id
}

##############################################################################
