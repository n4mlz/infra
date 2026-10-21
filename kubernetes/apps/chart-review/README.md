# Chart Review

このディレクトリは `review.xlair.dev` の workload と `/app/data` の永続化を管理する。SQLite database と upload data は Longhorn の `longhorn-rwo` PVC に保存する。image は digest で固定し、Auth0 audience、client ID / domain、server URL、最大 upload size は ConfigMap で管理する。Auth0 client secret は `Infra` vault の `XLAIR Chart Review` item から External Secrets Operator が Secret に同期する。

HTTPRoute は `platform/public-gateway` の HTTPS listener に接続する。
