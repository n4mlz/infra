# Terraform による Proxmox VM プロビジョニング

## 目標

devcontainer を介して、Terraform で Talos Kubernetes 用の VM スケルトンを Proxmox 上に作成する。

## 環境

| 項目 | 値 |
|------|-------|
| Proxmox ノード | camellia |
| ストレージ（VM） | local-zfs |
| ストレージ（ISO） | local |
| ブリッジ | vmbr0 |

## 前提条件

- [ ] Proxmox API トークンを作成し 1Password に保存
- [ ] Talos ISO を Proxmox にアップロード
- [ ] devcontainer を起動
- [ ] 1Password CLI を認証

## 手順

`terraform.tfvars` に `talos_iso_file_id` を常に記載しておく。
各 node の `bootstrap` flag で ISO の有無を制御する。

### 1. 初回作成（ISO boot が必要な node だけ）

新規 VM（wk-03, wk-04 など）を作成する際は、`locals.tf` で当該 node の `bootstrap = true` に設定する。
これにより当該 VM だけ ISO が接続され、CD-ROM boot が有効になる。

```bash
cd terraform/proxmox

export TF_VAR_proxmox_api_token_id="$(op read 'op://Personal/Proxmox/token_id')"
export TF_VAR_proxmox_api_token_secret="$(op read 'op://Personal/Proxmox/secret')"

tofu init
tofu fmt -recursive
tofu validate

tofu apply
```

### 2. Talos install 後（disk boot）

`talosctl apply-config` で Talos が disk に install されたら、
`locals.tf` の当該 node の `bootstrap` を `false` に変更し、再度 apply する。

```bash
# locals.tf を編集: wk-03, wk-04 の bootstrap を true → false に変更
tofu apply
```

既存 VM（bootstrap = false）は ISO が `none`、boot order が `["scsi0"]` のまま変更されない。

## 作成予定 VM

| 名前 | VMID | 役割 | CPU | メモリ | system disk | persistent volume disk | object storage disk |
|------|------|------|-----|--------|-------------|---------------|------------|
| cp-01 | 3101 | control-plane | 1 | 8192 | 32G | - | - |
| cp-02 | 3102 | control-plane | 1 | 8192 | 32G | - | - |
| cp-03 | 3103 | control-plane | 1 | 8192 | 32G | - | - |
| wk-01 | 3201 | worker | 1 | 4096 | 32G | 256G | 256G |
| wk-02 | 3202 | worker | 1 | 4096 | 32G | 256G | 256G |
| wk-03 | 3203 | worker | 1 | 4096 | 32G | 256G | 256G |
| wk-04 | 3204 | worker | 1 | 4096 | 32G | 256G | 256G |

worker の追加 disk は用途を分離する。

| interface | 用途 | serial |
|-----------|------|--------|
| scsi0 | Talos system disk | provider generated |
| scsi1 | persistent volume | `<node>-pv-0` |
| scsi2 | object storage | `<node>-object-0` |

persistent volume disk と object storage disk はどちらも 256G のため、容量だけで識別しない。
Talos の disk inventory では scsi slot と serial を確認してから Longhorn mount / DirectPV init を行う。

## 確認事項

- [ ] 7台全ての VM が Proxmox UI に存在する
- [ ] CPU/メモリ/ディスクが期待通り
- [ ] ネットワークが vmbr0 に接続されている
- [ ] worker の eth1（public VLAN）が接続されている
- [ ] QEMU Guest Agent が有効
- [ ] worker の scsi1/scsi2 serial が用途別に識別できる
- [ ] 初回: CD-ROM に Talos ISO が接続されている
- [ ] 通常時: CD-ROM は空、boot order が disk 優先

## シークレット

絶対にコミットしないもの：
- Proxmox API トークン（環境変数で渡す）
- tfstate ファイル
- kubeconfig / talosconfig
