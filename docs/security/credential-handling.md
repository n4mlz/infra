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
| GitHub Flux Bootstrap Token | 1Password | Flux bootstrap 時に `op read` で注入。fine-grained PAT: Administration(read), Contents(read/write), Metadata(read), n4mlz/infra のみ |
| SOPS age private key | 1Password | `task pull-age-key` で `.local/` に復元 |
| Talos secrets (暗号化) | Git (public) | `talsecret.sops.yaml`。SOPS で暗号化済み |
| kubeconfig | `.local/`（gitignore） | クラスタから取得。永続保存しない |
| talosconfig | `.local/`（gitignore） | talhelper で生成。永続保存しない |
| Terraform ステート | バックエンドまたは暗号化バックアップ | Git に置かない |
| ExternalSecret マニフェスト | Git（public） | 参照のみ、値は含まない |
| External Secrets Operator 1Password service account token (暗号化) | Git（public） | `kubernetes/platform/config/external-secrets/bootstrap/op-service-account-token.sops.yaml`。SOPS で暗号化済み |
| 1Password service account token | 1Password | External Secrets Operator bootstrap Secret の再生成時に `op read` で注入。SOPS 暗号化ののち commit |

## SOPS 暗号化ルール

### Kubernetes Secret manifest は `data` / `stringData` のみ暗号化する

Kubernetes 配下の `.sops.yaml` / `.sops.yml` は、`.sops.yaml` の `^kubernetes/.+\.sops\.ya?ml$` rule で `data` / `stringData` の値だけを暗号化する。Secret の名前や namespace は Git 上で見える情報として扱う。

```yaml
# 正しい配置
kubernetes/platform/config/external-secrets/bootstrap/op-service-account-token.sops.yaml

# 暗号化後の例
apiVersion: v1
kind: Secret
metadata:
  name: op-service-account-token
  namespace: external-secrets
type: Opaque
stringData:
  token: ENC[AES256_GCM,...]
sops:
  ...
```

### Talos secrets は別 rule

`talos/talsecret.sops.yaml` は Kubernetes Secret ではなく Talos secrets bundle のため、別の暗号化ルールを適用する。

## 注入パターン

### Terraform

```bash
# TF_VAR_ 環境変数経由
export TF_VAR_proxmox_endpoint="https://camellia:8006/"
export TF_VAR_proxmox_api_token_id="$(op read 'op://Personal/Proxmox/token_id')"
export TF_VAR_proxmox_api_token_secret="$(op read 'op://Personal/Proxmox/secret')"
tofu plan
```

### Kubernetes

```bash
# talosctl kubeconfig は task talos:kubeconfig で実行
# .local/kubeconfig が生成される

export KUBECONFIG="$PWD/.local/kubeconfig"
kubectl get nodes
```

## 脅威モデル: devcontainer 侵害時

devcontainer が侵害された場合：

1. **Proxmox トークン**: Proxmox UI で取り消し、新トークン作成、1Password 更新
2. **Cloudflare トークン**: Cloudflare ダッシュボードで取り消し、新トークン作成、1Password 更新
3. **kubeconfig**: Talos コントロールプレーンノードから再生成
4. **talosconfig**: Talos コントロールプレーンノードから再生成
5. **External Secrets Operator 1Password service account token**: 1Password 側で取り消し、新 token 作成、SOPS bootstrap Secret を再暗号化
6. **1Password セッション**: サインアウト。コンテナは使い捨てなので問題なし

devcontainer に永続的なシークレットは保持されないため、被害はアクティブなセッショントークンのみに限定されます。
