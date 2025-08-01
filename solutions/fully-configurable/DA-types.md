## `metrics_filter`

The `metrics_filter` variable allows you to control which custom metrics are collected by the IBM Cloud Monitoring agent. You can specify patterns to **include** or **exclude** certain metrics, giving you fine-grained control over the data sent to IBM Cloud Monitoring.

### Type

```hcl
type = list(object({
  include = optional(string)
  exclude = optional(string)
}))
```

### Description

- **Purpose:**
  Use `metrics_filter` to specify which metrics to include or exclude from collection. This is useful for reducing noise, focusing on relevant metrics, or optimizing resource usage.

- **How it works:**
  Each entry in the list can have an `include` or `exclude` field (or both).
  - The value should be a string pattern (supports wildcards, e.g., `metricA.*`).
  - `exclude` takes precedence over `include` if both match a metric.

- **Default:**
  ```hcl
  default = []
  ```
  By default, no filtering is applied—all metrics are collected.

### Example Usage

```hcl
[
  { exclude = "kube_pod_container_status_terminated_reason_oomkilled" },
  { include = "custom_metric_prefix.*" }
]
```

- The above configuration will:
  - Exclude all metrics matching `kube_pod_container_status_terminated_reason_oomkilled`
  - Include all metrics starting with `custom_metric_prefix.`

### References

- [IBM Docs: Filter metrics](https://cloud.ibm.com/docs/monitoring?topic=monitoring-change_kube_agent#change_kube_agent_inc_exc_metrics)
---

**Tip:**
Use `metrics_filter` to optimize your monitoring setup by collecting only the metrics that matter most to your use case. This can help reduce costs and improve performance.

## `prometheus_config`

The `prometheus_config` variable allows you to enable sysdig agent to scrape metrics from processes that expose Prometheus metric endpoints on its own host and send findings to the Sysdig collector for storing and further processing.

### Type

```hcl
map(any)
```

### Example Usage

```hcl
{
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
          action = "keep"
          source_labels = ["__meta_kubernetes_pod_host_ip"]
          regex = "__HOSTIPS__"
        },
        {
          action = "drop"
          source_labels = ["__meta_kubernetes_pod_annotation_promcat_sysdig_com_omit"]
          regex = "true"
        },
        {
          source_labels = ["__meta_kubernetes_pod_phase"]
          action = "keep"
          regex = "Running"
        }
      ]
    }
  ]
}
```

## `tolerations`

The `tolerations` setting can be used to define the tolerations that the IBM Cloud Monitoring agent applies to its pods. This variable allows you to define which **node taints** the monitoring agent should **tolerate** when deployed. It ensures that agent pods can be scheduled on nodes with specific taints.

### Options

Entries in the list of `tolerations` can have the following fields.

- `key` (optional): The taint key that the toleration applies to.
- `operator` (optional): The operator to use for the toleration. Valid values are `Exists` and `Equal`.
- `value` (optional): The value to match for the taint key.
- `effect` (optional): The effect of the taint to tolerate. Valid values are `NoSchedule`, `PreferNoSchedule`, and `NoExecute`.
- `tolerationSeconds` (optional): The duration (in seconds) for which the toleration is valid when the `effect` is `NoExecute`.

### Default

```hcl
[{
  operator = "Exists"
},
{
  operator = "Exists"
  effect   = "NoSchedule"
  key      = "node-role.kubernetes.io/master"
}]
```
The default behaviour configures the agent to tolerate any taint and explicitly allows master node taints (`NoSchedule`).

### Example Usage

```hcl
[
  {
    key      = "example-key"
    operator = "Equal"
    value    = "example-value"
    effect   = "NoSchedule"
  },
  {
    operator = "Exists"
  }
]
```
- The first toleration applies to any nodes with taint key `example-key` and a value of `example-value`, with the `NoSchedule` effect.
- The second toleration applies to any taint key regardless of value, due to the `Exists` operator.

### References

- [Kubernetes Taints and Tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/)
