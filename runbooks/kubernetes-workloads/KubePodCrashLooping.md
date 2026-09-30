# KubePodCrashLooping

**Pod container is crash looping.**

| | |
|---|---|
| Severity | warning |
| Pending (`for:`) | 15m (warning) |
| Domain | Kubernetes workloads |
| Requires | kube-state-metrics v2.x |
| Rule file | `rules/kubernetes-workloads.rules.yml` (group `ftw.kubernetes-workloads.alerts`) |

## Meaning

The container starts, exits and is restarted by the kubelet with an increasing back-off delay (up to 5 minutes). It has been waiting in `CrashLoopBackOff` for the whole pending period.

## Impact

The pod never becomes Ready. If all replicas crash, the service is down; with some replicas crashing, capacity is reduced and rollouts are blocked.

## Diagnosis

- Inspect the pod events and last state (exit code, OOMKilled, probe failures):
  ```bash
  kubectl -n <namespace> describe pod <pod>
  ```
- Read the logs of the crashed instance, not the current one:
  ```bash
  kubectl -n <namespace> logs <pod> -c <container> --previous
  ```
- Check whether the crash started with a rollout or config change:
  ```bash
  kubectl -n <namespace> rollout history deployment/<name>
  ```
- Restart rate across the namespace:
  ```promql
  sum by (pod, container) (increase(kube_pod_container_status_restarts_total{namespace="<namespace>"}[1h]))
  ```

## Mitigation

- Bad release: `kubectl -n <namespace> rollout undo deployment/<name>`.
- Missing config or secret: restore the ConfigMap/Secret the container reads at start-up.
- Failing liveness probe on slow start: add a `startupProbe` or raise `initialDelaySeconds`.
- Exit code 137 / OOMKilled: raise the memory limit or fix the leak (see KubeContainerOOMKilled).

## Escalation

- **warning**: Notify the owning team's alert channel. Acknowledge within business hours; create a ticket if it cannot be resolved the same day. Escalate to critical handling if it trends toward the critical condition.

Route to the team that owns the namespace. Platform on-call only takes over when several namespaces are affected at once (likely a node, network or control-plane problem).

## Rule definition

```yaml
- alert: KubePodCrashLooping
  expr: max_over_time(kube_pod_container_status_waiting_reason{job="kube-state-metrics", namespace=~".+", reason="CrashLoopBackOff"}[5m]) >= 1
  for: 15m
  labels:
    severity: warning
  annotations:
    summary: Pod container is crash looping.
    description: Container {{ $labels.container }} in pod {{ $labels.namespace }}/{{ $labels.pod }} has been in CrashLoopBackOff for at least 15m.
    runbook_url: runbooks/kubernetes-workloads/KubePodCrashLooping.md
```

---
Free sample of the [Prometheus Alert Rules & Runbook Pack](https://store.fractaltechware.com/l/prometheus-alert-rules-pack?utm_source=github&utm_medium=runbook&utm_campaign=free-repo) · Fractal Techware · MIT · [All runbooks](../README.md)
