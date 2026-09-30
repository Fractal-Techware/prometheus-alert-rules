# KubeDeploymentReplicasMismatch

**Deployment has fewer available replicas than desired.**

| | |
|---|---|
| Severity | warning |
| Pending (`for:`) | 15m (warning) |
| Domain | Kubernetes workloads |
| Requires | kube-state-metrics v2.x |
| Rule file | `rules/kubernetes-workloads.rules.yml` (group `ftw.kubernetes-workloads.alerts`) |

## Meaning

Desired replicas are higher than available replicas and the rollout is not making progress (updated replicas unchanged for 10 minutes).

## Impact

Reduced capacity and redundancy; an outage if available replicas reach zero.

## Diagnosis

- ```bash
  kubectl -n <namespace> get deployment <deployment> -o wide
  kubectl -n <namespace> get pods -l <selector> -o wide
  ```
- Unavailable pods usually show why: Pending (scheduling), CrashLoopBackOff, or failing readiness probes.
- ```promql
  kube_deployment_spec_replicas{deployment="<deployment>"} - kube_deployment_status_replicas_available{deployment="<deployment>"}
  ```

## Mitigation

- Resolve the pod-level cause (see KubePodNotReady / KubePodCrashLooping).
- If an HPA raised replicas beyond cluster capacity, add nodes or cap `maxReplicas`.
- Roll back a release that broke readiness: `kubectl -n <namespace> rollout undo deployment/<deployment>`.

## Escalation

- **warning**: Notify the owning team's alert channel. Acknowledge within business hours; create a ticket if it cannot be resolved the same day. Escalate to critical handling if it trends toward the critical condition.

Route to the team that owns the namespace. Platform on-call only takes over when several namespaces are affected at once (likely a node, network or control-plane problem).

## Rule definition

```yaml
- alert: KubeDeploymentReplicasMismatch
  expr: |-
    (kube_deployment_spec_replicas{job="kube-state-metrics", namespace=~".+"} > kube_deployment_status_replicas_available{job="kube-state-metrics", namespace=~".+"})
    and
    (changes(kube_deployment_status_replicas_updated{job="kube-state-metrics", namespace=~".+"}[10m]) == 0)
  for: 15m
  labels:
    severity: warning
  annotations:
    summary: Deployment has fewer available replicas than desired.
    description: Deployment {{ $labels.namespace }}/{{ $labels.deployment }} has had fewer available replicas than the desired {{ $value | humanize }} for longer than 15m, and no rollout is progressing.
    runbook_url: runbooks/kubernetes-workloads/KubeDeploymentReplicasMismatch.md
```

---
Free sample of the [Prometheus Alert Rules & Runbook Pack](https://store.fractaltechware.com/l/prometheus-alert-rules-pack?utm_source=github&utm_medium=runbook&utm_campaign=free-repo) · Fractal Techware · MIT · [All runbooks](../README.md)
