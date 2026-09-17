# KubeImagePullBackOff

**Container image cannot be pulled.**

| | |
|---|---|
| Severity | warning |
| Pending (`for:`) | 10m (warning) |
| Domain | Kubernetes workloads |
| Requires | kube-state-metrics v2.x |
| Rule file | `rules/kubernetes-workloads.rules.yml` (group `ftw.kubernetes-workloads.alerts`) |

## Meaning

The kubelet cannot pull the container image (wrong name or tag, missing registry credentials, registry unavailable or rate limited).

## Impact

New pods cannot start. Rollouts stall and scale-out does not add capacity.

## Diagnosis

- The pull error is in the pod events:
  ```bash
  kubectl -n <namespace> describe pod <pod> | grep -iA3 "failed to pull"
  ```
- Verify the image reference and the pull secret:
  ```bash
  kubectl -n <namespace> get pod <pod> -o jsonpath='{.spec.containers[*].image}{"\n"}{.spec.imagePullSecrets}'
  ```
- Several namespaces affected at once points to the registry or node egress, not the manifest.

## Mitigation

- Fix the tag or digest in the manifest and re-apply.
- Create or refresh the pull secret and reference it from the ServiceAccount or pod spec.
- Docker Hub rate limits: authenticate pulls or mirror the image into your own registry.

## Escalation

- **warning**: Notify the owning team's alert channel. Acknowledge within business hours; create a ticket if it cannot be resolved the same day. Escalate to critical handling if it trends toward the critical condition.

Route to the team that owns the namespace. Platform on-call only takes over when several namespaces are affected at once (likely a node, network or control-plane problem).

## Rule definition

```yaml
- alert: KubeImagePullBackOff
  expr: max_over_time(kube_pod_container_status_waiting_reason{job="kube-state-metrics", namespace=~".+", reason=~"ImagePullBackOff|ErrImagePull|InvalidImageName"}[5m]) >= 1
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: Container image cannot be pulled.
    description: Container {{ $labels.container }} in pod {{ $labels.namespace }}/{{ $labels.pod }} is waiting with reason {{ $labels.reason }}.
    runbook_url: runbooks/kubernetes-workloads/KubeImagePullBackOff.md
```

---
Free sample of the [Prometheus Alert Rules & Runbook Pack](https://fractaltechware.gumroad.com/l/prometheus-alert-rules-pack?utm_source=github&utm_medium=runbook&utm_campaign=free-repo) · Fractal Techware · MIT · [All runbooks](../README.md)
