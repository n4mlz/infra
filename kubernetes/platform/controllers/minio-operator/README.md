# MinIO Operator

[minio/operator](https://github.com/minio/operator) v7.1.1 に pin。

manifest を `kubectl kustomize` で生成し、そのまま vendor する。
Namespace (`minio-operator`) は vendor 元の定義をそのまま使う。

## ファイル構成

| ファイル | 生成元 |
|---------|-------|
| `artifacts/operator.yaml` | `kubectl kustomize "github.com/minio/operator?ref=v7.1.1"` |

## 更新手順

```bash
task minio-operator:update
```

`Taskfile.yml` 内の `MINIO_OPERATOR_VERSION` を変更してから実行する。
