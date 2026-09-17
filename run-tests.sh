#!/usr/bin/env bash
# Validate and unit-test every rule in this repository with promtool.
#
#   ./run-tests.sh
#
# Uses promtool from your PATH when available, otherwise the pinned Docker image.
# Set USE_DOCKER=1 to force Docker.
set -euo pipefail
cd "$(dirname "$0")"

PROMETHEUS_IMAGE="${PROMETHEUS_IMAGE:-prom/prometheus:v3.14.0}"

promtool() {
  if [ -z "${USE_DOCKER:-}" ] && command -v promtool >/dev/null 2>&1; then
    command promtool "$@"
  else
    docker run --rm -v "$PWD:/repo:ro" -w /repo --entrypoint promtool "$PROMETHEUS_IMAGE" "$@"
  fi
}

shopt -s nullglob
rule_files=(rules/*.yml)
test_files=(tests/*.test.yml)

echo "==> promtool check rules (${#rule_files[@]} files)"
promtool check rules "${rule_files[@]}"

echo "==> promtool test rules (${#test_files[@]} files)"
promtool test rules "${test_files[@]}"

echo "All checks passed."
