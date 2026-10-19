# Talos

Talos Kubernetes クラスタの宣言的設定を管理する。

## 方針

- Talos config 生成には `talhelper` を使う
- `talconfig.yaml` は non-secret なクラスタ定義
- `talsecret.sops.yaml` は SOPS で暗号化された Talos secrets
- SOPS age private key は 1Password に保存
- 生成された machine config は `.local/talos/clusterconfig` に出力。commit しない

## 初回セットアップ

### 1. SOPS age key を生成する

```bash
mkdir -p .local/sops/age
age-keygen -o .local/sops/age/keys.txt
```

### 2. public key を `.sops.yaml` に設定する

```bash
grep "public key:" .local/sops/age/keys.txt
```

出力された `age1...` を repo root の `.sops.yaml` の `age:` フィールドに設定する。

### 3. age private key を 1Password に保存する

```bash
op document create .local/sops/age/keys.txt \
  --title "SOPS age key for infra repo" \
  --vault "Personal"
```

### 4. Talos secrets を生成・暗号化する

```bash
task talos:gen-secret
```

生成された `talos/talsecret.sops.yaml` は commit する。

## 初回

```bash
task pull-age-key
task talos:gen-secret
task talos:render
```

生成された `talos/talsecret.sops.yaml` は commit する。

## 他 PC で作業する場合

```bash
task pull-age-key
task talos:render
```

## ノード適用

```bash
NODE=cp-01 BOOT_IP=<maintenance-ip> task talos:apply-initial
```

## Bootstrap

```bash
task talos:bootstrap
task talos:kubeconfig
task talos:status
```

## 構造

```
talos/
  talconfig.yaml          # cluster topology definition
  schematics.yaml         # Talos Factory schematic: iscsi-tools + util-linux-tools
  talsecret.sops.yaml     # encrypted Talos secrets
  cilium-values.yaml      # Cilium Helm values (initial bootstrap only)
  patches/
    cni.yaml              # CNI none + kube-proxy disabled
    addressless-public-vlan.yaml  # disable IPv6 SLAAC on public VLAN interface
    public-gateway-node-label.yaml  # node label for kube-vip scheduling
    storage-node-label.yaml  # node label for storage workloads
  Taskfile.yml            # talos operations (apply-initial, apply, bootstrap, render, upgrade-schematic)
```

## Gateway Workers

wk-01 から wk-04 は public Gateway トラフィックを処理するため、以下が設定されている：
- `eth1`: public VLAN 用 NIC（IP アドレスなし、DHCP 無効）
- kube-vip が `infra.n4mlz.dev/public-gateway=true` label の node で eth1 に Service VIP を付与し ARP で広報する
- public VIP からの reply は `public-egress-routing` DaemonSet が source-based policy route で eth1 に戻す

## Storage Workers

wk-01 から wk-04 は storage workload を処理するため、`node-role.n4mlz.dev/storage=true` label を Talos patch で付与する。
Talos の system extension (iscsi-tools, util-linux-tools) は `schematics.yaml` で定義し、`task talos:upgrade-schematic` で全 node に適用する。

## Talos バージョン更新

`talconfig.yaml` の `talosVersion` が最終目標バージョン。最終目標より古いノードがある場合は、Talos の互換性情報に従って中間バージョンを経由し、各段階を全ノードへ順に適用する。`talosctl` は devcontainer に含まれる `TALOSCTL_VERSION` を使い、Talos サーバーと同じリリース系列に合わせる。

```bash
task talos:upgrade-schematic VERSION=v1.x.y
```

各段階で control plane を1台ずつ先に更新し、etcd とノードが正常なことを確認してから次の段階へ進む。最後は `talosVersion` と同じ値で実行する。
