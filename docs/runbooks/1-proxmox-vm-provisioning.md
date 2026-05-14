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

```bash
cd terraform/proxmox
tofu init
tofu fmt -recursive
tofu validate
tofu plan
tofu apply
```

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
- [ ] CD-ROM に Talos ISO が接続されている
- [ ] ネットワークが vmbr0 に接続されている
- [ ] QEMU Guest Agent が有効
- [ ] VM は停止状態（まだ起動しない）

## シークレット

絶対にコミットしないもの：
- Proxmox API トークン（環境変数で渡す）
- tfstate ファイル
- kubeconfig / talosconfig
