# XLAIR website

このディレクトリは `xlair.dev` の stateless workload を管理する。image は `latest` タグと digest で固定し、GHCR の image tracking と Git 更新 automation はこのディレクトリで管理する。site URL、API URL、Auth0 issuer / audience、M2M client ID は ConfigMap で管理する。M2M client secret は `Infra` vault の `XLAIR Website` item から External Secrets Operator が Secret に同期する。

`xlair.dev` は `platform/public-gateway` の HTTPS apex listener に接続する。

自動更新対象の image は `ghcr.io/xlair-dev/xlair.dev`。
