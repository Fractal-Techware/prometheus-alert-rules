# NodeMemoryHighUtilization

**Host memory utilisation is above 90%.**

| | |
|---|---|
| Severity | warning |
| Pending (`for:`) | 15m (warning) |
| Domain | Hosts (node_exporter) |
| Requires | node_exporter 1.x (default collectors; systemd and hwmon noted per alert) |
| Rule file | `rules/node-exporter.rules.yml` (group `ftw.node-exporter.alerts`) |

## Meaning

Less than 10% of memory is available (MemAvailable accounts for reclaimable page cache).

## Impact

Risk of the kernel OOM killer terminating processes, heavy page-cache eviction and swapping.

## Diagnosis

- On the host: `free -m`, `ps aux --sort=-rss | head`, `smem -tk` if installed.
- ```promql
  node_memory_MemAvailable_bytes{instance="<instance>"}
  ```
- Kubernetes: `kubectl top pods -A --sort-by=memory | head`.

## Mitigation

- Restart or limit the leaking process; set memory limits on containers.
- Add memory (bigger instance) or move workloads away.

## Escalation

- **warning**: Notify the owning team's alert channel. Acknowledge within business hours; create a ticket if it cannot be resolved the same day. Escalate to critical handling if it trends toward the critical condition.

Owned by whoever operates the host (platform team for Kubernetes nodes, service owner for standalone VMs).

## Rule definition

```yaml
- alert: NodeMemoryHighUtilization
  expr: 100 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100) > 90
  for: 15m
  labels:
    severity: warning
  annotations:
    summary: Host memory utilisation is above 90%.
    description: Memory utilisation on {{ $labels.instance }} is {{ $value | printf "%.1f" }}%.
    runbook_url: runbooks/node-exporter/NodeMemoryHighUtilization.md
```

---
Free sample of the [Prometheus Alert Rules & Runbook Pack](https://fractaltechware.gumroad.com/l/prometheus-alert-rules-pack?utm_source=github&utm_medium=runbook&utm_campaign=free-repo) · Fractal Techware · MIT · [All runbooks](../README.md)
