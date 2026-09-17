# Contributing

Thanks for helping improve these alerts.

- **Bug reports** (an alert fires when it should not, never fires, or uses an outdated
  metric name): open an issue with your Prometheus, kube-state-metrics / node_exporter
  versions and, ideally, a sample of the series involved.
- **Pull requests**: every rule change needs a matching promtool test in `tests/` that
  proves the alert fires on the failure pattern and a test that proves it stays quiet on
  healthy input. Update the runbook in `runbooks/` if the behaviour changes.
- Run `./run-tests.sh` before opening the PR; CI runs the same checks.

Conventions: every alert has a `severity` label (`critical`, `warning` or `info`) and
`summary`, `description` and `runbook_url` annotations.

By contributing you agree that your contribution is licensed under the MIT License.
