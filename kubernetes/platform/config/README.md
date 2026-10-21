# Platform 設定

このディレクトリは `platform-controllers` が提供する CRD に依存する設定を管理する。`platform-config` Flux Kustomization が controller の適用後に reconciliation する。

## 配置物

| パス | 内容 |
|------|------|
| `app-hostnames.yaml` | Tailnet 公開 Service の hostname を Flux substitution 用 ConfigMap として管理 |
| `external-secrets/` | External Secrets Operator の設定 |
| `clusterissuers/` | cert-manager の ClusterIssuer |
| `gateway/` | Public Gateway と TLS Certificate |
| `storage/` | Longhorn StorageClass と VolumeSnapshotClass |

`app-hostnames.yaml` は複数アプリで共有する cluster 固有値であり、個別アプリの設定ではない。値は `apps` Flux Kustomization が `postBuild.substituteFrom` で読み込む。`apps` は `platform-config` に依存するため、参照先 ConfigMap が適用されてから substitution が実行される。アプリ側の記述ルールは [アプリケーション設定](../../apps/README.md) を参照。
