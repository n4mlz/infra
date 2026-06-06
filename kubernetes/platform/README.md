# Kubernetes

このディレクトリは Kubernetes クラスタの desired state を管理する。

## 方針

- `flux` は Flux 自身と同期定義を置く
- `platform` はクラスタ基盤を管理する（controllers + config）
- `apps` はアプリケーション workload を管理する
- 手動 `kubectl apply` は原則使わない
- cluster state は Git の状態へ収束させる

## 構成

```
flux/
  flux-system/              # Flux bootstrap 生成物 (+ SOPS decryption)
  kustomization.yaml
  platform-controllers.yaml # → platform/controllers
  platform-config.yaml      # → platform/config (dependsOn: platform-controllers)
  apps.yaml                 # → apps (dependsOn: platform-config)

platform/
  controllers/
    namespaces.yaml         # platform, apps, smoke-test
    sources.yaml            # HelmRepository ×4
    cilium/                 # Cilium HelmRelease
    onepassword-operator/   # 1Password Operator + SOPS token
      secrets/              # SOPS 暗号化 Secret manifest
    cert-manager/           # cert-manager HelmRelease
    external-dns/           # external-dns HelmRelease
  config/
    onepassword-items/      # 1Password → Kubernetes Secret
    clusterissuers/         # cert-manager ClusterIssuer

apps/
  smoke-test/               # 検証用 workload
```

## Kustomize 参照原則

- 親は子だけを見る
- 子は親や兄弟を見ない
- 横参照しない
- Flux が管理するパスの外を参照しない

## Secret 管理

- bootstrap secret（sops-age）は Taskfile 経由で手動適用
- Kubernetes Secret の SOPS 暗号化ファイルは `secrets/` ディレクトリに置く
- 通常の運用 secret は 1Password を source of truth とし、1Password Operator が Kubernetes Secret に変換する
- 詳細は [docs/security/credential-handling.md](../docs/security/credential-handling.md)

## Reconcile

```bash
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization flux-system -n flux-system --with-source
flux reconcile kustomization platform-controllers -n flux-system --with-source
flux reconcile kustomization platform-config -n flux-system --with-source
flux reconcile kustomization apps -n flux-system --with-source
```

## Status

```bash
flux get sources git -A
flux get kustomizations -A
flux get helmreleases -A
kubectl get pods -A
```
