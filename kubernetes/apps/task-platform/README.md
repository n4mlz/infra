# Task Platform

Task Platform は `task-platform` namespace で動作し、SQLite database を Longhorn volume に保存する。Web UI は Tailnet の Service port 80、MCP endpoint はアプリ既定の port 3100 で公開する。Tailnet hostname は[共通設定](../../platform/config/app-hostnames.yaml)で管理する。
