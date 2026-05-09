#!/usr/bin/env bash
# Post-create script for the infra operations devcontainer.
# Verifies tool installations and prepares the working directory.

set -euo pipefail

mkdir -p .local

echo "== Tool Versions =="
tofu version
op --version
jq --version

echo ""
echo "== Devcontainer ready =="
echo "Use 'op read' to inject secrets from 1Password"
