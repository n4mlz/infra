# Chart Review

このディレクトリは `review.xlair.dev` の workload と `/app/data` の永続化を管理する。SQLite database と upload data は Longhorn の `longhorn-rwo` PVC に保存する。image は `latest` tag と digest で固定し、このディレクトリの Flux image automation が専用 branch に更新を push する。Auth0 audience、client ID / domain、server URL、最大 upload size は ConfigMap で管理する。Auth0 client secret は `Infra` vault の `XLAIR Chart Review` item から External Secrets Operator が Secret に同期する。

HTTPRoute は `platform/public-gateway` の HTTPS listener に接続する。

自動更新対象の image は `ghcr.io/xlair-dev/chart-review`。
