# Tested Prometheus alert rules for Kubernetes & node_exporter — with promtool unit tests and runbooks

[![promtool tests](https://github.com/Fractal-Techware/prometheus-alert-rules/actions/workflows/test.yml/badge.svg)](https://github.com/Fractal-Techware/prometheus-alert-rules/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Prometheus 2.42+ | 3.x](https://img.shields.io/badge/Prometheus-2.42%2B%20%7C%203.x-e6522c?logo=prometheus&logoColor=white)
![Alerts: 12](https://img.shields.io/badge/alerts-12-informational)
![promtool tests: 28](https://img.shields.io/badge/promtool%20tests-28%20passing-brightgreen)

**12 production-ready Prometheus alerting rules** for the failures that wake people up most:
CrashLoopBackOff, OOMKilled containers, stuck Deployment rollouts, NotReady pods and nodes,
full disks, and down hosts. Every alert ships with:

- **promtool unit tests** — one proving it fires on the failure pattern, one proving it stays quiet on healthy input
- **a runbook** — meaning, impact, diagnosis (`kubectl` + PromQL), mitigation, escalation
- **consistent labels and annotations** — `severity`, `summary`, `description`, `runbook_url`
- **tuned `for:` durations** — no `for: 0m` noise during rollouts and restarts

Works with Prometheus 2.42+ and 3.x, kube-prometheus-stack / prometheus-operator,
Grafana Mimir, Thanos and VictoriaMetrics. Metric names match kube-state-metrics v2.x and node_exporter 1.x.

By [Fractal Techware](https://store.fractaltechware.com/?utm_source=github&utm_medium=readme&utm_campaign=free-repo). MIT licensed.

## Included alerts

| Alert | Severity | `for:` | What it catches | Runbook |
|---|---|---|---|---|
| `KubePodCrashLooping` | warning | 15m | Container stuck in CrashLoopBackOff | [runbook](runbooks/kubernetes-workloads/KubePodCrashLooping.md) |
| `KubeContainerOOMKilled` | warning | – (`keep_firing_for: 10m`) | Container restarted after exceeding its memory limit | [runbook](runbooks/kubernetes-workloads/KubeContainerOOMKilled.md) |
| `KubePodNotReady` | warning | 15m | Pod Pending / Unknown / Failed (Job pods excluded) | [runbook](runbooks/kubernetes-workloads/KubePodNotReady.md) |
| `KubeImagePullBackOff` | warning | 10m | ImagePullBackOff, ErrImagePull, InvalidImageName | [runbook](runbooks/kubernetes-workloads/KubeImagePullBackOff.md) |
| `KubeDeploymentReplicasMismatch` | warning | 15m | Fewer available replicas than desired, no rollout in progress | [runbook](runbooks/kubernetes-workloads/KubeDeploymentReplicasMismatch.md) |
| `KubeDeploymentRolloutStuck` | warning | 15m | Rollout exceeded its progress deadline | [runbook](runbooks/kubernetes-workloads/KubeDeploymentRolloutStuck.md) |
| `KubeNodeNotReady` | warning | 15m | Kubernetes node not Ready | [runbook](runbooks/kubernetes-nodes/KubeNodeNotReady.md) |
| `NodeExporterDown` | critical | 5m | Host or node_exporter unreachable | [runbook](runbooks/node-exporter/NodeExporterDown.md) |
| `NodeFilesystemSpaceFillingUp` | warning / critical | 1h | Disk predicted full within 24h / 4h (`predict_linear`) | [runbook](runbooks/node-exporter/NodeFilesystemSpaceFillingUp.md) |
| `NodeFilesystemAlmostOutOfSpace` | warning / critical | 30m | Less than 10% / 5% disk space left | [runbook](runbooks/node-exporter/NodeFilesystemAlmostOutOfSpace.md) |
| `NodeHighCPUUsage` | warning | 30m | Host CPU above 90% | [runbook](runbooks/node-exporter/NodeHighCPUUsage.md) |
| `NodeMemoryHighUtilization` | warning | 15m | Host memory utilisation above 90% | [runbook](runbooks/node-exporter/NodeMemoryHighUtilization.md) |

12 alerts · 14 rules (two alerts have warning and critical variants) · 28 promtool unit tests · 12 runbooks.

## Quick start

### 1. Prove the rules work (10 seconds)

```bash
git clone https://github.com/Fractal-Techware/prometheus-alert-rules.git
cd prometheus-alert-rules
./run-tests.sh      # uses local promtool, or the prom/prometheus Docker image
```

```
==> promtool check rules (3 files)
...
==> promtool test rules (3 files)
  SUCCESS
All checks passed.
```

### 2a. Plain Prometheus

Copy `rules/` next to your Prometheus config and add:

```yaml
rule_files:
  - /etc/prometheus/rules/*.yml
```

Reload (`curl -X POST http://localhost:9090/-/reload` with `--web.enable-lifecycle`) and open **Alerts**.

Want to look around first? `docker compose -f examples/docker-compose.yml up -d` starts
Prometheus + node_exporter with the rules loaded at http://localhost:9090/alerts.

### 2b. Kubernetes (kube-prometheus-stack / prometheus-operator)

Wrap each rule file in a `PrometheusRule` object with [yq](https://github.com/mikefarah/yq) v4 and apply:

```bash
for f in rules/*.rules.yml; do
  N="$(basename "$f" .rules.yml)" yq '{"apiVersion": "monitoring.coreos.com/v1", "kind": "PrometheusRule",
    "metadata": {"name": strenv(N), "namespace": "monitoring", "labels": {"release": "kube-prometheus-stack"}},
    "spec": {"groups": .groups}}' "$f"
  echo "---"
done | kubectl apply -f -
```

The `release` label must match your `prometheus.prometheusSpec.ruleSelector`. kube-prometheus-stack's
default rules include alerts with the same names (e.g. `KubePodCrashLooping`); disable the
overlapping `defaultRules.rules.kubernetesApps` / `nodeExporterAlerting` groups to avoid duplicates.

### 2c. Mimir, Grafana Cloud, Thanos, VictoriaMetrics

`mimirtool rules load rules/*.yml` · Thanos Ruler `--rule-file=rules/*.yml` · vmalert `-rule=rules/*.yml`

### Runbook links

`runbook_url` annotations are relative (`runbooks/<domain>/<Alert>.md`). Prefix them with
wherever you host the runbooks, for example:

```bash
sed -i.bak 's#runbook_url: runbooks/#runbook_url: https://github.com/<you>/<repo>/blob/main/runbooks/#' rules/*.yml tests/*.yml
```

## Why tested alerts?

Most alert rules are copied from a blog post or a snippet collection and never exercised
until a real incident. Common failure modes:

- **Metric renamed** in kube-state-metrics v2 or node_exporter 1.x — the alert silently never fires.
- **Label mismatch** in a `on (...)` join — the expression returns nothing.
- **No `for:`** — every rollout and restart pages someone.
- **Wrong exclusions** — tmpfs, overlay or read-only filesystems trigger disk alerts.

A [promtool unit test](https://prometheus.io/docs/prometheus/latest/configuration/unit_testing_rules/)
feeds synthetic series into the rule and asserts the exact labels and annotations that fire at a
given time. Each alert here has at least one positive test and one negative test
(e.g. *KubePodNotReady stays quiet for Job pods*, *NodeFilesystemAlmostOutOfSpace ignores tmpfs*).
CI runs them on every push (`.github/workflows/test.yml`), and you can run them on your own
customised copy the same way.

## Repository layout

```
rules/       alerting rules (3 groups: Kubernetes workloads, Kubernetes nodes, node_exporter)
tests/       promtool unit tests (*.test.yml)
runbooks/    one Markdown runbook per alert
examples/    prometheus.yml + docker-compose trial stack
run-tests.sh promtool check rules + test rules (local binary or Docker)
```

## Runbooks for every alert

On call with an alert that isn't in this repo? [https://fractal-techware.github.io/runbooks/](https://fractal-techware.github.io/runbooks/) has a runbook page for all 165 alerts in the full pack: what the alert means, common causes and the first commands to run.

## Want the full set?

This repository is a free sample of the
**[Prometheus Alert Rules & Runbook Pack](https://store.fractaltechware.com/l/prometheus-alert-rules-pack?utm_source=github&utm_medium=readme&utm_campaign=free-repo)**,
built from the same source and held to the same test standard. If these 12 alerts are
useful, the paid tiers cover the rest of a production stack:

| | **Free** (this repo) | **Starter** $19 | **Pro** $49 | **Studio** $99 |
|---|:---:|:---:|:---:|:---:|
| Alerting rules | 12 alerts | 49 | 179 | 179 |
| Domains | K8s workloads/nodes, hosts | K8s workloads/nodes, hosts | 20 | 20 |
| promtool unit tests | 28 | 98 | 364 (+17 recording rules) | 364 |
| Runbooks | 12 | 46 | 165 | 165 |
| StatefulSets, DaemonSets, node pressure, capacity, inodes, network, RAID, clock | – | yes | yes | yes |
| Control plane, PVCs, Jobs, HPA, certificates, Prometheus/Alertmanager self-monitoring | – | – | yes | yes |
| PostgreSQL, Redis, Kafka, NGINX Ingress, Loki, CoreDNS, etcd, blackbox, SLO burn rates | – | – | yes | yes |
| PrometheusRule CRDs + tested Alertmanager routing | – | – | yes | yes |
| Generator (thresholds/labels from one file), Slack/PagerDuty/Teams/email templates, Helm values, HTML runbook site | – | – | – | yes |
| License | MIT | own organization | own organization | client / agency use |

[See the full pack on Gumroad →](https://store.fractaltechware.com/l/prometheus-alert-rules-pack?utm_source=github&utm_medium=readme&utm_campaign=free-repo)

## Contributing

Issues and pull requests are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). Every rule change needs a promtool test.

## License

[MIT](LICENSE) © Fractal Techware
