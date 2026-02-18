# Deploy agent in IKS cluster

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=monitoring-agent-obs-agent-iks-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-monitoring-agent/tree/main/examples/obs-agent-iks"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


An example that shows how to deploy the agent in an IKS cluster.

The following resources are provisioned:

- A new resource group, if an existing one is not passed in.
- A basic VPC (if `is_vpc_cluster` is true).
- A Kubernetes cluster.
- An IBM Cloud Monitoring instance.
- An App Configuration instance.
- An SCC Workload Protection instance.
- The Monitoring and Workload Protection agent.
- Zones for specific policy.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
