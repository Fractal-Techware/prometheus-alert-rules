# KubeContainerOOMKilled

**Container was OOM killed.**

| | |
|---|---|
| Severity | warning |
| Pending (`for:`) | 0m (warning) |
| `keep_firing_for:` | 10m |
| Domain | Kubernetes workloads |
| Requires | kube-state-metrics v2.x |
| Rule file | `rules/kubernetes-workloads.rules.yml` (group `ftw.kubernetes-workloads.alerts`) |

## Meaning

The container restarted within the last 10 minutes and its last termination reason is `OOMKilled` - the kernel killed it for exceeding its cgroup memory limit. `keep_firing_for` keeps the alert up for 10 minutes so a single kill is not lost between notifications.

## Impact

In-flight requests on that replica failed and in-memory state was lost. Repeated kills lead to CrashLoopBackOff.

## Diagnosis

- Confirm the limit and the last state:
  ```bash
  kubectl -n <namespace> get pod <pod> -o jsonpath='{.spec.containers[*].resources}'
  kubectl -n <namespace> describe pod <pod> | grep -A5 "Last State"
  ```
- Memory working set versus limit over time:
  ```promql
  max by (pod, container) (container_memory_working_set_bytes{namespace="<namespace>", pod="<pod>", container!=""})
    / on (pod, container) group_left max by (pod, container) (kube_pod_container_resource_limits{namespace="<namespace>", pod="<pod>", resource="memory"})
  ```
- A steady climb suggests a leak; a sudden spike suggests a large request or batch.

## Mitigation

- Raise the memory limit (and request) to cover the observed peak plus headroom.
- For JVM/Node.js/Go, align heap/GC settings with the container limit (e.g. `-XX:MaxRAMPercentage`, `GOMEMLIMIT`).
- Fix the leak or bound the workload (batch size, cache size) if usage grows without bound.

## Escalation

- **warning**: Notify the owning team's alert channel. Acknowledge within business hours; create a ticket if it cannot be resolved the same day. Escalate to critical handling if it trends toward the critical condition.

Route to the team that owns the namespace. Platform on-call only takes over when several namespaces are affected at once (likely a node, network or control-plane problem).

## Rule definition

```yaml
- alert: KubeContainerOOMKilled
  expr: |-
    (increase(kube_pod_container_status_restarts_total{job="kube-state-metrics", namespace=~".+"}[10m]) >= 1)
    and on (cluster, namespace, pod, container)
    (kube_pod_container_status_last_terminated_reason{job="kube-state-metrics", reason="OOMKilled"} == 1)
  keep_firing_for: 10m
  labels:
    severity: warning
  annotations:
    summary: Container was OOM killed.
    description: Container {{ $labels.container }} in pod {{ $labels.namespace }}/{{ $labels.pod }} restarted after being killed for exceeding its memory limit.
    runbook_url: runbooks/kubernetes-workloads/KubeContainerOOMKilled.md
```

---
Free sample of the [Prometheus Alert Rules & Runbook Pack](https://fractaltechware.gumroad.com/l/prometheus-alert-rules-pack?utm_source=github&utm_medium=runbook&utm_campaign=free-repo) · Fractal Techware · MIT · [All runbooks](../README.md)
