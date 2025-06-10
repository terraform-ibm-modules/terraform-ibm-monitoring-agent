# Terraform IBM Monitoring agent module

[![Graduated (Supported)](https://img.shields.io/badge/Status-Graduated%20(Supported)-brightgreen)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-monitoring-agent?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-monitoring-agent/releases/latest)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

This module deploys the following monitoring agent to an IBM Cloud Red Hat OpenShift Container Platform or Kubernetes cluster:

- [Monitoring agent](https://cloud.ibm.com/docs/monitoring?topic=monitoring-about-collect-metrics)

<!-- Below content is automatically populated via pre-commit hook -->
<!-- BEGIN OVERVIEW HOOK -->
## Overview
* [terraform-ibm-monitoring-agent](#terraform-ibm-monitoring-agent)
* [Examples](./examples)
    * [Monitoring agent on Kubernetes using CSE ingress endpoint with an apikey](./examples/obs-agent-iks)
    * [Monitoring agent](./examples/obs-agent-ocp)
* [Contributing](#contributing)
<!-- END OVERVIEW HOOK -->

## terraform-ibm-monitoring-agent

### Usage

```hcl
# ############################################################################
# Init cluster config for helm
# ############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  # update this value with the Id of the cluster where these agent will be provisioned
  cluster_name_id = "cluster_id"
}

# ############################################################################
# Config providers
# ############################################################################

provider "ibm" {
  # update this value with your IBM Cloud API key value
  ibmcloud_api_key = "XXXXXXXXXXXXXXXXX"  # pragma: allowlist secret
}

provider "helm" {
  kubernetes {
    host                   = data.ibm_container_cluster_config.cluster_config.host
    token                  = data.ibm_container_cluster_config.cluster_config.token
    cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config.ca_certificate
  }
}

# ############################################################################
# Install monitoring agents
# ############################################################################

module "monitoring_agents" {
  source                           = "terraform-ibm-modules/monitoring-agent/ibm"
  version                          = "X.X.X" # Replace "X.X.X" with a release version to lock into a specific release
  is_vpc_cluster                   = true # Change to false if target cluster is running on classic infrastructure
  cluster_id                       = "cluster id" # update this with your cluster id where the agent will be installed
  cluster_resource_group_id        = "resource group id" # update this with the Id of your IBM Cloud resource group
  access_key      = "XXXXXXXX"
  cloud_monitoring_instance_region = "us-south"
}
```

### Required IAM access policies
You need the following permissions to run this module.

- Service
    - **Resource group only**
        - `Viewer` access on the specific resource group
    - **Kubernetes** service
        - `Viewer` platform access
        - `Manager` service access

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.15.0, <3.0.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.76.1, <2.0.0 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [helm_release.cloud_monitoring_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [ibm_container_cluster.cluster](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster) | data source |
| [ibm_container_cluster_config.cluster_config](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster_config) | data source |
| [ibm_container_vpc_cluster.cluster](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_vpc_cluster) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_key"></a> [access\_key](#input\_access\_key) | Access key used by the IBM Cloud Monitoring agent to communicate with the instance | `string` | n/a | yes |
| <a name="input_access_key_secret_name"></a> [access\_key\_secret\_name](#input\_access\_key\_secret\_name) | The name of a Kubernetes or OpenShift Secret that contains the Sysdig agent access key under the key `access-key`. This variable allows you to reference an existing secret in your cluster, rather than providing the access key directly in your Terraform configuration. | `string` | `null` | no |
| <a name="input_add_cluster_name"></a> [add\_cluster\_name](#input\_add\_cluster\_name) | If true, configure the cloud monitoring agent to attach a tag containing the cluster name to all metric data. This tag is added in the format `ibm-containers-kubernetes-cluster-name: cluster_name`. | `bool` | `true` | no |
| <a name="input_agent_image_repository"></a> [agent\_image\_repository](#input\_agent\_image\_repository) | The image repository to pull the Cloud Monitoring agent image from. | `string` | `"agent-slim"` | no |
| <a name="input_agent_image_tag_digest"></a> [agent\_image\_tag\_digest](#input\_agent\_image\_tag\_digest) | The image tag digest to use for the Cloud Monitoring agent. | `string` | `"13.9.2@sha256:0dcdb6d70bab60dae4bf5f70c338f2feb9daeba514f1b8ad513ed24724c2a04d"` | no |
| <a name="input_agent_limits_cpu"></a> [agent\_limits\_cpu](#input\_agent\_limits\_cpu) | Specifies the CPU limit for the agent. | `string` | `"1"` | no |
| <a name="input_agent_limits_memory"></a> [agent\_limits\_memory](#input\_agent\_limits\_memory) | Specifies the memory limit for the agent. | `string` | `"1024Mi"` | no |
| <a name="input_agent_requests_cpu"></a> [agent\_requests\_cpu](#input\_agent\_requests\_cpu) | Specifies the CPU requested to run in a node for the agent. | `string` | `"1"` | no |
| <a name="input_agent_requests_memory"></a> [agent\_requests\_memory](#input\_agent\_requests\_memory) | Specifies the memory requested to run in a node for the agent. | `string` | `"1024Mi"` | no |
| <a name="input_agent_tags"></a> [agent\_tags](#input\_agent\_tags) | Map of tags to associate to all metrics that the agent collects. NOTE: Use the `add_cluster_name` boolean variable to add the cluster name as a tag, e.g `{'environment': 'production'}.` | `map(string)` | `{}` | no |
| <a name="input_blacklisted_ports"></a> [blacklisted\_ports](#input\_blacklisted\_ports) | To block network traffic and metrics from network ports, pass the list of ports from which you want to filter out any data. [Learn more](https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_block_ports). | `list(number)` | `[]` | no |
| <a name="input_chart"></a> [chart](#input\_chart) | The name of the Helm chart to deploy. | `string` | `"sysdig-deploy"` | no |
| <a name="input_chart_location"></a> [chart\_location](#input\_chart\_location) | The location of the Cloud Monitoring agent helm chart. | `string` | `"https://charts.sysdig.com"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The version of the Cloud Monitoring agent helm chart to deploy. | `string` | `"1.85.1"` | no |
| <a name="input_cloud_monitoring_instance_endpoint_type"></a> [cloud\_monitoring\_instance\_endpoint\_type](#input\_cloud\_monitoring\_instance\_endpoint\_type) | Specify the IBM Cloud Monitoring instance endpoint type (public or private) to use. Used to construct the ingestion endpoint. | `string` | `"private"` | no |
| <a name="input_cloud_monitoring_instance_region"></a> [cloud\_monitoring\_instance\_region](#input\_cloud\_monitoring\_instance\_region) | The IBM Cloud Monitoring instance region. Used to construct the ingestion endpoint. | `string` | n/a | yes |
| <a name="input_cluster_config_endpoint_type"></a> [cluster\_config\_endpoint\_type](#input\_cluster\_config\_endpoint\_type) | Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster. | `string` | `"default"` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | The ID of the cluster you wish to deploy the agent in | `string` | n/a | yes |
| <a name="input_cluster_resource_group_id"></a> [cluster\_resource\_group\_id](#input\_cluster\_resource\_group\_id) | The Resource Group ID of the cluster | `string` | n/a | yes |
| <a name="input_container_filter"></a> [container\_filter](#input\_container\_filter) | To filter custom containers, specify which containers to include or exclude from metrics collection for the cloud monitoring agent. See https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_filter_data. | <pre>list(object({<br/>    type      = string<br/>    parameter = string<br/>    name      = string<br/>  }))</pre> | `[]` | no |
| <a name="input_image_registry_base_url"></a> [image\_registry\_base\_url](#input\_image\_registry\_base\_url) | The image registry base URL to pull the Cloud Monitoring agent images from. For example `icr.io`, `quay.io`, etc. | `string` | `"icr.io"` | no |
| <a name="input_image_registry_namespace"></a> [image\_registry\_namespace](#input\_image\_registry\_namespace) | The namespace within the image registry to pull the Cloud Monitoring agent images from. | `string` | `"ext/sysdig"` | no |
| <a name="input_is_vpc_cluster"></a> [is\_vpc\_cluster](#input\_is\_vpc\_cluster) | Specify true if the target cluster for the monitoring agent is a VPC cluster, false if it is a classic cluster. | `bool` | `true` | no |
| <a name="input_kernal_module_image_repository"></a> [kernal\_module\_image\_repository](#input\_kernal\_module\_image\_repository) | The image repository to pull the Cloud Monitoring agent kernal module initContainer image from. | `string` | `"agent-kmodule"` | no |
| <a name="input_kernel_module_image_tag_digest"></a> [kernel\_module\_image\_tag\_digest](#input\_kernel\_module\_image\_tag\_digest) | The image tag digest to use for the Cloud Monitoring agent kernel module used by the initContainer. | `string` | `"13.9.2@sha256:a6b301f24557c5e14ab5abe62577340e7ab33ce11f33cfcd4797296d1603184a"` | no |
| <a name="input_metrics_filter"></a> [metrics\_filter](#input\_metrics\_filter) | To filter custom metrics, specify the Cloud Monitoring metrics to include or to exclude. See https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics. | <pre>list(object({<br/>    include = optional(string)<br/>    exclude = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Cloud Monitoring agent name. Used for naming all kubernetes and helm resources on the cluster. | `string` | `"sysdig-agent"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace where to deploy the Cloud Monitoring agent. Default value is 'ibm-observe' | `string` | `"ibm-observe"` | no |
| <a name="input_tolerations"></a> [tolerations](#input\_tolerations) | List of tolerations to apply to Cloud Monitoring agent. | <pre>list(object({<br/>    key               = optional(string)<br/>    operator          = optional(string)<br/>    value             = optional(string)<br/>    effect            = optional(string)<br/>    tolerationSeconds = optional(number)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "operator": "Exists"<br/>  },<br/>  {<br/>    "effect": "NoSchedule",<br/>    "key": "node-role.kubernetes.io/master",<br/>    "operator": "Exists"<br/>  }<br/>]</pre> | no |
| <a name="input_wait_till"></a> [wait\_till](#input\_wait\_till) | To avoid long wait times when you run your Terraform code, you can specify the stage when you want Terraform to mark the cluster resource creation as completed. Depending on what stage you choose, the cluster creation might not be fully completed and continues to run in the background. However, your Terraform code can continue to run without waiting for the cluster to be fully created. Supported args are `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady` and `Normal` | `string` | `"Normal"` | no |
| <a name="input_wait_till_timeout"></a> [wait\_till\_timeout](#input\_wait\_till\_timeout) | Timeout for wait\_till in minutes. | `number` | `90` | no |

### Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


<!-- Leave this section as is so that your module has a link to local development environment set up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
