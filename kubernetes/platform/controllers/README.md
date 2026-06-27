# Platform Controllers

このディレクトリは Kubernetes クラスタ基盤の controller 本体を管理する。

## controller 一覧

| controller | 用途 |
|------------|------|
| gateway-api-crds | Gateway API CRD |
| cilium | CNI（ネットワーク） + kube-proxy replacement |
| kube-vip | LoadBalancer VIP の割当と ARP 広報 |
| public-egress-routing | public VIP の reply を public VLAN へ戻す policy route |
| external-secrets | 外部 Secret provider（1Password）と Kubernetes Secret の同期 |
| cert-manager | TLS 証明書の自動発行・更新 |
| external-dns | Cloudflare DNS record の自動管理 |

## 追加手順

1. `controllers/` 配下に `<controller>/` ディレクトリを作成
2. `kustomization.yaml` と `helmrelease.yaml` を作成
3. `sources.yaml` に HelmRepository を追加（初出の場合）
4. `controllers/kustomization.yaml` の `resources` に追加
