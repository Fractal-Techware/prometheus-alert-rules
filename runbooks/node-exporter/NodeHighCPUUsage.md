# NodeHighCPUUsage

**Host CPU usage is above 90%.**

| | |
|---|---|
| Severity | warning |
| Pending (`for:`) | 30m (warning) |
| Domain | Hosts (node_exporter) |
| Requires | node_exporter 1.x (default collectors; systemd and hwmon noted per alert) |
| Rule file | `rules/node-exporter.rules.yml` (group `ftw.node-exporter.alerts`) |

## Meaning

Average CPU utilisation across all cores (everything except idle) has been above 90% for 30 minutes. The long `for:` filters out normal bursts.

## Impact

Higher latency for everything on the host; the kubelet and system daemons may be starved.

## Diagnosis

- Break down by mode (user, system, iowait, steal):
  ```promql
  sum by (mode) (rate(node_cpu_seconds_total{instance="<instance>", mode!="idle"}[5m]))
  ```
- High `steal`: noisy neighbour / burstable instance out of credits.
- On the host: `top -o %CPU`, `pidstat 5 3`. Kubernetes: `kubectl top pods -A --sort-by=cpu | head`.

## Mitigation

- Scale out the workload or move it to a bigger instance.
- Burstable instances (t3/t4g, B-series): switch to a non-burstable type or enable unlimited mode.
- Set CPU limits/requests on runaway pods.

## Escalation

- **warning**: Notify the owning team's alert channel. Acknowledge within business hours; create a ticket if it cannot be resolved the same day. Escalate to critical handling if it trends toward the critical condition.

Owned by whoever operates the host (platform team for Kubernetes nodes, service owner for standalone VMs).

## Rule definition

```yaml
- alert: NodeHighCPUUsage
  expr: 100 * (1 - avg without (cpu, mode) (rate(node_cpu_seconds_total{mode="idle"}[5m]))) > 90
  for: 30m
  labels:
    severity: warning
  annotations:
    summary: Host CPU usage is above 90%.
    description: CPU usage on {{ $labels.instance }} has been {{ $value | printf "%.1f" }}% for more than 30m.
    runbook_url: runbooks/node-exporter/NodeHighCPUUsage.md
```

---
Free sample of the [Prometheus Alert Rules & Runbook Pack](https://store.fractaltechware.com/l/prometheus-alert-rules-pack?utm_source=github&utm_medium=runbook&utm_campaign=free-repo) · Fractal Techware · MIT · [All runbooks](../README.md)
