# Network Architecture

## Network Topology

```
Tailscale Tailnet (100.64.0.0/10)
  ├── cosmos (admin host)
  ├── camellia (Proxmox host)
  └── <subnet-router-vm> (Tailscale subnet router)
        └── 10.240.0.0/16 (advertised route)
              └── 10.240.30.0/28 (Talos Kubernetes nodes)
                     ├── cp-01: 10.240.30.1
                     ├── cp-02: 10.240.30.2
                     ├── cp-03: 10.240.30.3
                     ├── wk-01: 10.240.30.4
                     ├── wk-02: 10.240.30.5
                     └── (reserved: .6 ~ .8)

Public VLAN (internet-facing)
  └── VLAN 2033 / 163.220.236.0/23
      └── 163.220.236.73-76 (kube-vip-cloud-provider range-global)
          ├── auto-assigned to LoadBalancer Services
          └── used by: Gateway, future L4 services
```

## Talos Node Network

| 項目 | 値 |
|------|-------|
| サブネット | 10.240.0.0/16 |
| Kubernetes ノード用範囲 | 10.240.30.0/28 |
| デフォルトゲートウェイ | 10.240.255.254 |
| DNS | 8.8.8.8, 1.1.1.1 |

## Gateway Worker

wk-01, wk-02 は public VLAN に接続された 2 枚目の NIC（eth1）を持つ。
eth1 には普段は IP アドレスは付与されないが、kube-vip が leader node の eth1 に LoadBalancer VIP を実際に付与し、ARP で広報する。
kube-vip は `infra.n4mlz.dev/public-gateway=true` label で wk-01/wk-02 だけに scheduling される。

| ノード | eth0 (management) | eth1 (public VLAN) |
|--------|-------------------|-------------------|
| wk-01 | 10.240.30.4/16 | no IP, dhcp:false |
| wk-02 | 10.240.30.5/16 | no IP, dhcp:false |

control-plane（cp-01 ~ cp-03）は public VLAN に接続しない。

eth1 は上流スイッチから VLAN 2033 の tagged frame を受ける。
Cilium の BPF datapath は VLAN tagged frame を既定では filter するため、`bpf.vlanBypass` で VLAN 2033 だけを許可する。
`[0]` による全 VLAN 許可は使わず、public ingress に必要な VLAN だけを IaC で明示する。

## LoadBalancer IP Architecture

```text
external client
  -> Cloudflare DNS (smoke-test.n4mlz.dev -> <EXTERNAL-IP>)
  -> upstream router
  -> public VLAN (L2)
  -> kube-vip (leader node eth1 に VIP を付与 + ARP)
  -> LoadBalancer Service
  -> Istio Gateway Envoy Pod (TLS termination + routing)
  -> HTTPRoute -> Service -> Pod
```

- kube-vip-cloud-provider: `range-global: 163.220.236.73-76` から `Service type=LoadBalancer` に IP を自動割当
- kube-vip: leader node の eth1 に VIP を実際に付与し、ARP で広報する。`svc_election=true` により Service ごとに leader election
- Istio Gateway: Gateway API を解釈し、自動生成された Envoy Deployment + `type: LoadBalancer` Service が L7 ルーティングを行う。Cilium の TPROXY/L7LB 経路に依存しない
- Cilium CNI: `devices: eth+` で kube-proxy replacement (SNAT)。L4 Service datapath のみ担当
- Cilium VLAN bypass: public VLAN 2033 の tagged frame を Cilium BPF datapath で許可する
- Cilium pod rollout: HelmRelease の `rollOutCiliumPods: true` により、`cilium-config` 変更時に agent pod を自動更新する
- Gateway: `platform` namespace の `public-gateway`。IP は kube-vip-cloud-provider が自動割当。gatewayClassName: `istio`
- HTTPRoute: アプリ namespace 側で hostname/path を Service に紐づけ
- kube-vip service security: `enable_service_security=true` で、Service port のみに traffic を制限し、host service の意図しない露出を防止

## Tailscale Subnet Route

Talos ノードは Tailscale Tailnet 上に直接参加していない。
同じ LAN 上の VM を subnet router として設定し、`10.240.0.0/16` を Tailnet に広報している。

Talos は初回 boot 時に DHCP から IP を取得するため、初回 config apply までは
DHCP 払い出しの IP に到達できる必要がある。そのためサブネット全体を広報する。

### Subnet Router の設定

Talos ノードと同じ LAN 上の Linux VM で実行する。

```bash
# 1. IP forwarding を有効化
sudo tee /etc/sysctl.d/99-tailscale.conf >/dev/null <<'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF

sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

# 2. Tailscale でルートを広報（Talos 初回 boot 時は DHCP IP に到達する必要があるためサブネット全体）
sudo tailscale set --advertise-routes=10.240.0.0/16

# 3. Tailscale デーモン再起動
sudo systemctl restart tailscaled
```

### 4. Tailscale Admin Console で Approve

https://login.tailscale.com/admin/machines から該当マシンを選択し、
`10.240.0.0/16` の subnet route を enable にする。

### 5. 動作確認

admin host から:

```bash
ping -c 2 10.240.30.1
talosctl get disks --insecure --nodes 10.240.30.1
```

### トラブルシュート

| 現象 | 原因 | 対応 |
|------|------|------|
| ping が通らない | subnet route が approve されていない | Admin console で確認 |
| ping が通らない | IP forwarding が無効 | `sysctl net.ipv4.ip_forward` を確認 |
| ping が通らない | subnet router VM が offline | `tailscale status` で確認 |
| 一部のノードのみ到達不可 | Talos ノードの network 設定 | Proxmox console で確認 |
