# DirectPV

[minio/directpv](https://github.com/minio/directpv) v4.1.6 に pin。

install manifest を `kubectl-directpv install -o yaml` で生成し、そのまま vendor する。
Namespace (`directpv`) は vendor 元の定義をそのまま使う。

## ファイル構成

| ファイル | 生成元 |
|---------|-------|
| `artifacts/install.yaml` | `kubectl-directpv install -o yaml` |

## 更新手順

```bash
task directpv:update
```

事前に `kubectl-directpv` plugin をインストールしておくこと。
