# XLAIR production

このディレクトリは production API、dashboard、PostgreSQL を管理する。PostgreSQL 16 は Longhorn の `longhorn-rwo` PVC にデータを保存する。API は namespace 内の PostgreSQL に接続し、dashboard は `API_BASE_URL` で設定した API endpoint を利用する。

各 workload のイメージは `latest` タグと digest で固定する。GHCR の image tracking と Git 更新 automation はこのディレクトリで管理し、専用 branch に push する。接続先 URL、Auth0 issuer / audience、R2 endpoint と bucket は ConfigMap で管理し、DB 認証情報、R2 access key、dashboard の Auth0 secret は `Infra` vault の `XLAIR Production` item から External Secrets Operator が Secret に同期する。

`api.xlair.dev` と `dash.xlair.dev` は `platform/public-gateway` の HTTPS listener に接続する。

自動更新対象の image は `ghcr.io/xlair-dev/xlair-api` と `ghcr.io/xlair-dev/dashboard`。
