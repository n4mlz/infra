# XLAIR staging

このディレクトリは staging API、dashboard、PostgreSQL を管理する。PostgreSQL 16 は Longhorn の `longhorn-rwo` PVC にデータを保存する。API は namespace 内の PostgreSQL に接続し、dashboard は `API_BASE_URL` で設定した API endpoint を利用する。

各 workload のイメージは digest で固定する。接続先 URL、Auth0 issuer / audience、R2 endpoint と bucket は ConfigMap で管理し、DB 認証情報、R2 access key、dashboard の Auth0 secret は `Infra` vault の `XLAIR Staging` item から External Secrets Operator が Secret に同期する。

`api.stg.xlair.dev` と `dash.stg.xlair.dev` は `platform/public-gateway` の HTTPS listener に接続する。
