# Secrets, TLS, and DNS Automation

## Goal

Flux で SOPS 復号を有効にし、1Password Operator / cert-manager / external-dns を GitOps 管理下に置く。

## Prerequisites

- [ ] Flux GitOps bootstrap が完了している（[3-flux-gitops-bootstrap](3-flux-gitops-bootstrap.md) 完了）
- [ ] SOPS age key が 1Password に保存済み
- [ ] 1Password service account token が発行済み
- [ ] Cloudflare API tokens（cert-manager DNS01 用 / external-dns 用）が発行済み
- [ ] Cloudflare 管理のドメイン

## Procedure

### 1. SOPS 復号を有効化

```bash
task pull-age-key
task flux:bootstrap-sops
```

### 2. 1Password Operator の導入

1Password 側で [service account token](https://www.1password.dev/k8s/operator) を発行し、`op://Infra/1Password Kubernetes Operator/token` に保存しておく。

```bash
export KUBECONFIG="$PWD/.local/kubeconfig"

# age key を復元
task pull-age-key

# 1Password から token を読み取り、SOPS 暗号化 Secret を作成
export OP_SERVICE_ACCOUNT_TOKEN="$(op read 'op://Infra/1Password Kubernetes Operator/token')"

kubectl -n platform create secret generic onepassword-service-account-token \
  --from-literal=token="$OP_SERVICE_ACCOUNT_TOKEN" \
  --dry-run=client -o yaml \
  > kubernetes/platform/controllers/onepassword-operator/secrets/service-account-token.sops.yaml

SOPS_AGE_KEY_FILE=.local/sops/age/keys.txt \
  sops -e -i kubernetes/platform/controllers/onepassword-operator/secrets/service-account-token.sops.yaml

# 暗号化確認
grep -q "ENC\[" kubernetes/platform/controllers/onepassword-operator/secrets/service-account-token.sops.yaml

unset OP_SERVICE_ACCOUNT_TOKEN
```

生成された `service-account-token.sops.yaml` は commit する。平文 token は含まれない。

### 3. cert-manager の導入

CRD 管理を Helm chart に委譲（`crds.enabled: true`）。
HelmRelease は `platform` namespace に置く。

### 4. external-dns の導入

Cloudflare provider を使用。`policy: upsert-only` で既存レコードは保護。
Cloudflare token は 1Password Operator が生成する Secret を参照する。

### 5. Cloudflare tokens と DNS01 の設定

1Password にあらかじめ以下のアイテムを作成しておく：

| アイテム | vault | 用途 |
|----------|-------|------|
| Cloudflare cert-manager DNS01 token | Infra | cert-manager DNS01 challenge |
| Cloudflare external-dns token | Infra | external-dns の DNS record 管理 |

各アイテムの `password` フィールドに Cloudflare API token を入れる。

OnePasswordItem と ClusterIssuer は `clusterissuers.yaml` と `cloudflare-items.yaml` に定義済み。

### 6. 検証

cert-test Certificate は `apps/smoke-test/certificate.yaml` に配置。

（準備中）

## トラブルシュート

（準備中）
