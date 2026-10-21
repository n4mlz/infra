# Gitea

`gitea` namespace で稼働し、HTTP と SSH は Tailnet に公開する。公開名は[共通設定](../../platform/config/app-hostnames.yaml)で管理する。PostgreSQL とアプリケーションデータは Longhorn volume に保存する。
