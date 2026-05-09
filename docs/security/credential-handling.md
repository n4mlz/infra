# 認証情報の扱い

public インフラリポジトリにおけるシークレット管理のルール。

## 原則

1. **シークレットは 1Password に置く**。Git にもコンテナにも VM にも置かない
2. **参照は public、値は private**
3. **注入は実行時のみ**。1Password CLI 経由
4. **ステートは暗号化**。平文で public な場所に保存しない

## 配置ルール

| 項目 | 配置場所 | 備考 |
|------|----------|-------|
| Proxmox API トークン | 1Password | 実行時に `op read` で注入 |
| Cloudflare API トークン | 1Password | 実行時に `op read` で注入 |
| Tailscale 認証キー | 1Password | 実行時に `op read` で注入 |
| kubeconfig | `.local/`（gitignore） | クラスタから取得。永続保存しない |
| talosconfig | `.local/`（gitignore） | talosctl で生成。永続保存しない |
| Terraform ステート | バックエンドまたは暗号化バックアップ | Git に置かない |
| ExternalSecret マニフェスト | Git（public） | 参照のみ、値は含まない |
| .env ファイル | 使用しない | 1Password + `op run` を使う |

## 注入パターン

### Terraform

```bash
# TF_VAR_ 環境変数経由
export TF_VAR_proxmox_endpoint="https://camellia:8006/"
export TF_VAR_proxmox_api_token_id="$(op read 'op://Personal/Proxmox/token_id')"
export TF_VAR_proxmox_api_token_secret="$(op read 'op://Personal/Proxmox/secret')"
tofu plan

# op run 経由
op run --env-file ./op.env -- tofu apply
```

### Kubernetes

```bash
# クラスタから kubeconfig を取得
talosctl kubeconfig --nodes <cp-node> .local/

# kubectl で使用（devcontainer.json で KUBECONFIG 環境変数を設定済み）
kubectl get nodes
```

## 脅威モデル: devcontainer 侵害時

devcontainer が侵害された場合：

1. **Proxmox トークン**: Proxmox UI で取り消し、新トークン作成、1Password 更新
2. **Cloudflare トークン**: Cloudflare ダッシュボードで取り消し、新トークン作成、1Password 更新
3. **kubeconfig**: Talos コントロールプレーンノードから再生成
4. **talosconfig**: Talos コントロールプレーンノードから再生成
5. **1Password セッション**: サインアウト。コンテナは使い捨てなので問題なし

devcontainer に永続的なシークレットは保持されないため、被害はアクティブなセッショントークンのみに限定されます。
