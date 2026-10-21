# XLAIR website

このディレクトリは `xlair.dev` の stateless workload を管理する。image は digest で固定し、site URL、API URL、Auth0 issuer / audience、M2M client ID は ConfigMap で管理する。M2M client secret は `Infra` vault の `XLAIR Website` item から External Secrets Operator が Secret に同期する。

`xlair.dev` は `platform/public-gateway` の HTTPS apex listener に接続する。
