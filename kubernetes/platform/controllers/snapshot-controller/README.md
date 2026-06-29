# CSI Snapshot Controller

[kubernetes-csi/external-snapshotter](https://github.com/kubernetes-csi/external-snapshotter) v8.3.0 に pin。

- CRDs は upstream の `client/config/crd/` からそのまま取得
- RBAC と Deployment は `deploy/kubernetes/snapshot-controller/` からそのまま取得
- kustomize の namespace transformer で `namespace: snapshot-controller` に設定
- upstream には存在しない CRD ファイルも合わせて artifacts/ で管理

## ファイル構成

| ファイル | 元 |
|---------|-----|
| `artifacts/volumesnapshotclasses.yaml` | `client/config/crd/` |
| `artifacts/volumesnapshotcontents.yaml` | `client/config/crd/` |
| `artifacts/volumesnapshots.yaml` | `client/config/crd/` |
| `artifacts/rbac-snapshot-controller.yaml` | `deploy/kubernetes/snapshot-controller/` |
| `artifacts/setup-snapshot-controller.yaml` | `deploy/kubernetes/snapshot-controller/` |

## 更新手順

```bash
task snapshot-controller:update
```

`Taskfile.yml` 内の `SNAPSHOTTER_VERSION` を変更してから実行する。
