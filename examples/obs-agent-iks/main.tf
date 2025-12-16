##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.4.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Create VPC and IKS Cluster
##############################################################################

resource "ibm_is_vpc" "example_vpc" {
  count          = var.is_vpc_cluster ? 1 : 0
  name           = "${var.prefix}-vpc"
  resource_group = module.resource_group.resource_group_id
  tags           = var.resource_tags
}

resource "ibm_is_subnet" "testacc_subnet" {
  count                    = var.is_vpc_cluster ? 1 : 0
  name                     = "${var.prefix}-subnet"
  vpc                      = ibm_is_vpc.example_vpc[0].id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  resource_group           = module.resource_group.resource_group_id
}

# Lookup the current default kube version
data "ibm_container_cluster_versions" "cluster_versions" {}
locals {
  default_version = data.ibm_container_cluster_versions.cluster_versions.default_kube_version
}

resource "ibm_container_vpc_cluster" "cluster" {
  count                = var.is_vpc_cluster ? 1 : 0
  name                 = var.prefix
  vpc_id               = ibm_is_vpc.example_vpc[0].id
  kube_version         = local.default_version
  flavor               = "bx2.4x16"
  worker_count         = "2"
  force_delete_storage = true
  wait_till            = "IngressReady"
  zones {
    subnet_id = ibm_is_subnet.testacc_subnet[0].id
    name      = "${var.region}-1"
  }
  resource_group_id = module.resource_group.resource_group_id
  tags              = var.resource_tags
}

resource "ibm_container_cluster" "cluster" {
  #checkov:skip=CKV2_IBM_7:Public endpoint is required for testing purposes
  count                = var.is_vpc_cluster ? 0 : 1
  name                 = var.prefix
  datacenter           = var.datacenter
  default_pool_size    = 2
  hardware             = "shared"
  kube_version         = local.default_version
  force_delete_storage = true
  machine_type         = "b3c.4x16"
  public_vlan_id       = ibm_network_vlan.public_vlan[0].id
  private_vlan_id      = ibm_network_vlan.private_vlan[0].id
  wait_till            = "Normal"
  resource_group_id    = module.resource_group.resource_group_id
  tags                 = var.resource_tags

  timeouts {
    delete = "2h"
    create = "3h"
  }
}

locals {
  cluster_name_id = var.is_vpc_cluster ? ibm_container_vpc_cluster.cluster[0].id : ibm_container_cluster.cluster[0].id
}

resource "ibm_network_vlan" "public_vlan" {
  count      = var.is_vpc_cluster ? 0 : 1
  datacenter = var.datacenter
  type       = "PUBLIC"
}

resource "ibm_network_vlan" "private_vlan" {
  count      = var.is_vpc_cluster ? 0 : 1
  datacenter = var.datacenter
  type       = "PRIVATE"
}

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = local.cluster_name_id
  resource_group_id = module.resource_group.resource_group_id
}

# Sleep to allow RBAC sync on cluster
resource "time_sleep" "wait_operators" {
  depends_on      = [data.ibm_container_cluster_config.cluster_config]
  create_duration = "45s"
}

##############################################################################
# Monitoring instance
##############################################################################

module "cloud_monitoring" {
  source            = "terraform-ibm-modules/cloud-monitoring/ibm"
  version           = "1.12.1"
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
  version                       = "1.16.5"
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
  cluster_id                = local.cluster_name_id
  cluster_resource_group_id = module.resource_group.resource_group_id
  is_vpc_cluster            = var.is_vpc_cluster
  access_key                = module.cloud_monitoring.access_key
  instance_region           = var.region
  priority_class_name       = "sysdig-daemonset-priority"
  prometheus_config = {
    scrape_configs = [
      {
        job_name = "testing-prometheus-scrape"
        tls_config = {
          insecure_skip_verify = true
        }
        kubernetes_sd_configs = [
          {
            role = "pod"
          }
        ]
        relabel_configs = [
          {
            action        = "keep"
            source_labels = ["__meta_kubernetes_pod_host_ip"]
            regex         = "__HOSTIPS__"
          },
          {
            action        = "drop"
            source_labels = ["__meta_kubernetes_pod_annotation_promcat_sysdig_com_omit"]
            regex         = "true"
          },
          {
            source_labels = ["__meta_kubernetes_pod_phase"]
            action        = "keep"
            regex         = "Running"
          }
        ]
      }
    ]
  }
}
