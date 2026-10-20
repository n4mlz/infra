# Storage Architecture

## 方針

Kubernetes の永続ボリュームは Longhorn CSI で GitOps 管理する。

## Node / Disk

Longhorn は worker の scsi1 ディスクを使う。Talos User Volume `persistent-volume` が `*-pv-0` serial のディスクを選び、`/var/mnt/persistent-volume` に mount する。Longhorn の data path も同じ場所を使い、Talos の Kubelet `extraMounts` でコンテナ内から見えるようにする。

| node | system disk | Longhorn disk |
|------|-------------|---------------|
| wk-01 | scsi0 | scsi1 / `wk-01-pv-0` |
| wk-02 | scsi0 | scsi1 / `wk-02-pv-0` |
| wk-03 | scsi0 | scsi1 / `wk-03-pv-0` |
| wk-04 | scsi0 | scsi1 / `wk-04-pv-0` |

## Capacity

| 項目 | 値 |
|------|----|
| Longhorn raw | 256GiB × 4 = 1TiB |
| replicas / volume | 3 |
| 実効容量上限の目安 | 約 239GiB。各 worker で Longhorn の既定予約 30% を差し引き、replica 数 3 で割った値 |

## Kubernetes

StorageClass は default にしない。データ削除を避けるため `reclaimPolicy` は `Retain` とする。

| name | provisioner | reclaimPolicy | 用途 |
|------|-------------|---------------|------|
| `longhorn-rwo` | `driver.longhorn.io` | `Retain` | アプリ / platform の RWO PVC |

## 未完了

- VolumeSnapshot の動作確認
- Backblaze B2 backup
