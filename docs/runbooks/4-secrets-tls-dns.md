# Secrets, TLS, and DNS Automation

## Goal

Flux で SOPS 復号を有効にし、External Secrets Operator / cert-manager / external-dns を GitOps 管理下に置く。

Secret value は 1Password を source of truth とする。Git には 1Password item field の参照と Kubernetes Secret の形だけを置く。SOPS で管理する Kubernetes Secret は、External Secrets Operator が 1Password を読むための bootstrap token に限定する。

## Prerequisites

- [ ] Flux GitOps bootstrap が完了している（[3-flux-gitops-bootstrap](3-flux-gitops-bootstrap.md) 完了）
- [ ] SOPS age key が 1Password に保存済み
- [ ] External Secrets Operator 用 1Password service account token が発行済み
- [ ] External Secrets Operator 用 1Password service account は `Infra` vault の read-only に限定済み
- [ ] Cloudflare API tokens（cert-manager DNS01 用 / external-dns 用）が 1Password に保存済み
- [ ] Cloudflare 管理のドメインがある

## 1Password item

1Password の item title と field label は、Git 側の `ExternalSecret.remoteRef.key` から参照する安定した API として扱う。

| item title | field label | 用途 |
|------------|-------------|------|
| `External Secrets Operator` | `token` | External Secrets Operator が `Infra` vault を読むための bootstrap token |
| `Cloudflare cert-manager DNS01 token` | `token` | cert-manager DNS01 challenge |
| `Cloudflare external-dns token` | `token` | external-dns の DNS record 管理 |

同一 item 内で field label を重複させない。`.env` 全体を 1Password に置かず、必要な field だけを置き、Kubernetes Secret の形は `ExternalSecret.spec.target.template` で管理する。

## Procedure

### 1. SOPS 復号を有効化

```bash
task pull-age-key
task flux:bootstrap-sops
```

### 2. External Secrets Operator bootstrap Secret を再生成する

通常は Git 上の `kubernetes/platform/config/external-secrets/bootstrap/op-service-account-token.sops.yaml` を使う。token を作り直す場合だけ、以下を実行する。

```bash
export KUBECONFIG="$PWD/.local/kubeconfig"
task pull-age-key

export OP_SERVICE_ACCOUNT_TOKEN="$(op read 'op://Infra/External Secrets Operator/token')"

kubectl -n external-secrets create secret generic op-service-account-token \
  --from-literal=token="$OP_SERVICE_ACCOUNT_TOKEN" \
  --dry-run=client -o yaml \
  > kubernetes/platform/config/external-secrets/bootstrap/op-service-account-token.sops.yaml

SOPS_AGE_KEY_FILE=.local/sops/age/keys.txt \
  sops -e -i kubernetes/platform/config/external-secrets/bootstrap/op-service-account-token.sops.yaml

grep -q "ENC\\[" kubernetes/platform/config/external-secrets/bootstrap/op-service-account-token.sops.yaml

unset OP_SERVICE_ACCOUNT_TOKEN
```

平文 token を Git に置かない。`metadata` は暗号化せず、`stringData` の値だけを SOPS で暗号化する。

### 3. Reconcile

```bash
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization platform-controllers -n flux-system --with-source
flux reconcile kustomization platform-config -n flux-system --with-source
flux reconcile kustomization apps -n flux-system --with-source
```

`platform-config` は `platform-controllers` に依存している。External Secrets Operator CRD と controller が入ってから `ClusterSecretStore` / `ExternalSecret` を適用する。

## Verification

```bash
flux get kustomizations -A
flux get helmreleases -A

kubectl -n external-secrets get pods
kubectl get clustersecretstore onepassword-infra
kubectl get externalsecrets -A

kubectl get clusterissuer
kubectl -n platform get certificate wildcard-n4mlz-dev-tls
```

Secret の中身は表示しない。key の存在だけを確認する。

```bash
kubectl -n cert-manager get secret cloudflare-cert-manager-token -o jsonpath='{.data}' | jq keys
kubectl -n external-dns get secret cloudflare-external-dns-token -o jsonpath='{.data}' | jq keys
```

cert-manager 検証：

```bash
kubectl -n cert-manager logs -l app.kubernetes.io/instance=cert-manager --tail=100
kubectl get certificates -A
kubectl get challenges -A
```

external-dns 検証：

```bash
kubectl -n external-dns logs deploy/external-dns --tail=100
```

Gateway 用の wildcard Certificate が `Ready=True` になり、`wildcard-n4mlz-dev-tls` Secret が生成されたら成功。

## トラブルシュート

### ClusterSecretStore が Ready にならない

- `kubectl describe clustersecretstore onepassword-infra` でエラー確認
- `external-secrets` namespace に `op-service-account-token` Secret が存在するか確認
- External Secrets Operator 用 1Password service account が `Infra` vault を read できるか確認

### ExternalSecret が Ready にならない

- `kubectl describe externalsecret -n cert-manager cloudflare-cert-manager-token`
- `kubectl describe externalsecret -n external-dns cloudflare-external-dns-token`
- 対象 namespace に `secrets.n4mlz.dev/onepassword-infra: "true"` label があるか確認
- 1Password item title と field label が `remoteRef.key` と一致しているか確認

### cert-manager ClusterIssuer が Ready にならない

- `kubectl describe clusterissuer letsencrypt-production` でエラー確認
- Cloudflare token Secret が存在するか: `kubectl -n cert-manager get secret cloudflare-cert-manager-token`
- `apiTokenSecretRef.key` が Secret のキーと一致しているか
- Cloudflare API token に `Zone:DNS:Edit` 権限があるか

### Certificate が Ready にならない

- `kubectl -n platform describe certificate wildcard-n4mlz-dev-tls` でエラー確認
- `kubectl -n platform get certificaterequest,order,challenge` で中間リソースを確認
- DNS01 challenge の TXT record が Cloudflare DNS に作成されているか

### external-dns が record を作成しない

- `policy: upsert-only` により削除は行われない。作成のみ
- `kubectl -n external-dns logs deploy/external-dns` でエラー確認
- Cloudflare token Secret が存在するか: `kubectl -n external-dns get secret cloudflare-external-dns-token`
