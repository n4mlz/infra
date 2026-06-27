# Platform Config

このディレクトリは controllers に依存する設定リソースを管理する。
controllers が提供する CRD を利用するため、`platform-controllers` の reconciliation 完了後に適用される。

## 配置物

| ディレクトリ | 内容 |
|--------------|------|
| external-secrets | External Secrets Operator の設定（ClusterSecretStore, ExternalSecret） |
| clusterissuers | cert-manager ClusterIssuer（DNS01 Cloudflare） |
| gateway | shared public Gateway（HTTPS entrypoint）と wildcard TLS Certificate |
