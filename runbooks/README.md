# Runbooks

One runbook per alert. Every runbook follows the same template: Meaning, Impact, Diagnosis, Mitigation, Escalation, Rule definition.

## Kubernetes workloads

| Alert | Severity | Summary |
|---|---|---|
| [KubePodCrashLooping](kubernetes-workloads/KubePodCrashLooping.md) | warning | Pod container is crash looping. |
| [KubePodNotReady](kubernetes-workloads/KubePodNotReady.md) | warning | Pod has been in a non-ready state. |
| [KubeContainerOOMKilled](kubernetes-workloads/KubeContainerOOMKilled.md) | warning | Container was OOM killed. |
| [KubeImagePullBackOff](kubernetes-workloads/KubeImagePullBackOff.md) | warning | Container image cannot be pulled. |
| [KubeDeploymentReplicasMismatch](kubernetes-workloads/KubeDeploymentReplicasMismatch.md) | warning | Deployment has fewer available replicas than desired. |
| [KubeDeploymentRolloutStuck](kubernetes-workloads/KubeDeploymentRolloutStuck.md) | warning | Deployment rollout is not progressing. |

## Kubernetes nodes

| Alert | Severity | Summary |
|---|---|---|
| [KubeNodeNotReady](kubernetes-nodes/KubeNodeNotReady.md) | warning | Node is not ready. |

## Hosts (node_exporter)

| Alert | Severity | Summary |
|---|---|---|
| [NodeExporterDown](node-exporter/NodeExporterDown.md) | critical | Host or node_exporter is down. |
| [NodeFilesystemSpaceFillingUp](node-exporter/NodeFilesystemSpaceFillingUp.md) | warning, critical | Filesystem is predicted to run out of space within 24h (warning) / 4h (critical). |
| [NodeFilesystemAlmostOutOfSpace](node-exporter/NodeFilesystemAlmostOutOfSpace.md) | warning, critical | Filesystem has less than 10% (warning) / 5% (critical) space left. |
| [NodeHighCPUUsage](node-exporter/NodeHighCPUUsage.md) | warning | Host CPU usage is above 90%. |
| [NodeMemoryHighUtilization](node-exporter/NodeMemoryHighUtilization.md) | warning | Host memory utilisation is above 90%. |

---

The [full pack](https://store.fractaltechware.com/l/prometheus-alert-rules-pack?utm_source=github&utm_medium=readme&utm_campaign=free-repo) has 165 runbooks for 179 alerts (Kubernetes, control plane, databases, Kafka, ingress, SLOs) and, in Studio, a searchable HTML runbook site.
