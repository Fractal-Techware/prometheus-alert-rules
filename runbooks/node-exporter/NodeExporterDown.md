# NodeExporterDown

**Host or node_exporter is down.**

| | |
|---|---|
| Severity | critical |
| Pending (`for:`) | 5m (critical) |
| Domain | Hosts (node_exporter) |
| Requires | node_exporter 1.x (default collectors; systemd and hwmon noted per alert) |
| Rule file | `rules/node-exporter.rules.yml` (group `ftw.node-exporter.alerts`) |

## Meaning

Prometheus cannot scrape node_exporter on the host. Either the host is down, the exporter stopped, or the network path between Prometheus and the host is broken.

## Impact

All host alerts for this instance are blind. If the host itself is down, everything running on it is unavailable.

## Diagnosis

- Check the scrape error in Prometheus: **Status → Targets**, or
  ```promql
  up{instance="<instance>"}
  ```
- Is the host reachable? `ping <host>` / `curl -s http://<host>:9100/metrics | head`.
- On the host: `systemctl status node_exporter` (Kubernetes: `kubectl -n monitoring get pods -o wide | grep node-exporter`).

## Mitigation

- Restart node_exporter or the host.
- Fix firewall/security-group rules for port 9100.
- If the host was intentionally removed, remove it from service discovery / file_sd targets.

## Escalation

- **critical**: Page the on-call engineer immediately. If not acknowledged within 15 minutes, escalate to the secondary on-call. Open an incident channel when user impact is confirmed.

Owned by whoever operates the host (platform team for Kubernetes nodes, service owner for standalone VMs).

## Rule definition

```yaml
- alert: NodeExporterDown
  expr: up{job=~"node|node-exporter|node_exporter|prometheus-node-exporter"} == 0
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: Host or node_exporter is down.
    description: node_exporter target {{ $labels.instance }} (job {{ $labels.job }}) has been unreachable for 5m.
    runbook_url: runbooks/node-exporter/NodeExporterDown.md
```

---
Free sample of the [Prometheus Alert Rules & Runbook Pack](https://fractaltechware.gumroad.com/l/prometheus-alert-rules-pack?utm_source=github&utm_medium=runbook&utm_campaign=free-repo) · Fractal Techware · MIT · [All runbooks](../README.md)
