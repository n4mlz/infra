# Platform Config

このディレクトリは controllers に依存する設定リソースを管理する。
controllers が提供する CRD を利用するため、`platform-controllers` の reconciliation 完了後に適用される。

## 配置物

| ディレクトリ | 内容 |
|--------------|------|
| onepassword-items | 1Password → Kubernetes Secret のマッピング（OnePasswordItem） |
| clusterissuers | cert-manager ClusterIssuer（DNS01 Cloudflare） |
| loadbalancer | Cilium LB IPAM pool + L2 Announcement policy |
| gateway | shared public Gateway（HTTPS entrypoint） |
