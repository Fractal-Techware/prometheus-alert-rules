# NodeFilesystemAlmostOutOfSpace

**Filesystem has less than 10% space left.**

| | |
|---|---|
| Severity | critical, warning |
| Pending (`for:`) | 30m (warning), 30m (critical) |
| Domain | Hosts (node_exporter) |
| Requires | node_exporter 1.x (default collectors; systemd and hwmon noted per alert) |
| Rule file | `rules/node-exporter.rules.yml` (group `ftw.node-exporter.alerts`) |

## Meaning

Free space on the filesystem is below a static threshold (10% warning, 5% critical), regardless of trend.

## Impact

The filesystem is close to full. Some filesystems (ext4) reserve 5% for root, so non-root writers may already fail.

## Diagnosis

- ```promql
  100 * node_filesystem_avail_bytes{instance="<instance>"} / node_filesystem_size_bytes{instance="<instance>"}
  ```
- `sudo du -xh --max-depth=2 <mountpoint> | sort -h | tail -20` on the host.

## Mitigation

- Free space (logs, images, old backups, core dumps) or grow the volume.
- If this filesystem is expected to stay nearly full (e.g. a pre-allocated volume), exclude its mountpoint via the `fs` parameter.

## Escalation

- **warning**: Notify the owning team's alert channel. Acknowledge within business hours; create a ticket if it cannot be resolved the same day. Escalate to critical handling if it trends toward the critical condition.
- **critical**: Page the on-call engineer immediately. If not acknowledged within 15 minutes, escalate to the secondary on-call. Open an incident channel when user impact is confirmed.

Owned by whoever operates the host (platform team for Kubernetes nodes, service owner for standalone VMs).

## Rule definition

```yaml
- alert: NodeFilesystemAlmostOutOfSpace
  expr: |-
    (
      node_filesystem_avail_bytes{fstype!="", fstype!~"tmpfs|ramfs|squashfs|overlay|nsfs|fuse.lxcfs|fuse.snapfuse", mountpoint!~"/run(/.*)?|/var/lib/kubelet/.+|/var/lib/docker/.+"} / node_filesystem_size_bytes{fstype!="", fstype!~"tmpfs|ramfs|squashfs|overlay|nsfs|fuse.lxcfs|fuse.snapfuse", mountpoint!~"/run(/.*)?|/var/lib/kubelet/.+|/var/lib/docker/.+"} * 100 < 10
    and
      node_filesystem_readonly{fstype!="", fstype!~"tmpfs|ramfs|squashfs|overlay|nsfs|fuse.lxcfs|fuse.snapfuse", mountpoint!~"/run(/.*)?|/var/lib/kubelet/.+|/var/lib/docker/.+"} == 0
    )
  for: 30m
  labels:
    severity: warning
  annotations:
    summary: Filesystem has less than 10% space left.
    description: Filesystem {{ $labels.mountpoint }} ({{ $labels.device }}) on {{ $labels.instance }} has only {{ $value | printf "%.1f" }}% space left.
    runbook_url: runbooks/node-exporter/NodeFilesystemAlmostOutOfSpace.md
- alert: NodeFilesystemAlmostOutOfSpace
  expr: |-
    (
      node_filesystem_avail_bytes{fstype!="", fstype!~"tmpfs|ramfs|squashfs|overlay|nsfs|fuse.lxcfs|fuse.snapfuse", mountpoint!~"/run(/.*)?|/var/lib/kubelet/.+|/var/lib/docker/.+"} / node_filesystem_size_bytes{fstype!="", fstype!~"tmpfs|ramfs|squashfs|overlay|nsfs|fuse.lxcfs|fuse.snapfuse", mountpoint!~"/run(/.*)?|/var/lib/kubelet/.+|/var/lib/docker/.+"} * 100 < 5
    and
      node_filesystem_readonly{fstype!="", fstype!~"tmpfs|ramfs|squashfs|overlay|nsfs|fuse.lxcfs|fuse.snapfuse", mountpoint!~"/run(/.*)?|/var/lib/kubelet/.+|/var/lib/docker/.+"} == 0
    )
  for: 30m
  labels:
    severity: critical
  annotations:
    summary: Filesystem has less than 5% space left.
    description: Filesystem {{ $labels.mountpoint }} ({{ $labels.device }}) on {{ $labels.instance }} has only {{ $value | printf "%.1f" }}% space left.
    runbook_url: runbooks/node-exporter/NodeFilesystemAlmostOutOfSpace.md
```

---
Free sample of the [Prometheus Alert Rules & Runbook Pack](https://store.fractaltechware.com/l/prometheus-alert-rules-pack?utm_source=github&utm_medium=runbook&utm_campaign=free-repo) · Fractal Techware · MIT · [All runbooks](../README.md)
