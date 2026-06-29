# Storage Architecture

## 方針

Kubernetes の storage foundation を GitOps 管理する。
backup は Backblaze B2 を予定している（未実装）。

Longhorn と MinIO は同じ worker 群で動かすが、disk は分離する。

| 用途 | 実装 | disk | Kubernetes 名 |
|------|------|------|----------------|
| 汎用 RWO PVC | Longhorn | worker scsi1 | `longhorn-rwo` |
| object storage | MinIO on DirectPV | worker scsi2 | `directpv-object-storage` |

## Node / Disk

worker は 4 台構成。

| node | system disk | persistent volume disk | object storage disk |
|------|-------------|---------------|------------|
| wk-01 | scsi0 | scsi1 / `wk-01-pv-0` | scsi2 / `wk-01-object-0` |
| wk-02 | scsi0 | scsi1 / `wk-02-pv-0` | scsi2 / `wk-02-object-0` |
| wk-03 | scsi0 | scsi1 / `wk-03-pv-0` | scsi2 / `wk-03-object-0` |
| wk-04 | scsi0 | scsi1 / `wk-04-pv-0` | scsi2 / `wk-04-object-0` |

persistent volume disk と object storage disk はどちらも 256G のため、容量だけで識別しない。
DirectPV init 前に Talos の disk inventory で serial と slot を確認する。

## Capacity

| 項目 | 値 |
|------|----|
| Longhorn raw | 256GiB × 4 = 1TiB |
| Longhorn replica | 3 |
| Longhorn 実効目安 | 約 341GiB |
| Longhorn 運用上限目安 | 約 250〜290GiB |
| MinIO raw | 256GiB × 4 = 1TiB |
| MinIO 実効目安 | 約 512GiB |

## Kubernetes

StorageClass は default にしない。
`reclaimPolicy` は backup 完成前にデータ削除へ直結しないよう `Retain` にする。

| name | provisioner | reclaimPolicy | 用途 |
|------|-------------|---------------|------|
| `longhorn-rwo` | `driver.longhorn.io` | `Retain` | app / platform RWO PVC |
| `directpv-object-storage` | `directpv-min-io` | `Retain` | object storage Tenant PVC |

DirectPV の vendored manifest が生成する既定 StorageClass は使わない。
Git 上では削除し、`directpv-object-storage` だけを管理する。
`directpv-object-storage` は DirectPV の provisioner / xfs / identity topology 制約を維持し、reclaim policy だけを `Retain` に変える。

## Secret

MinIO root credential は 1Password `Infra` vault の `MinIO Root` item を source of truth とする。
Kubernetes Secret は External Secrets Operator が `minio-root-credentials` として作成する。

## 未完了

- persistent volume disk の `/var/mnt/persistent-volume` mount
- DirectPV drive init
- disk inventory の確定
- Longhorn PVC / VolumeSnapshot 検証
- MinIO bucket/object 検証
- Backblaze B2 backup
