# Kubernetes

このディレクトリは Kubernetes クラスタの desired state を管理する。

## 方針

- `flux` は Flux 自身と同期定義を置く
- `platform` はクラスタ基盤を管理する
- `apps` はアプリケーション workload を管理する
- 手動 `kubectl apply` は原則使わない
- cluster state は Git の状態へ収束させる

## 構成

```
flux/
  flux-system/    # Flux bootstrap 生成物
  kustomization.yaml
  platform.yaml   # Flux Kustomization → platform
  apps.yaml       # Flux Kustomization → apps

platform/
  namespaces.yaml # baseline namespaces
  sources.yaml    # HelmRepository
  cilium/         # Cilium HelmRelease

apps/
  smoke-test/     # 検証用 workload
```

## Kustomize 参照原則

- 親は子だけを見る
- 子は親や兄弟を見ない
- 横参照しない
- Flux が管理するパスの外を参照しない

## Reconcile

```bash
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization platform -n flux-system --with-source
flux reconcile kustomization apps -n flux-system --with-source
```

## Status

```bash
flux get sources git -A
flux get kustomizations -A
flux get helmreleases -A
kubectl get pods -A
```
