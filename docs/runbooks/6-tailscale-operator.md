# Tailscale Kubernetes Operator

## 目的

Flux で Tailscale Kubernetes Operator を管理し、選択した Kubernetes Service を Tailnet から利用できるようにする。

Operator は Talos node network の `10.240.0.0/16` を広報する既存 subnet router の代わりではない。node 管理経路は引き続き subnet router を使う。

## 事前準備

- [ ] Flux と External Secrets Operator が Ready
- [ ] 1Password `Infra` vault に `Tailscale Kubernetes Operator` item を作り、`client_id` と `client_secret` field を登録
- [ ] Tailscale Admin Console で Operator 用 OAuth client を作成
- [ ] OAuth client の write scope を `General/Services`、`Devices/Core`、`Keys/Auth Keys` に限定
- [ ] OAuth client の tag に `tag:k8s-operator` を指定
- [ ] Tailnet policy の `tagOwners` に以下を追加（既存 policy の他の設定は保持する）

```json
{
  "tagOwners": {
    "tag:k8s-operator": [],
    "tag:k8s": ["tag:k8s-operator"]
  }
}
```

Operator は `tag:k8s-operator`、Operator が作成する proxy device は既定で `tag:k8s` を使う。
OAuth client の値は Git に書かず、1Password の item にだけ保存する。

## GitOps 適用

`platform-config` の ExternalSecret が `tailscale/operator-oauth` Secret を作成する。Operator の HelmRelease は他の platform controller と同じ Kustomization で管理し、既定の Secret 名 `operator-oauth` を参照する。HelmRelease は Secret が準備されるまで install remediation により再試行する。
OAuth 値を HelmRelease values に渡さない。

```bash
export KUBECONFIG="$PWD/.local/kubeconfig"

flux reconcile source git flux-system -n flux-system
flux reconcile kustomization platform-controllers -n flux-system --with-source
flux reconcile kustomization platform-config -n flux-system --with-source
```

## 確認

```bash
flux get kustomizations -A
flux get helmreleases -A
kubectl -n tailscale get pods
kubectl -n tailscale get externalsecret tailscale-operator-oauth
```

Tailscale Admin Console の Machines で `tailscale-operator` が `tag:k8s-operator` 付きで登録されたことを確認する。
Secret の値は表示しない。

## アプリ Service を Tailnet に公開

アプリ namespace の Service に `tailscale.com/expose: "true"` を追加する。Operator が生成する proxy pod は privileged container を使い `/dev/net/tun` を作成するため、`tailscale` namespace は Pod Security `privileged` で管理する。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: example
  namespace: example
  annotations:
    tailscale.com/expose: "true"
spec:
  selector:
    app: example
  ports:
    - port: 80
      targetPort: 8080
```

Operator の proxy は Tailnet から Service への ingress を提供する。公開対象の制御は Tailnet policy と Service annotation の両方で管理する。

Cilium を kube-proxy replacement mode で使う場合、Pod namespace 内の socket load balancing を無効にする `socketLB.hostNamespaceOnly: true` が必要。Tailscale proxy が Pod 内で設定する netfilter forwarding rules を ClusterIP 接続が迂回しないようにする。この値は Cilium の bootstrap values と Flux HelmRelease の両方に設定する。

反映後は Cilium の実効状態と ConfigMap の host namespace 設定を確認する。kube-proxy replacement が有効な場合、ConfigMap の `bpf-lb-sock` の値だけでは socket load balancing の実効状態を判定できない。

```bash
kubectl -n kube-system exec ds/cilium -- cilium-dbg status --verbose | grep -A3 KubeProxyReplacement
kubectl -n kube-system get cm cilium-config -o jsonpath='{.data.bpf-lb-sock-hostns-only}{"\n"}'
```

## 関連資料

- [Network Architecture](../architecture/network.md)
- [Install the Tailscale Kubernetes Operator](https://tailscale.com/docs/kubernetes-operator/install-operator)
- [Expose a cluster workload to your tailnet](https://tailscale.com/docs/kubernetes-operator/ingress/expose-workload-to-tailnet-l3)
- [Compatibility for the Tailscale Kubernetes Operator](https://tailscale.com/docs/kubernetes-operator/reference/compatibility)
