# Ops Devcontainer

この devcontainer はインフラ運用における**唯一の管理環境**です。

## 目的

- Proxmox API に対する Terraform の実行
- 1Password からのシークレット注入（実行時）
- コンテナ内に永続的な状態を保持しない

## 前提条件

- Docker（または devcontainer 対応の Podman）
- Git
- Dev Containers 拡張機能を入れた VS Code（または devcontainer CLI）
- 認証済みの 1Password デスクトップアプリまたは CLI
- Tailscale 接続済み（Proxmox API への到達用）

## 使い方

```bash
# VS Code で開く
code .

# または devcontainer CLI
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . bash
```

## ツール

全てのバージョンは `.devcontainer/Dockerfile` で固定されています。

| ツール | 目的 |
|------|---------|
| OpenTofu | Proxmox VM の IaC |
| 1Password CLI | 1Password ボルトからのシークレット注入 |
| jq | JSON 処理 |
| talosctl | Talos クラスタの管理 |
| kubectl | Kubernetes クラスタの操作 |
| helm | Kubernetes パッケージ管理 |
| flux | Kubernetes GitOps 管理 |
| talhelper | Talos config 生成 |
| sops | シークレット暗号化 |
| age | SOPS 用暗号化鍵 |
| k9s | Kubernetes クラスタ管理 TUI |

## シークレットの扱い

シークレットはコンテナイメージに**決して焼き込みません**。実行時に注入します：

```bash
# 1Password から環境変数として注入
export TF_VAR_proxmox_api_token_id="$(op read 'op://Personal/Proxmox/token_id')"
export TF_VAR_proxmox_api_token_secret="$(op read 'op://Personal/Proxmox/secret')"

tofu plan
```

## ステート管理

- Terraform の state ファイルはコンテナ外に保存
- 現在: ローカル state + 1Password への暗号化バックアップ

## セキュリティ

- コンテナは使い捨て。内部に状態は永続化しない
- `.local/` ディレクトリは gitignore され、ホストからマウント
- 認証情報は 1Password CLI で注入。ファイルには保存しない
- 作業後、`.local/` は安全に削除・再取得可能
