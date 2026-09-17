# KubeNodeNotReady

**Node is not ready.**

| | |
|---|---|
| Severity | warning |
| Pending (`for:`) | 15m (warning) |
| Domain | Kubernetes nodes & capacity |
| Requires | kube-state-metrics v2.x |
| Rule file | `rules/kubernetes-nodes.rules.yml` (group `ftw.kubernetes-nodes.alerts`) |

## Meaning

The kubelet on the node has not reported `Ready=True` for the whole pending period.

## Impact

No new pods are scheduled on the node. After the eviction timeout (default 5 minutes) its pods are evicted and rescheduled, which can overload the remaining nodes.

## Diagnosis

- ```bash
  kubectl get nodes -o wide
  kubectl describe node <node> | sed -n '/Conditions/,/Addresses/p'
  ```
- On the node (SSH/SSM): `systemctl status kubelet containerd` and `journalctl -u kubelet --since "30 min ago"`.
- Check host metrics for resource exhaustion:
  ```promql
  node_memory_MemAvailable_bytes{instance=~"<node>.*"} / node_memory_MemTotal_bytes{instance=~"<node>.*"}
  ```

## Mitigation

- Restart the kubelet or container runtime if they crashed.
- If the node cannot recover: `kubectl cordon <node>`, `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data`, then replace it (managed node groups: terminate the instance).

## Escalation

- **warning**: Notify the owning team's alert channel. Acknowledge within business hours; create a ticket if it cannot be resolved the same day. Escalate to critical handling if it trends toward the critical condition.

Owned by the platform / cluster team. Involve the cloud provider when nodes fail at the infrastructure level.

## Rule definition

```yaml
- alert: KubeNodeNotReady
  expr: kube_node_status_condition{job="kube-state-metrics", condition="Ready", status="true"} == 0
  for: 15m
  labels:
    severity: warning
  annotations:
    summary: Node is not ready.
    description: Node {{ $labels.node }} has not been Ready for more than 15m.
    runbook_url: runbooks/kubernetes-nodes/KubeNodeNotReady.md
```

---
Free sample of the [Prometheus Alert Rules & Runbook Pack](https://fractaltechware.gumroad.com/l/prometheus-alert-rules-pack?utm_source=github&utm_medium=runbook&utm_campaign=free-repo) · Fractal Techware · MIT · [All runbooks](../README.md)
