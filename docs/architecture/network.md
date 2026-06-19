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
  └── 163.220.236.73-76 (Cilium LoadBalancer IPAM pool)
        ├── .73: shared HTTPS Gateway
        └── .74-76: reserved
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
eth1 には IP アドレスは付与されず、Cilium L2 Announcement が LoadBalancer VIP の ARP/NDP に応答するために使われる。
Cilium L2 Announcement は `nodeSelector` で wk-01/wk-02 だけを lease election の候補にする。

| ノード | eth0 (management) | eth1 (public VLAN) |
|--------|-------------------|-------------------|
| wk-01 | 10.240.30.4/16 | no IP, dhcp:false |
| wk-02 | 10.240.30.5/16 | no IP, dhcp:false |

control-plane（cp-01 ~ cp-03）は public VLAN に接続しない。

## LoadBalancer IP Architecture

```text
external client
  -> Cloudflare DNS (smoke-test.n4mlz.dev -> 163.220.236.73)
  -> upstream router
  -> public VLAN (L2)
  -> Cilium L2 Announcement (worker responds to ARP)
  -> Cilium LoadBalancer Service
  -> Gateway (TLS termination + routing)
  -> HTTPRoute -> Service -> Pod
```

- Cilium LB IPAM: `CiliumLoadBalancerIPPool` が `Service type=LoadBalancer` に public IP を割り当てる
- Cilium L2 Announcement: wk-01/wk-02 が public VLAN 上の LoadBalancer VIP に対して ARP/NDP 代理応答。VIP は node の NIC に実アドレスとして設定されない
- Gateway: `platform` namespace の `public-gateway`。`163.220.236.73` を明示要求（`lbipam.cilium.io/ips`）
- HTTPRoute: アプリ namespace 側で hostname/path を Service に紐づけ

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
