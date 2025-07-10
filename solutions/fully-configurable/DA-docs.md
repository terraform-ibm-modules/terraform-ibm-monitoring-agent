When attempting to deploy the agents to cluster nodes on RH CoreOS that have no public gateways enabled (and/or have outbound traffic disabled), the pods fail to come up with the error:
```
Download of sysdigcloud-probe for version 13.9.2 failed.
curl: (28) Failed to connect to download.sysdig.com port 443: Connection timed out
Cannot load the probe
```

This happens because the agent tries to connect to the kernel and for that it needs a kernel module (default behaviour):
- If not available in the machine already, it tries to build it with the kernel headers
- if kernel headers not available, it tries to download it

To fix this, we need the ability to set the helm values `agent.ebpf.enabled` and `agent.ebpf.kind` if cluster is using nodes based on RHCOS by setting the terraform boolean input variable called `enable_universal_ebpf` to true. Enabling universal ebpf needs kernel version to be `5.8` or higher. RHEL8 already has the kernel headers and enabling `ebpf` will not cause any impact even though kernel version is `4.18`.
