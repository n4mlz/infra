# Flux GitOps Bootstrap

## Goal

既存の Kubernetes クラスタを Flux GitOps 管理下に入れる。
Cilium を HelmRelease 管理に移行し、Git が desired state の single source of truth になる。

## Prerequisites

- [ ] Kubernetes クラスタが稼働している（[2-talos-cluster-bootstrap](2-talos-cluster-bootstrap.md) 完了）
- [ ] devcontainer が起動している
- [ ] `kubectl` でクラスタにアクセスできる（`.local/kubeconfig`）
- [ ] GitHub Fine-grained PAT が作成済み（[credential-handling](../security/credential-handling.md) 参照）
  - Administration: read-only
  - Contents: read & write
  - Metadata: read-only
  - 対象: `n4mlz/infra` のみ
- [ ] PAT が 1Password に保存済み（`GitHub Flux Bootstrap Token` 内の `token`）

## Procedure

### 1. GitHub Token を設定する

```bash
export KUBECONFIG="$PWD/.local/kubeconfig"
export GITHUB_TOKEN="$(op read 'op://Personal/GitHub Flux Bootstrap Token/token')"
```

### 2. Flux Bootstrap

`--token-auth` により Deploy key ではなく PAT で HTTPS 認証する。
PAT はクラスタ内の `flux-system/flux-system` Secret に保存される。
これにより Administration 権限は read-only で済む。

```bash
export KUBECONFIG="$PWD/.local/kubeconfig"

flux check --pre

flux bootstrap github \
  --token-auth \
  --owner=n4mlz \
  --repository=infra \
  --branch=main \
  --path=./kubernetes/flux \
  --personal \
  --private=false

unset GITHUB_TOKEN
```

### 3. Bootstrap 後の確認

```bash
kubectl get ns flux-system
kubectl -n flux-system get pods
flux check
flux get sources git -A
flux get kustomizations -A
```

### 4. Reconcile

```bash
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization platform -n flux-system --with-source
flux reconcile kustomization apps -n flux-system --with-source
```

### 5. Cilium 移行確認

Cilium が手動 Helm install から Flux HelmRelease に移行されていることを確認。

```bash
flux get helmreleases -A
kubectl -n kube-system get pods -l k8s-app=cilium
helm -n kube-system list
```

### 6. Smoke Test

```bash
kubectl -n smoke-test get pods -o wide

kubectl -n smoke-test run curl \
  --image=curlimages/curl:8.10.1 \
  --rm -it --restart=Never \
  -- curl -I http://nginx.smoke-test.svc.cluster.local
```

`HTTP/1.1 200 OK` が返れば成功。

### 7. Drift Correction 確認

```bash
kubectl -n smoke-test scale deployment nginx --replicas=1
kubectl -n smoke-test get deploy nginx
flux reconcile kustomization apps -n flux-system --with-source
kubectl -n smoke-test get deploy nginx
```

`replicas: 2` に戻れば Git desired state に収束している。

## 構成

```
kubernetes/
  flux/                          # Flux 自身と同期定義
    flux-system/                 # Flux bootstrap 生成物
    kustomization.yaml
    platform.yaml                # Flux Kustomization → platform
    apps.yaml                    # Flux Kustomization → apps
  platform/                      # クラスタ基盤
    namespaces.yaml              # baseline namespaces
    sources.yaml                 # HelmRepository
    cilium/                      # Cilium HelmRelease
  apps/                          # アプリケーション workload
    smoke-test/                  # 検証用 workload
```

## Kustomize 参照原則

- 親は子だけを見る
- 子は親や兄弟を見ない
- 横参照しない
- Flux が管理するパスの外を参照しない

## トラブルシュート

### Bootstrap が失敗する

- GitHub token が正しいか（権限、対象リポジトリ、有効期限）
- `--token-auth` を使っている場合、Administration は read-only でよい（Deploy key を作らないため）
- `--token-auth` を使わない場合は Administration に read & write が必要（Deploy key 作成のため）
- `--owner` と `--repository` が正しいか
- 既に `flux-system` namespace が存在していないか

### Flux Kustomization が Ready にならない

- `flux get kustomizations -A` でエラーメッセージを確認
- `kubectl -n flux-system logs -l app=source-controller --tail=100`
- GitRepository が正しい branch を参照しているか

### Cilium HelmRelease が Ready にならない

- `kubectl -n kube-system describe helmrelease cilium` で状態確認
- HelmRepository が cluster から到達可能か
- 手動 Helm release の name / namespace と HelmRelease が一致しているか
- `helm -n kube-system get values cilium` で values 比較
