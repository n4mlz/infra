# GitOps Bootstrap

Flux が SOPS 暗号化 manifest を復号するには、`flux-system` namespace に `sops-age` Secret が必要です。

この Secret は Flux 自身に管理させると循環依存になるため、Taskfile で手動作成します。

## Trust Anchor

```
1Password → age private key → kubectl create secret → flux-system/sops-age
```

`sops-age` Secret は Git に置きません（平文も暗号化も）。SOPS 復号のための root trust anchor です。

## 実行

```bash
task pull-age-key
task flux:bootstrap-sops
```

## 確認

```bash
kubectl -n flux-system get secret sops-age
kubectl -n flux-system get kustomization flux-system -o yaml | grep -A3 decryption
```
