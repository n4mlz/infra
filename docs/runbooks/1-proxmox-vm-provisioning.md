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

Talos VM は2段階で管理する。

### 1. 初回作成（ISO boot）

VM を作成し、Talos ISO から起動する状態にする。

```bash
cd terraform/proxmox

export TF_VAR_proxmox_api_token_id="$(op read 'op://Personal/Proxmox/token_id')"
export TF_VAR_proxmox_api_token_secret="$(op read 'op://Personal/Proxmox/secret')"

tofu init
tofu fmt -recursive
tofu validate

tofu apply \
  -var='talos_iso_file_id=local:iso/nocloud-amd64.iso' \
  -var='talos_boot_order=["ide2","scsi0"]'
```

### 2. Talos config apply 後（disk boot）

`talosctl apply-config` を実行し、Talos が disk に install された後、
ISO を外して disk boot に切り替える。

```bash
tofu apply
```

`terraform.tfvars` では `talos_iso_file_id` を指定しないため、
デフォルトで `none`（空 CD-ROM）と `boot_order = ["scsi0"]` が適用される。

## 作成予定 VM

| 名前 | VMID | 役割 | CPU | メモリ | ディスク |
|------|------|------|-----|--------|------|
| cp-01 | 3101 | control-plane | 1 | 4096 | 32G |
| cp-02 | 3102 | control-plane | 1 | 4096 | 32G |
| cp-03 | 3103 | control-plane | 1 | 4096 | 32G |
| wk-01 | 3201 | worker | 1 | 4096 | 32G |
| wk-02 | 3202 | worker | 1 | 4096 | 32G |

## 確認事項

- [ ] 5台全ての VM が Proxmox UI に存在する
- [ ] CPU/メモリ/ディスクが期待通り
- [ ] ネットワークが vmbr0 に接続されている
- [ ] QEMU Guest Agent が有効
- [ ] 初回: CD-ROM に Talos ISO が接続されている
- [ ] 通常時: CD-ROM は空、boot order が disk 優先

## シークレット

絶対にコミットしないもの：
- Proxmox API トークン（環境変数で渡す）
- tfstate ファイル
- kubeconfig / talosconfig
