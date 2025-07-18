## Key considerations

- Multiple instances of the agent cannot be deployed on the same host. However, by creating a connection between instances, a single agent can collect both metrics and security data for each instance.
- You can use the [Cloud automation for Cloud Monitoring](https://cloud.ibm.com/catalog/7a4d68b4-cf8b-40cd-a3d1-f49aff526eb3/architecture/deploy-arch-ibm-cloud-monitoring-73debdbf-894f-4c14-81c7-5ece3a70b67d-global) deployable architecture to provision a new instance of IBM Cloud Monitoring.
- You can use the [terraform-ibm-scc-workload-protection](https://github.com/terraform-ibm-modules/terraform-ibm-scc-workload-protection) module to provision a new instance of IBM Cloud Security and Compliance Center Workload Protection. This deployable architecture has an input called `cloud_monitoring_instance_crn` which allows you to create a connection between instances.
- Both instances must be in the same region.
- You can connect only one Monitoring instance to one Workload Protection instance.
- Connections can only be established between two new instances or between one new and one existing instance.

## When to Enable `enable_universal_ebpf`

For Clusters using Red Hat CoreOS (RHCOS) or RHEL 9 nodes with restricted outbound internet access, the monitoring agent pods may fail to start due to the inability to retrieve kernel modules which are necessary for the agent to connect with kernel.

Setting the input variable `enable_universal_ebpf` to `true` ensures the agent uses eBPF-based instrumentation, which avoids the need for external downloads and allows successful deployment in restricted environments.

### When Should You Enable It?

Set `enable_universal_ebpf` to true if:

- Your cluster nodes run on RHCOS or RHEL 9 and do not have public or outbound internet access.
- You want to avoid relying on dynamic downloads for kernel modules.

### Kernel Compatibility

- **RHCOS and RHEL9**: Since kernel version **5.14 or later** is used. Default value for variable has been set to true.
- **RHEL 8**: Although it uses kernel version **4.18**, the necessary kernel headers are pre-installed, so enabling eBPF is safe and has no impact.
