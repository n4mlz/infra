# Gateway API and External Ingress Path

## Goal

kube-vip が LB VIP を eth1 に付与し、Istio Gateway が L7 ルーティングを行う。
Cilium DSR/Geneve が戻り経路の非対称 routing を回避する。
Gateway、HTTPRoute、cert-manager TLS、external-dns DNS を GitOps 管理下に置く。

## Prerequisites

- [ ] Flux SOPS / 1Password Operator / cert-manager / external-dns が導入済み（[4-secrets-tls-dns](4-secrets-tls-dns.md) 完了）
- [ ] public VLAN bridge が設定済み（`terraform/proxmox/terraform.tfvars` の `vm_public_bridge`）
- [ ] Talos config に eth1 が設定済み（`talos/talconfig.yaml`）
- [ ] Cloudflare DNS01 tokens が 1Password に保存済み

## Procedure

### 1. Proxmox で worker に public VLAN NIC を追加

```bash
cd terraform/proxmox

export TF_VAR_proxmox_api_token_id="$(op read 'op://Personal/Proxmox/token_id')"
export TF_VAR_proxmox_api_token_secret="$(op read 'op://Personal/Proxmox/secret')"

# vm_public_bridge を実際の public VLAN bridge に設定してから実行
tofu apply
```

### 2. Talos config を適用

```bash
task pull-age-key
task talos:render

# render 済みの config を worker に適用（順次）
NODE=wk-01 NODE_IP=10.240.30.4 task talos:apply
NODE=wk-02 NODE_IP=10.240.30.5 task talos:apply
```

### 3. Talos config 再適用（node label patch を含む）

`talos/patches/public-gateway-node-label.yaml` に `infra.n4mlz.dev/public-gateway=true` が IaC 化されている。

```bash
task pull-age-key
task talos:render
NODE=wk-01 NODE_IP=10.240.30.4 task talos:apply
NODE=wk-02 NODE_IP=10.240.30.5 task talos:apply
```

### 4. Reconcile

```bash
export KUBECONFIG="$PWD/.local/kubeconfig"

flux reconcile source git flux-system -n flux-system
flux reconcile kustomization flux-system -n flux-system --with-source
flux reconcile kustomization platform-controllers -n flux-system --with-source
flux reconcile kustomization platform-config -n flux-system --with-source
flux reconcile kustomization apps -n flux-system --with-source
```

### 5. 状態確認

```bash
# Istio Gateway
kubectl get gatewayclass
kubectl -n platform get gateway
kubectl get svc -A | grep public-gateway
kubectl -n istio-system get pods

# kube-vip
kubectl -n kube-vip-svc get pods
kubectl -n kube-vip-svc logs ds/kube-vip --tail=20

# Cilium KPR
kubectl -n kube-system exec ds/cilium -- cilium-dbg status --verbose | grep -iE 'kubeproxy|devices'

# HTTPRoute
kubectl -n smoke-test get httproute smoke-test

# cert-manager
kubectl -n platform get certificate
kubectl -n platform get certificate wildcard-n4mlz-dev-tls

# external-dns
kubectl -n platform logs deploy/external-dns --tail=50
```

### 6. 接続確認

```bash
# EXTERNAL-IP 確認
kubectl get svc -A | grep LoadBalancer

# VIP が leader node の eth1 に実際に付いているか確認
talosctl -n 10.240.30.4 get addresses | grep eth1
talosctl -n 10.240.30.5 get addresses | grep eth1

# 外部から HTTP
curl -v http://<EXTERNAL-IP> -H "Host: smoke-test.n4mlz.dev"

# DNS 経由
curl -vk https://smoke-test.n4mlz.dev/
```

## 構成

```text
controllers:
  gateway-api-crds/       # Gateway API CRD v1.5.1 (vendor, Istio 互換)
  cilium/                 # CNI + kubeProxyReplacement (DSR/Geneve, gatewayAPI disabled)
  kube-vip/               # kube-vip DaemonSet (VIP → eth1) + kube-vip-cloud-provider (IPAM)
  istio/                  # Istio base + istiod (Gateway API automated deployment)
  external-dns/           # +gateway-httproute source

config:
  gateway/
    istio-gatewayclass.yaml  # GatewayClass istio (controllerName: istio.io/gateway-controller)
    certificate.yaml         # shared wildcard TLS Certificate (*.n4mlz.dev, production issuer)
    public-gateway.yaml      # shared HTTPS Gateway (gatewayClassName: istio)
```

## kube-vip IP pool

`163.220.236.73-163.220.236.76` を `kube-vip-cloud-provider` の `range-global` で管理。

## トラブルシュート

### Gateway が Accepted/Programmed にならない

- Gateway API CRD がインストールされているか: `kubectl get crd | grep gateway.networking.k8s.io`
- GatewayClass `istio` が存在し Accepted か: `kubectl get gatewayclass istio`
- Istio が Running か: `kubectl -n istio-system get pods`

### LoadBalancer IP が割り当たらない

- kube-vip-cloud-provider が Running か: `kubectl -n kube-vip-svc get pods`
- ConfigMap `kube-vip-cloud-provider` に `range-global` が設定されているか: `kubectl -n kube-vip-svc get cm kube-vip-cloud-provider -o yaml`
- LoadBalancer Service が存在するか: `kubectl get svc -A | grep LoadBalancer`

### kube-vip pod が wk-01/wk-02 で動いていない

- node label が付いているか: `kubectl get nodes --show-labels | grep public-gateway`
- kube-vip HelmRelease の `nodeSelector` が正しいか
- namespace に PSA privileged label があるか: `kubectl get ns kube-vip-svc --show-labels`

### VIP が eth1 に付かない

- kube-vip pod のログを確認: `kubectl -n kube-vip-svc logs ds/kube-vip`
- `vip_interface: eth1` が正しく設定されているか
- eth1 が実際に存在するか: `talosctl get links --nodes <wk-ip>`

### Istio Gateway が Service を作らない

- `PILOT_ENABLE_GATEWAY_API` と `PILOT_ENABLE_GATEWAY_API_DEPLOYMENT_CONTROLLER` が `true` か確認
- istiod のログを確認: `kubectl -n istio-system logs deploy/istiod`
