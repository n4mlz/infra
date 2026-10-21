# Tailscale / Persistent Volume Smoke Test

## 概要

Tailscale Kubernetes Operator による Service の Tailnet 公開と、`longhorn-rwo` PersistentVolumeClaim のデータ保持を確認するためのテストアプリ。

## 公開範囲

このアプリは `tailscale.com/expose` による L3 Service proxy だけを使う。`HTTPRoute` と Funnel annotation は設定しないため、Public Gateway や Funnel からインターネットには公開しない。`tailscale.com/expose` は Tailnet 内から Service に接続するための機能で、Funnel は別途明示的に設定する。

## 確認方法

Service の hostname は `tailscale-smoke-test`。Tailnet に接続した端末から次を実行し、応答本文を確認する。

```bash
curl http://tailscale-smoke-test/
```

Tailnet policy で接続元から `tag:k8s` の TCP/80 を許可する。`tagOwners` の設定だけではサービスへの接続許可にならない。

応答は `Tailscale and persistent volume smoke test`。Pod を削除して Deployment に再作成させた後、同じ応答が返ることを確認すると、PVC 上のデータが保持されたことを確認できる。

```bash
kubectl -n tailscale-smoke-test delete pod -l app.kubernetes.io/name=tailscale-smoke-test
```

PVC は Longhorn `longhorn-rwo` StorageClass の 64 MiB volume を使う。
