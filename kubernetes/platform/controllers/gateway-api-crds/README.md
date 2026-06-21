# Gateway API CRD

Gateway API の CRD は Kubernetes 本体にバンドルされておらず、**どの Gateway API controller を使う場合でも別途インストールが必要**である。

このディレクトリは [kubernetes-sigs/gateway-api](https://github.com/kubernetes-sigs/gateway-api) の標準 CRD を vendor したものである。
Gateway API v1.5.1 (standard channel + TLSRoute experimental) に pin する。

| CRD | channel | 用途 |
|-----|---------|------|
| GatewayClass | standard (GA) | Gateway controller の実装を表す |
| Gateway | standard (GA) | L4-L7 ロードバランサの論理定義 |
| HTTPRoute | standard (GA) | HTTP リクエストのルーティング |
| ReferenceGrant | standard (GA) | クロス namespace 参照の許可 |
| GRPCRoute | standard (GA) | gRPC ルーティング |
| TLSRoute | experimental | TLS パススルールーティング |

## 更新手順

```bash
task gateway-api-crds:update
```

`kubernetes/platform/controllers/gateway-api-crds/Taskfile.yml` 内の `GATEWAY_API_VERSION` を変更してから実行することでバージョンアップが可能。
