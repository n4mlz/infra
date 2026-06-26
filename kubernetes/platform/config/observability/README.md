# 可観測性設定

このディレクトリは、監視 backend 上に乗る設定リソースを管理する。
監視基盤全体の設計、telemetry flow、依存関係は [監視アーキテクチャ](../../../../docs/architecture/observability.md) を正とする。

## 配置物

| ファイル | 内容 |
|---|---|
| `collector-rbac.yaml` | OTel Collector が Kubernetes metadata を読むための RBAC |
| `otel-collectors.yaml` | OTel Collector gateway / logs agent |
| `grafana-datasources.yaml` | Grafana datasource |
| `servicemonitors.yaml` | Prometheus scrape target |
| `prometheusrules.yaml` | baseline alert rules |
| `istio-telemetry.yaml` | Istio trace export |

## 局所的な依存

- `collector-rbac.yaml` は `otel-collectors.yaml` の `k8sattributes` processor に必要。
- `istio-telemetry.yaml` は `kubernetes/platform/controllers/istio/istiod.yaml` の `meshConfig.extensionProviders.otel` に依存する。
