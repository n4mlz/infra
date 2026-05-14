# Root of Trust

このドキュメントは、完全な自動化が不可能な**最小限の手動作業**と、インフラの信頼の起点（root of trust）を記述します。

## 自動化できないもの

ゼロタッチ自動化は原理的に不可能です。何かしらが自動化自体をブートストラップする必要があります。以下は削減不可能な手動作業です：

### 1. Proxmox のインストール

- 物理ラックサーバーに Proxmox VE をインストール
- 初期ネットワーク設定（vmbr0 など）
- root パスワードの設定

### 2. Proxmox API トークンの作成

Proxmox UI で作成：

```
Datacenter -> Permissions -> API Tokens -> Add
```

必要なトークン：

| トークン | 目的 | 最小権限 |
|-------|---------|-------------------|
| `opentofu` | Terraform による VM プロビジョニング | Administrator |

### 3. 1Password ボルトのセットアップ

以下のボルト構造を作成：

```
Personal (ボルト)
├── Proxmox (アイテム)
│   ├── token_id: <token_id>
│   └── secret: <secret>
└── SOPS age key for infra repo (ドキュメント)
    └── age private key (age-keygen で生成)
```

SOPS age key は devcontainer 内で生成する：

```bash
mkdir -p .local/sops/age
age-keygen -o .local/sops/age/keys.txt
```

生成された `keys.txt` を 1Password にドキュメントとして保存する。
public key は `.sops.yaml` の `age:` フィールドに設定する。

### 4. Talos ISO のアップロード

1. https://factory.talos.dev/ にアクセス
2. Talos のバージョンを選択
3. システム拡張に `siderolabs/qemu-guest-agent` を追加
4. ISO をダウンロード
5. Proxmox にアップロード: `camellia -> local -> ISO Images -> Upload`
6. ファイルIDを控える（例: `local:iso/talos-metal-amd64.iso`）

### 5. Tailscale Subnet Router の設定

Talos ノードは Tailscale Tailnet 上に直接参加していない。
同じ LAN 上の VM を subnet router として設定し、Talos ノード用サブネットを Tailnet に広報する。

```bash
# Talos ノードと同じ LAN 上の VM で実行
# Talos 初回 boot は DHCP のため、サブネット全体を広報
sudo tailscale set --advertise-routes=10.240.0.0/16
sudo systemctl restart tailscaled
```

その後、Tailscale admin console で subnet route を approve する。
詳細は `docs/architecture/network.md` を参照。

### 6. 初回 devcontainer の起動

```bash
git clone <repo-url>
cd infra
# VS Code の Dev Containers 拡張機能で開く
```

## 管理環境の再構築

devcontainer または管理用ワークステーションを失った場合：

1. 任意のマシンに Docker をインストール
2. infra リポジトリを clone
3. 1Password CLI を認証
4. devcontainer を起動
5. ステートバックエンドに接続（または暗号化バックアップから復元）
6. `tofu init` で再初期化

## 信頼境界

| コンポーネント | 信頼レベル | 備考 |
|-----------|-------------|-------|
| Proxmox ホスト | 最高 | 物理アクセスが必要 |
| 1Password | 最高 | 全てのシークレットを保持 |
| Devcontainer | 一時的 | 使い捨て、永続的なシークレットなし |
| Git リポジトリ（public） | 信頼なし | シークレットなし、参照のみ |
| Kubernetes クラスタ | 高 | ワークロード実行、GitOps で管理 |

## 認証情報のローテーション

認証情報が侵害された場合：

1. Proxmox UI で該当の API トークンを取り消し
2. 1Password ボルトのアクセスをローテーション
3. Talos コントロールプレーンから kubeconfig/talosconfig を再生成
4. devcontainer を再構築
5. `tofu apply` でステートの整合性を確認
