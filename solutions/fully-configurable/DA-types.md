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
metrics_filter = [
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
