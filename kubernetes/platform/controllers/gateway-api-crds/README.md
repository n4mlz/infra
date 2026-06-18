# Gateway API CRD

Gateway API の CRD は Kubernetes 本体にバンドルされておらず、**どの Gateway API controller を使う場合でも別途インストールが必要**である。

このディレクトリは [kubernetes-sigs/gateway-api](https://github.com/kubernetes-sigs/gateway-api) の CRD を vendor したものである。
Cilium 1.19 は Gateway API v1.4.1 をサポート対象としているため、ここでも v1.4.1 に pin する。

| CRD | channel | 用途 |
|-----|---------|------|
| GatewayClass | standard (GA) | Gateway controller の実装を表す |
| Gateway | standard (GA) | L4-L7 ロードバランサの論理定義 |
| HTTPRoute | standard (GA) | HTTP リクエストのルーティング |
| ReferenceGrant | standard (beta) | クロス namespace 参照の許可 |
| GRPCRoute | standard (GA) | gRPC ルーティング |
| TLSRoute | experimental | TLS パススルールーティング |

TLSRoute は Cilium 1.19 が参照する `gateway.networking.k8s.io/v1alpha2` を serve する必要がある。
Gateway API v1.5.1 の TLSRoute CRD は `v1alpha2` を serve しないため、Cilium 1.19 と組み合わせない。
`Taskfile.yml` は standard CRD と experimental TLSRoute CRD の取得元を分けている。

## 更新手順

```bash
task gateway-api-crds:update
```

`kubernetes/platform/controllers/gateway-api-crds/Taskfile.yml` 内の `GATEWAY_API_VERSION` を変更してから実行することでバージョンアップが可能。
Cilium のサポートする Gateway API version と TLSRoute の served version を確認してから変更する。
