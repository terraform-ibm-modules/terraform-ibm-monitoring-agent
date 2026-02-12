##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.4.8"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

########################################################################################################################
# VPC + Subnet + Public Gateway
#
# NOTE: This is a very simple VPC with single subnet in a single zone with a public gateway enabled, that will allow
# all traffic ingress/egress by default.
# For production use cases this would need to be enhanced by adding more subnets and zones for resiliency, and
# ACLs/Security Groups for network security.
########################################################################################################################

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.prefix}-vpc"
  resource_group            = module.resource_group.resource_group_id
  address_prefix_management = "auto"
  tags                      = var.resource_tags
}

# Public gateway required when deploying a cluster with public endpoint enabled otherwise ingress goes into degraded state
resource "ibm_is_public_gateway" "gateway" {
  name           = "${var.prefix}-gateway-1"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = module.resource_group.resource_group_id
  zone           = "${var.region}-1"
}

resource "ibm_is_subnet" "subnet_zone_1" {
  name                     = "${var.prefix}-subnet-1"
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = module.resource_group.resource_group_id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway.id
}

########################################################################################################################
# OCP VPC cluster (single zone)
########################################################################################################################

locals {
  cluster_vpc_subnets = {
    default = [
      {
        id         = ibm_is_subnet.subnet_zone_1.id
        cidr_block = ibm_is_subnet.subnet_zone_1.ipv4_cidr_block
        zone       = ibm_is_subnet.subnet_zone_1.zone
      }
    ]
  }

  worker_pools = [
    {
      subnet_prefix    = "default"
      pool_name        = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type     = "bx2.4x16"
      operating_system = "RHEL_9_64"
      workers_per_zone = 2 # minimum of 2 is allowed when using single zone
    }
  ]
}

module "ocp_base" {
  source               = "terraform-ibm-modules/base-ocp-vpc/ibm"
  version              = "3.80.1"
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  tags                 = var.resource_tags
  cluster_name         = var.prefix
  force_delete_storage = true
  vpc_id               = ibm_is_vpc.vpc.id
  vpc_subnets          = local.cluster_vpc_subnets
  worker_pools         = local.worker_pools
  access_tags          = var.access_tags
  ocp_entitlement      = var.ocp_entitlement
}

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = module.ocp_base.cluster_id
  resource_group_id = module.resource_group.resource_group_id
}

##############################################################################
# Monitoring instance
##############################################################################

module "cloud_monitoring" {
  source            = "terraform-ibm-modules/cloud-monitoring/ibm"
  version           = "1.13.4"
  instance_name     = "${var.prefix}-cloud-monitoring"
  resource_group_id = module.resource_group.resource_group_id
  resource_tags     = var.resource_tags
  region            = var.region
  plan              = "graduated-tier"
}

##############################################################################
# SCC Workload Protection instance
##############################################################################

module "scc_wp" {
  source                        = "terraform-ibm-modules/scc-workload-protection/ibm"
  version                       = "1.17.3"
  name                          = "${var.prefix}-scc-wp"
  resource_group_id             = module.resource_group.resource_group_id
  region                        = var.region
  resource_tags                 = var.resource_tags
  cloud_monitoring_instance_crn = module.cloud_monitoring.crn
  cspm_enabled                  = false
}

##############################################################################
# Monitoring Agents
##############################################################################

module "monitoring_agents" {
  source = "../.."
  # remove the above line and uncomment the below 2 lines to consume the module from the registry
  # source  = "terraform-ibm-modules/monitoring-agent/ibm"
  # version = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  cluster_id                = module.ocp_base.cluster_id
  cluster_resource_group_id = module.resource_group.resource_group_id
  is_vpc_cluster            = true
  access_key                = module.cloud_monitoring.access_key
  instance_region           = var.region
  # example of how to include / exclude metrics - more info https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_log_metrics
  metrics_filter = [{ exclude = "metricA.*" }, { include = "metricB.*" }]
  # example of how to include / exclude container filter - more info https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_filter_data
  container_filter = [{ type = "exclude", parameter = "kubernetes.namespace.name", name = "kube-system" }]
  # example of how to include / exclude container filter - more info https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_block_ports
  blacklisted_ports = [22, 2379, 3306]
  # example of adding agent tag
  agent_tags = { "environment" : "test", "custom" : "value" }
  # example of setting agent mode to troubleshooting for additional metrics
  agent_mode = "troubleshooting"
}
