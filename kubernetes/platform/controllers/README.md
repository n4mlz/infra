# Platform Controllers

このディレクトリは Kubernetes クラスタ基盤の controller 本体を管理する。

## controller 一覧

| controller | 用途 |
|------------|------|
| cilium | CNI（ネットワーク） |
| onepassword-operator | 1Password → Kubernetes Secret 変換 |
| cert-manager | TLS 証明書の自動発行・更新 |
| external-dns | Cloudflare DNS record の自動管理 |

## 追加手順

1. `controllers/` 配下に `<controller>/` ディレクトリを作成
2. `kustomization.yaml` と `helmrelease.yaml` を作成
3. `sources.yaml` に HelmRepository を追加（初出の場合）
4. `controllers/kustomization.yaml` の `resources` に追加
