# 可観測性コントローラ

このディレクトリは、監視 backend と OpenTelemetry Operator を管理する。
監視基盤全体の設計、telemetry flow、依存関係は [監視アーキテクチャ](../../../../docs/architecture/observability.md) を正とする。

## 配置物

| ファイル | 内容 |
|---|---|
| `helmrepositories.yaml` | Prometheus / Grafana / OpenTelemetry の HelmRepository |
| `kube-prometheus-stack.yaml` | Prometheus / Grafana / Alertmanager |
| `loki.yaml` | log backend |
| `tempo.yaml` | trace backend |
| `opentelemetry-operator.yaml` | OpenTelemetryCollector CR の controller |

## 採用バージョン

| Component | Version |
|---|---|
| kube-prometheus-stack chart | 87.2.1 (app v0.92.0) |
| Loki chart (grafana-community) | 18.1.1 (app 3.7.3) |
| tempo-distributed chart | 1.61.3 (app 2.9.0) |
| opentelemetry-operator chart | 0.117.0 (app 0.153.0) |

## Loki chart

Grafana Loki Helm chart は OSS 利用では grafana-community/helm-charts を使う。
grafana 公式 repo の chart 7.0.0 は GEL (Grafana Enterprise Logs) 向けのため、このディレクトリでは community chart を参照する。
