## When to Enable `enable_universal_ebpf`

For Clusters using Red Hat CoreOS (RHCOS) or RHEL 9 nodes with restricted outbound internet access, the monitoring agent pods may fail to start due to the inability to retrieve kernel modules which are necessary for the agent to connect with kernel.

Setting the Terraform variable `enable_universal_ebpf` to `true` ensures the agent uses eBPF-based instrumentation, which avoids the need for external downloads and allows successful deployment in restricted environments.

### When Should You Enable It?

Set `enable_universal_ebpf` to true if:

- Your cluster nodes run on RHCOS or RHEL 9 and do not have public or outbound internet access.
- You want to avoid relying on dynamic downloads for kernel modules.

### Kernel Compatibility

- **RHCOS and RHEL9**: Since kernel version **5.14** is used. Default value for variable has been set to true.
- **RHEL 8**: Although it uses kernel version **4.18**, the necessary kernel headers are pre-installed, so enabling eBPF is safe and has no impact.

