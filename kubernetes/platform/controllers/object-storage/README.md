# オブジェクトストレージ

このディレクトリは、クラスタ内部だけで利用する S3 互換オブジェクトストレージを管理する。
現時点では可観測性基盤の Loki / Tempo が使う一時的な MinIO を配置する。
監視基盤全体での位置づけは [監視アーキテクチャ](../../../../docs/architecture/observability.md) を正とする。

## 構成

| ディレクトリ | 内容 |
|---|---|
| `minio/` | Loki / Tempo 用 bucket を持つ in-cluster MinIO |

## 運用上の前提

- `minio-root-credentials` と `observability-object-storage-credentials` は 1Password Operator が `platform` namespace に同期する。
- MinIO は `emptyDir` を使うため、Pod 再作成で保存済み logs/traces は失われる。
- 永続化が必要になった時点で StatefulSet / PVC へ置き換える。
