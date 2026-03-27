# Deploy agent in OpenShift cluster

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<p>
  <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=monitoring-agent-obs-agent-ocp-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-monitoring-agent/tree/main/examples/obs-agent-ocp">
    <img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics">
  </a><br>
  ℹ️ Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab.
</p>
<!-- END SCHEMATICS DEPLOY HOOK -->

An example that shows how to deploy the agent in an Red Hat OpenShift container platform cluster.

The following resources are provisioned:

- A new resource group, if an existing one is not passed in.
- A basic VPC.
- A Red Hat OpenShift Container Platform VPC cluster.
- An IBM Cloud Monitoring instance.
- An App Configuration instance.
- An SCC Workload Protection instance.
- The Monitoring and Workload Protection agent.
- Zones for specific policy.
