# IBM Cloud Monitoring and Workload Protection agent module

[![Graduated (Supported)](https://img.shields.io/badge/Status-Graduated%20(Supported)-brightgreen)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-monitoring-agent?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-monitoring-agent/releases/latest)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

This module supports the provisioning of an agent to an IBM Cloud Red Hat OpenShift Container Platform or Kubernetes cluster. The agent can be configured for:
- Metrics monitoring with [IBM Cloud Monitoring](https://cloud.ibm.com/docs/monitoring?topic=monitoring-getting-started)
- Security and compliance with [IBM Cloud Security and Compliance Center Workload Protection](https://cloud.ibm.com/docs/workload-protection?topic=workload-protection-getting-started)

## Key considerations
- Multiple instances of the agent cannot be deployed on the same host. However, by creating a connection between instances, a single agent can collect both metrics and security data for each instance.
- You can use the [terraform-ibm-cloud-monitoring](https://github.com/terraform-ibm-modules/terraform-ibm-cloud-monitoring) module to provision a new instance of IBM Cloud Monitoring
- You can use the [terraform-ibm-scc-workload-protection](https://github.com/terraform-ibm-modules/terraform-ibm-scc-workload-protection) module to provision a new instance of IBM Cloud Security and Compliance Center Workload Protection. This module has an input called `cloud_monitoring_instance_crn` which allows you to create a connection between instances.
- Both instances must be in the same region.
- You can connect only one Monitoring instance to one Workload Protection instance.
- Connections can only be established between two new instances or between one new and one existing instance.

<!-- Below content is automatically populated via pre-commit hook -->
<!-- BEGIN OVERVIEW HOOK -->
## Overview
* [terraform-ibm-monitoring-agent](#terraform-ibm-monitoring-agent)
* [Examples](./examples)
    * [Deploy agent in IKS cluster](./examples/obs-agent-iks)
    * [Deploy agent in OpenShift cluster](./examples/obs-agent-ocp)
* [Contributing](#contributing)
<!-- END OVERVIEW HOOK -->

## terraform-ibm-monitoring-agent

### Usage

```hcl
#############################################################################
# Initialize cluster config for helm provider
#############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id = "REPLACE" # Replace with name of ID of cluster
}

#############################################################################
# Configure providers
#############################################################################

provider "ibm" {
  ibmcloud_api_key = "XXXXXXXXXXXXXXXXX" # Replace with IBM Cloud api key
}

provider "helm" {
  kubernetes = {
    host                   = data.ibm_container_cluster_config.cluster_config.host
    token                  = data.ibm_container_cluster_config.cluster_config.token
    cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config.ca_certificate
  }
}

#############################################################################
# Install agent
#############################################################################

module "monitoring_agent" {
  source                     = "terraform-ibm-modules/monitoring-agent/ibm"
  version                    = "X.Y.Z" # Replace "X.Y.Z" with a release version to lock into a specific release
  is_vpc_cluster             = true # Change to false if target cluster is running on classic infrastructure
  cluster_id                 = "REPLACE"
  cluster_resource_group_id  = "REPLACE"
  access_key                 = "XXXXXXXX"
  instance_region            = "us-south" # enter region of Cloud Monitoring / SCC-WP instance
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
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 3.0.0, <4.0.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.79.2, <2.0.0 |

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
| <a name="input_access_key"></a> [access\_key](#input\_access\_key) | Access key used by the agent to communicate with the instance. Either `access_key` or `existing_access_key_secret_name` is required. This value will be stored in a new secret on the cluster if passed. If you want to use this agent for only metrics or metrics with security and compliance, use a manager key scoped to the IBM Cloud Monitoring instance. If you only want to use the agent for security and compliance use a manager key scoped to the Security and Compliance Center Workload Protection instance. | `string` | `null` | no |
| <a name="input_add_cluster_name"></a> [add\_cluster\_name](#input\_add\_cluster\_name) | If true, configure the agent to associate a tag containing the cluster name. This tag is added in the format `ibm-containers-kubernetes-cluster-name: cluster_name`. | `bool` | `true` | no |
| <a name="input_agent_image_repository"></a> [agent\_image\_repository](#input\_agent\_image\_repository) | The image repository to pull the agent image from. | `string` | `"agent-slim"` | no |
| <a name="input_agent_image_tag_digest"></a> [agent\_image\_tag\_digest](#input\_agent\_image\_tag\_digest) | The image tag or digest of agent image to use. If using digest, it must be in the format of `X.Y.Z@sha256:xxxxx`. | `string` | `"14.1.0@sha256:2c6401018cfe3f5fcbd0713b64b096c38d47de1b5cd6c11de4691912752263fc"` | no |
| <a name="input_agent_limits_cpu"></a> [agent\_limits\_cpu](#input\_agent\_limits\_cpu) | Specify CPU resource limits for the agent. For more info, see https://cloud.ibm.com/docs/monitoring?topic=monitoring-resource_requirements | `string` | `"1"` | no |
| <a name="input_agent_limits_memory"></a> [agent\_limits\_memory](#input\_agent\_limits\_memory) | Specify memory resource limits for the agent. For more info, see https://cloud.ibm.com/docs/monitoring?topic=monitoring-resource_requirements | `string` | `"1024Mi"` | no |
| <a name="input_agent_requests_cpu"></a> [agent\_requests\_cpu](#input\_agent\_requests\_cpu) | Specify CPU resource requests for the agent. For more info, see https://cloud.ibm.com/docs/monitoring?topic=monitoring-resource_requirements | `string` | `"1"` | no |
| <a name="input_agent_requests_memory"></a> [agent\_requests\_memory](#input\_agent\_requests\_memory) | Specify memory resource requests for the agent. For more info, see https://cloud.ibm.com/docs/monitoring?topic=monitoring-resource_requirements | `string` | `"1024Mi"` | no |
| <a name="input_agent_tags"></a> [agent\_tags](#input\_agent\_tags) | Map of tags to associate to the agent. For example, {"environment": "production"}. NOTE: Use the `add_cluster_name` boolean variable to add the cluster name as a tag. | `map(string)` | `{}` | no |
| <a name="input_blacklisted_ports"></a> [blacklisted\_ports](#input\_blacklisted\_ports) | To block network traffic and metrics from network ports, pass the list of ports from which you want to filter out any data. For more info, see https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_agent#ports | `list(number)` | `[]` | no |
| <a name="input_chart"></a> [chart](#input\_chart) | The name of the Helm chart to deploy. Use `chart_location` to specify helm chart location. | `string` | `"sysdig-deploy"` | no |
| <a name="input_chart_location"></a> [chart\_location](#input\_chart\_location) | The location of the agent helm chart. | `string` | `"https://charts.sysdig.com"` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | The version of the agent helm chart to deploy. | `string` | `"1.91.1"` | no |
| <a name="input_cluster_config_endpoint_type"></a> [cluster\_config\_endpoint\_type](#input\_cluster\_config\_endpoint\_type) | Specify which type of endpoint to use for for cluster config access: 'default', 'private', 'vpe', 'link'. 'default' value will use the default endpoint of the cluster. | `string` | `"default"` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | The ID of the cluster you wish to deploy the agent in. | `string` | n/a | yes |
| <a name="input_cluster_resource_group_id"></a> [cluster\_resource\_group\_id](#input\_cluster\_resource\_group\_id) | The resource group ID of the cluster. | `string` | n/a | yes |
| <a name="input_cluster_shield_deploy"></a> [cluster\_shield\_deploy](#input\_cluster\_shield\_deploy) | Deploy the Cluster Shield component to provide runtime detection and policy enforcement for Kubernetes workloads. If enabled, a Kubernetes Deployment will be deployed to your cluster using helm. | `bool` | `true` | no |
| <a name="input_cluster_shield_image_repository"></a> [cluster\_shield\_image\_repository](#input\_cluster\_shield\_image\_repository) | The image repository to pull the Cluster Shield image from. | `string` | `"cluster-shield"` | no |
| <a name="input_cluster_shield_image_tag_digest"></a> [cluster\_shield\_image\_tag\_digest](#input\_cluster\_shield\_image\_tag\_digest) | The image tag or digest to pull for the Cluster Shield component. If using digest, it must be in the format of `X.Y.Z@sha256:xxxxx`. | `string` | `"1.14.0@sha256:abbff90f7884a91d4558476b7b43bb2ae0c72f486c2cf95e729f699116695e52"` | no |
| <a name="input_cluster_shield_limits_cpu"></a> [cluster\_shield\_limits\_cpu](#input\_cluster\_shield\_limits\_cpu) | Specify CPU resource limits for the cluster shield pods. | `string` | `"1500m"` | no |
| <a name="input_cluster_shield_limits_memory"></a> [cluster\_shield\_limits\_memory](#input\_cluster\_shield\_limits\_memory) | Specify memory resource limits for the cluster shield pods. | `string` | `"1536Mi"` | no |
| <a name="input_cluster_shield_requests_cpu"></a> [cluster\_shield\_requests\_cpu](#input\_cluster\_shield\_requests\_cpu) | Specify CPU resource requests for the cluster shield pods. | `string` | `"500m"` | no |
| <a name="input_cluster_shield_requests_memory"></a> [cluster\_shield\_requests\_memory](#input\_cluster\_shield\_requests\_memory) | Specify memory resource requests for the cluster shield pods. | `string` | `"512Mi"` | no |
| <a name="input_container_filter"></a> [container\_filter](#input\_container\_filter) | Customize the agent to exclude containers from metrics collection. For more info, see https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_filter_data | <pre>list(object({<br/>    type      = string<br/>    parameter = string<br/>    name      = string<br/>  }))</pre> | `[]` | no |
| <a name="input_deployment_tag"></a> [deployment\_tag](#input\_deployment\_tag) | Sets a global tag that will be included in the components. It represents the mechanism from where the components have been installed (terraform, local...). | `string` | `"terraform"` | no |
| <a name="input_enable_host_scanner"></a> [enable\_host\_scanner](#input\_enable\_host\_scanner) | Enable host scanning to detect vulnerabilities and identify the resolution priority based on available fixed versions and severity. Requires a Security and Compliance Center Workload Protection instance to view results. | `bool` | `true` | no |
| <a name="input_enable_kspm_analyzer"></a> [enable\_kspm\_analyzer](#input\_enable\_kspm\_analyzer) | Enable Kubernetes Security Posture Management (KSPM) analyzer. Requires a Security and Compliance Center Workload Protection instance to view results. | `bool` | `true` | no |
| <a name="input_enable_universal_ebpf"></a> [enable\_universal\_ebpf](#input\_enable\_universal\_ebpf) | Deploy monitoring agent with universal extended Berkeley Packet Filter (eBPF) enabled. It requires kernel version 5.8+. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-monitoring-agent/blob/main/solutions/fully-configurable/DA-docs.md#when-to-enable-enable_universal_ebpf) | `bool` | `true` | no |
| <a name="input_existing_access_key_secret_name"></a> [existing\_access\_key\_secret\_name](#input\_existing\_access\_key\_secret\_name) | An alternative to using `access_key`. Specify the name of an existing Kubernetes secret containing the access key in the same namespace that is defined in the `namespace` input. Either `access_key` or `existing_access_key_secret_name` is required. | `string` | `null` | no |
| <a name="input_image_registry_base_url"></a> [image\_registry\_base\_url](#input\_image\_registry\_base\_url) | The image registry base URL to pull all images from. For example `icr.io` or `quay.io`. | `string` | `"icr.io"` | no |
| <a name="input_image_registry_namespace"></a> [image\_registry\_namespace](#input\_image\_registry\_namespace) | The namespace within the image registry to pull all images from. | `string` | `"ext/sysdig"` | no |
| <a name="input_instance_region"></a> [instance\_region](#input\_instance\_region) | The region of the IBM Cloud Monitoring instance that you want to send metrics to. The region value is used to construct the ingestion and api endpoints. If you are only using the agent for security and compliance monitoring, set this to the region of your IBM Cloud Security and Compliance Center Workload Protection instance. If you have both Cloud Monitoring and Security and Compliance Center Workload Protection instances, the instances must be connected and must be in the same region to use the same agent. | `string` | n/a | yes |
| <a name="input_is_vpc_cluster"></a> [is\_vpc\_cluster](#input\_is\_vpc\_cluster) | Specify true if the target cluster is a VPC cluster, false if it is a classic cluster. | `bool` | `true` | no |
| <a name="input_kernal_module_image_repository"></a> [kernal\_module\_image\_repository](#input\_kernal\_module\_image\_repository) | The image repository to pull the agent kernal module initContainer image from. | `string` | `"agent-kmodule"` | no |
| <a name="input_kernel_module_image_tag_digest"></a> [kernel\_module\_image\_tag\_digest](#input\_kernel\_module\_image\_tag\_digest) | The image tag or digest to use for the agent kernel module used by the initContainer. If using digest, it must be in the format of `X.Y.Z@sha256:xxxxx` | `string` | `"14.1.1@sha256:339a15d5aec1f1d3a4edd3928e14233f54c1c586f4a45d601a12f8a92da31ae0"` | no |
| <a name="input_metrics_filter"></a> [metrics\_filter](#input\_metrics\_filter) | To filter custom metrics you can specify which metrics to include and exclude. For more info, see https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics | <pre>list(object({<br/>    include = optional(string)<br/>    exclude = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | The name to give the agent helm release. | `string` | `"sysdig-agent"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace to deploy the agent to. | `string` | `"ibm-observe"` | no |
| <a name="input_prometheus_config"></a> [prometheus\_config](#input\_prometheus\_config) | Prometheus configuration for the agent. If you want to enable Prometheus configuration provide the prometheus.yaml file content in `hcl` format. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-monitoring-agent/blob/main/solutions/fully-configurable/DA-types.md#prometheus_config). | `map(any)` | `{}` | no |
| <a name="input_tolerations"></a> [tolerations](#input\_tolerations) | List of tolerations to apply to the agent. | <pre>list(object({<br/>    key               = optional(string)<br/>    operator          = optional(string)<br/>    value             = optional(string)<br/>    effect            = optional(string)<br/>    tolerationSeconds = optional(number)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "operator": "Exists"<br/>  },<br/>  {<br/>    "effect": "NoSchedule",<br/>    "key": "node-role.kubernetes.io/master",<br/>    "operator": "Exists"<br/>  }<br/>]</pre> | no |
| <a name="input_use_private_endpoint"></a> [use\_private\_endpoint](#input\_use\_private\_endpoint) | Whether send data over a private endpoint or not. To use a private endpoint, you must enable virtual routing and forwarding (VRF) for your account. See https://cloud.ibm.com/docs/account?topic=account-vrf-service-endpoint. | `bool` | `true` | no |
| <a name="input_use_scc_wp_endpoint"></a> [use\_scc\_wp\_endpoint](#input\_use\_scc\_wp\_endpoint) | By default an IBM Cloud Monitoring endpoint is used and is constructed from the `instance_region` and `use_private_endpoint` inputs. To use an IBM Cloud Security and Compliance Center Workload Protection endpoint instead, set this to true. | `bool` | `false` | no |
| <a name="input_wait_till"></a> [wait\_till](#input\_wait\_till) | To avoid long wait times when you run your Terraform code, you can specify the stage when you want Terraform to mark the cluster resource creation as completed. Depending on what stage you choose, the cluster creation might not be fully completed and continues to run in the background. However, your Terraform code can continue to run without waiting for the cluster to be fully created. Supported values are `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady` and `Normal` | `string` | `"Normal"` | no |
| <a name="input_wait_till_timeout"></a> [wait\_till\_timeout](#input\_wait\_till\_timeout) | Timeout for wait\_till in minutes. | `number` | `90` | no |

### Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


<!-- Leave this section as is so that your module has a link to local development environment set up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
