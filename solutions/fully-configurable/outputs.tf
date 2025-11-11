##############################################################################
# Outputs
##############################################################################
##############################################################################
#  Monitoring and Workload Protection agent- Next Steps URLs outputs
##############################################################################

output "next_steps_text" {
  value       = "Your Monitoring Instance Environment is ready."
  description = "Next steps text"
}

output "next_step_primary_label" {
  value       = "Go to Monitoring Instance Dashboard"
  description = "Primary label"
}

output "next_step_primary_url" {
  value       = "https://cloud.ibm.com/observability/embedded-view/monitoring/${element(split(":", var.instance_crn), 7)}"
  description = "Primary URL"
}

output "next_step_secondary_label" {
  value       = "Learn more about IBM Cloud Monitoring"
  description = "Secondary label"
}

output "next_step_secondary_url" {
  value       = "https://cloud.ibm.com/docs/monitoring?topic=monitoring-mng_metrics"
  description = "Secondary URL"
}

##############################################################################
