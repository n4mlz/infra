# Gitea

`gitea` namespace で稼働し、HTTP と SSH は Tailnet に公開する。公開名は [Flux の apps 設定](../../flux/apps.yaml) で管理する。PostgreSQL とアプリケーションデータは Longhorn volume に保存する。
