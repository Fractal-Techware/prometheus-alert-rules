# KubeDeploymentRolloutStuck

**Deployment rollout is not progressing.**

| | |
|---|---|
| Severity | warning |
| Pending (`for:`) | 15m (warning) |
| Domain | Kubernetes workloads |
| Requires | kube-state-metrics v2.x |
| Rule file | `rules/kubernetes-workloads.rules.yml` (group `ftw.kubernetes-workloads.alerts`) |

## Meaning

The Deployment controller set `Progressing=False` (reason `ProgressDeadlineExceeded`) because the rollout made no progress within `progressDeadlineSeconds`.

## Impact

The new version is not fully rolled out. Old and new ReplicaSets may be serving side by side.

## Diagnosis

- ```bash
  kubectl -n <namespace> rollout status deployment/<deployment> --timeout=5s
  kubectl -n <namespace> describe deployment <deployment> | sed -n '/Conditions/,/Events/p'
  kubectl -n <namespace> get rs -l <selector>
  ```
- Inspect the newest ReplicaSet's pods for readiness or scheduling failures.

## Mitigation

- Roll back: `kubectl -n <namespace> rollout undo deployment/<deployment>`.
- Or fix the underlying pod problem and re-trigger: `kubectl -n <namespace> rollout restart deployment/<deployment>`.

## Escalation

- **warning**: Notify the owning team's alert channel. Acknowledge within business hours; create a ticket if it cannot be resolved the same day. Escalate to critical handling if it trends toward the critical condition.

Route to the team that owns the namespace. Platform on-call only takes over when several namespaces are affected at once (likely a node, network or control-plane problem).

## Rule definition

```yaml
- alert: KubeDeploymentRolloutStuck
  expr: kube_deployment_status_condition{job="kube-state-metrics", namespace=~".+", condition="Progressing", status="false"} != 0
  for: 15m
  labels:
    severity: warning
  annotations:
    summary: Deployment rollout is not progressing.
    description: Rollout of deployment {{ $labels.namespace }}/{{ $labels.deployment }} has exceeded its progress deadline and has not progressed for 15m.
    runbook_url: runbooks/kubernetes-workloads/KubeDeploymentRolloutStuck.md
```

---
Free sample of the [Prometheus Alert Rules & Runbook Pack](https://store.fractaltechware.com/l/prometheus-alert-rules-pack?utm_source=github&utm_medium=runbook&utm_campaign=free-repo) · Fractal Techware · MIT · [All runbooks](../README.md)
