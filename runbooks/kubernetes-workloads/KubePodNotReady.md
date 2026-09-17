# KubePodNotReady

**Pod has been in a non-ready state.**

| | |
|---|---|
| Severity | warning |
| Pending (`for:`) | 15m (warning) |
| Domain | Kubernetes workloads |
| Requires | kube-state-metrics v2.x |
| Rule file | `rules/kubernetes-workloads.rules.yml` (group `ftw.kubernetes-workloads.alerts`) |

## Meaning

The pod phase has been `Pending`, `Unknown` or `Failed` for the whole pending period. Pods owned by Jobs are excluded (the full pack covers them with KubeJobFailed).

## Impact

The workload runs with fewer replicas than intended. A single-replica workload is unavailable.

## Diagnosis

- Look at the scheduling and container events:
  ```bash
  kubectl -n <namespace> describe pod <pod>
  kubectl -n <namespace> get events --sort-by=.lastTimestamp | tail -20
  ```
- `Pending` with `FailedScheduling`: insufficient CPU/memory, taints, node selectors, or an unbound PVC.
- `Unknown`: the node stopped reporting; check `kubectl get nodes` and KubeNodeNotReady.
- Cluster-wide view:
  ```promql
  sum by (namespace, phase) (kube_pod_status_phase{phase=~"Pending|Unknown|Failed"})
  ```

## Mitigation

- Insufficient resources: scale the node pool, lower requests, or remove stale workloads.
- Unbound PVC: fix the StorageClass or provision the volume (the full pack alerts on this with KubePersistentVolumeClaimPending).
- Node lost: cordon and drain the node; the controller recreates the pod elsewhere.
- Failed pods that will not recover: `kubectl -n <namespace> delete pod <pod>` after capturing logs.

## Escalation

- **warning**: Notify the owning team's alert channel. Acknowledge within business hours; create a ticket if it cannot be resolved the same day. Escalate to critical handling if it trends toward the critical condition.

Route to the team that owns the namespace. Platform on-call only takes over when several namespaces are affected at once (likely a node, network or control-plane problem).

## Rule definition

```yaml
- alert: KubePodNotReady
  expr: |-
    max by (cluster, namespace, pod) (kube_pod_status_phase{job="kube-state-metrics", namespace=~".+", phase=~"Pending|Unknown|Failed"}) > 0
    unless on (cluster, namespace, pod)
    max by (cluster, namespace, pod) (kube_pod_owner{job="kube-state-metrics", owner_kind="Job"})
  for: 15m
  labels:
    severity: warning
  annotations:
    summary: Pod has been in a non-ready state.
    description: Pod {{ $labels.namespace }}/{{ $labels.pod }} has been Pending, Unknown or Failed for longer than 15m.
    runbook_url: runbooks/kubernetes-workloads/KubePodNotReady.md
```

---
Free sample of the [Prometheus Alert Rules & Runbook Pack](https://fractaltechware.gumroad.com/l/prometheus-alert-rules-pack?utm_source=github&utm_medium=runbook&utm_campaign=free-repo) · Fractal Techware · MIT · [All runbooks](../README.md)
