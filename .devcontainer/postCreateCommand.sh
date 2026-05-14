#!/usr/bin/env bash
# Post-create script for the infra operations devcontainer.
# Verifies tool installations and prepares the working directory.

set -euo pipefail

mkdir -p .local

echo "== Tool Versions =="
tofu version
op --version
jq --version
talosctl version --client
kubectl version --client --short 2>/dev/null || kubectl version --client
helm version --short
talhelper --version
sops --version
age --version
task --version
k9s version

echo ""
echo "== Devcontainer ready =="
echo "Use 'op read' to inject secrets from 1Password"
