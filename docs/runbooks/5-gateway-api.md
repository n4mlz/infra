# Gateway API and External Ingress Path

## Goal

Cilium Gateway API による外部 HTTPS 入口を完成させる。
L2 Announcement、LB IPAM、Gateway、HTTPRoute、cert-manager TLS、external-dns DNS を GitOps 管理下に置く。

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

### 3. Reconcile

```bash
export KUBECONFIG="$PWD/.local/kubeconfig"

flux reconcile source git flux-system -n flux-system
flux reconcile kustomization flux-system -n flux-system --with-source
flux reconcile kustomization platform-controllers -n flux-system --with-source
flux reconcile kustomization platform-config -n flux-system --with-source
flux reconcile kustomization apps -n flux-system --with-source
```

### 4. 状態確認

```bash
# Cilium Gateway
kubectl get gatewayclass
kubectl -n platform get gateway
kubectl get svc -A | grep public-gateway

# LB IPAM + L2 Announcement
kubectl get ciliumloadbalancerippools.cilium.io
kubectl get ciliuml2announcementpolicies.cilium.io
kubectl -n kube-system get leases | grep cilium

# HTTPRoute
kubectl -n apps get httproute smoke-test

# cert-manager
kubectl -n platform get certificate
kubectl -n platform get certificate wildcard-n4mlz-dev-tls

# external-dns
kubectl -n platform logs deploy/external-dns --tail=50
```

### 5. 接続確認

```bash
# LAN 内から LoadBalancer IP へ直接
curl -v http://163.220.236.73 -H "Host: smoke-test.n4mlz.dev"

# DNS 経由
curl -vk https://smoke-test.n4mlz.dev/
```

## 構成

```
controllers/
  gateway-api-crds/     # Gateway API CRD v1.4.1 (vendor, Cilium 1.19 互換)
  cilium/               # +gatewayAPI +l2announcements
  external-dns/         # +gateway-httproute source

config/
  loadbalancer/
    cilium-lb-ipam.yaml  # CiliumLoadBalancerIPPool (163.220.236.73-76)
    cilium-l2-announcement.yaml  # CiliumL2AnnouncementPolicy (eth1, worker-only)
  gateway/
    certificate.yaml     # shared wildcard TLS Certificate (*.n4mlz.dev, production issuer)
    public-gateway.yaml  # shared HTTPS Gateway (163.220.236.73, *.n4mlz.dev)
```

## トラブルシュート

### Gateway が Accepted/Programmed にならない

- Gateway API CRD がインストールされているか: `kubectl get crd | grep gateway.networking.k8s.io`
- GatewayClass `cilium` が存在するか: `kubectl get gatewayclass`
- Cilium Gateway API が有効か: `helm -n kube-system get values cilium | grep gatewayAPI`
- HTTPS listener が `Programmed=True` にならない場合は、`platform/wildcard-n4mlz-dev-tls` Secret が Certificate から生成されているか確認する
- `cilium-operator` が `TLSRoute v1alpha2` 不在で落ちる場合は、Gateway API CRD が Cilium 1.19 互換の v1.4.1 から生成されているか確認する

### LoadBalancer IP が割り当たらない

- LB IPAM pool が存在するか: `kubectl get ciliumloadbalancerippools`
- Gateway に `lbipam.cilium.io/ips` annotation が正しいか
- Cilium LB IPAM が有効か

### L2 Announcement で ARP 応答がない

- worker に eth1 が存在するか: `talosctl get links --nodes <wk-ip>`
- worker に eth1 が存在するか: `talosctl get links --nodes <wk-ip>`
- `interfaces` が正しいか: `kubectl describe ciliuml2announcementpolicy`
- Lease leader を確認: `kubectl -n kube-system get leases`
