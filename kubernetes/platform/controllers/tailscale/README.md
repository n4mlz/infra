# Tailscale Kubernetes Operator

このディレクトリは Tailscale Kubernetes Operator の HelmRelease を管理する。

## 認証

- OAuth client ID / secret は 1Password の `Tailscale Kubernetes Operator` item で管理する。
- External Secrets Operator が `tailscale/operator-oauth` Secret の `client_id` / `client_secret` key を作る。
- Helm chart は既定の `operator-oauth` Secret を読む。OAuth 値は Helm values に含めない。
- Tailnet policy は `tag:k8s-operator` が `tag:k8s` を所有できるよう設定する。詳細は [Tailscale Operator runbook](../../../../docs/runbooks/6-tailscale-operator.md) を参照。

## バージョン

Helm chart は `sources.yaml` の公式 stable repository から取得し、`helmrelease.yaml` でバージョンを固定する。
