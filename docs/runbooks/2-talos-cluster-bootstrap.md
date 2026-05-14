# Talos Kubernetes Cluster Bootstrap

## Goal

Proxmox 上の VM skeleton を Talos Kubernetes cluster にする。
Cilium が CNI として動き、`kubectl get nodes` で全 node が Ready になる。

## Prerequisites

- [ ] [Tailscale subnet route](../architecture/network.md) が動作している
- [ ] devcontainer が起動している
- [ ] Talos ISO が Proxmox にアップロードされている
- [ ] VM が Terraform で作成済み（停止状態）
- [ ] SOPS age key が 1Password に保存されている

## Procedure

### 1. VM を起動する

```bash
cd terraform/proxmox

export TF_VAR_proxmox_api_token_id="$(op read 'op://Personal/Proxmox/token_id')"
export TF_VAR_proxmox_api_token_secret="$(op read 'op://Personal/Proxmox/secret')"

tofu apply
```

VM が Talos maintenance mode に入るまで数分待つ。

### 2. 疎通確認

Proxmox console で各 VM の DHCP 払い出し IP を確認する。

```bash
export CP1_BOOT_IP="<cp-01 の DHCP IP>"
export CP2_BOOT_IP="<cp-02 の DHCP IP>"
export CP3_BOOT_IP="<cp-03 の DHCP IP>"
export WK1_BOOT_IP="<wk-01 の DHCP IP>"
export WK2_BOOT_IP="<wk-02 の DHCP IP>"
```

```bash
ping -c 2 "$CP1_BOOT_IP"
```

### 3. Disk 名を確認する

```bash
talosctl get disks --insecure --nodes "$CP1_BOOT_IP"
```

出力から install 先の disk を確認（例: `/dev/sda`, `/dev/vda`）。
`talos/talconfig.yaml` の `installDisk` 値と一致しているか確認。

### 4. SOPS age key を復元する

```bash
task talos:pull-age-key
```

### 5. Secrets を生成する

初回のみ実行。

```bash
task talos:gen-secret
```

生成された `talos/talsecret.sops.yaml` は暗号化済みなので commit してよい。

### 6. Config を Render する

```bash
task talos:render
```

`.local/talos/clusterconfig/` にファイルが生成される。

### 7. 各ノードに Config を Apply する

1台ずつ実行する。

```bash
NODE=cp-01 BOOT_IP="$CP1_BOOT_IP" task talos:apply
NODE=cp-02 BOOT_IP="$CP2_BOOT_IP" task talos:apply
NODE=cp-03 BOOT_IP="$CP3_BOOT_IP" task talos:apply
NODE=wk-01 BOOT_IP="$WK1_BOOT_IP" task talos:apply
NODE=wk-02 BOOT_IP="$WK2_BOOT_IP" task talos:apply
```

各ノードが reboot して Talos のインストールが開始される。数分待つ。

### 8. Bootstrap する

**一度だけ** 実行する。

```bash
task talos:bootstrap
```

### 9. Kubeconfig を取得する

```bash
task talos:kubeconfig
```

### 10. Cilium を Install する

```bash
export KUBECONFIG="$PWD/.local/kubeconfig"

helm install cilium oci://quay.io/cilium/charts/cilium \
  --version 1.19.4 \
  --namespace kube-system \
  -f talos/cilium-values.yaml
```

### 11. 確認

```bash
task talos:status
```

全 node が `Ready` になるまで数分待つ。

```bash
kubectl get nodes -w
```

## Smoke Test

```bash
kubectl create namespace smoke-test

kubectl -n smoke-test create deployment nginx \
  --image=nginx:1.27-alpine \
  --replicas=2

kubectl -n smoke-test expose deployment nginx --port=80

kubectl -n smoke-test run curl \
  --image=curlimages/curl:8.10.1 \
  --rm -it --restart=Never \
  -- curl -I http://nginx.smoke-test.svc.cluster.local

kubectl delete namespace smoke-test
```

## 生成ファイル（git に含めない）

| ファイル | 内容 |
|---|---|
| `.local/sops/age/keys.txt` | SOPS age private key |
| `.local/talos/clusterconfig/*.yaml` | ノード固有の machine config |
| `.local/talos/clusterconfig/talosconfig` | talosctl 認証情報 |
| `.local/kubeconfig` | kubectl 認証情報 |

`talos/talsecret.sops.yaml` は暗号化済みなので commit する。
他は再生成可能。

## トラブルシュート

### ノードが IP を取らない

- Tailscale subnet route が動作しているか確認
- Proxmox VM の network bridge が正しいか確認
- Proxmox console で Talos の boot メッセージを確認

### `talosctl bootstrap` が失敗する

- control-plane config が正しく apply されているか
- cp-01 が reboot 中ではないか
- `talosctl health --server=false` で状態確認

### `kubectl get nodes` で NotReady のまま

- CNI が未導入の可能性。Cilium が起動しているか確認
- `kubectl -n kube-system get pods`
- `kubectl -n kube-system logs -l k8s-app=cilium --tail=100`

### Cilium が起動しない

- `k8sServiceHost: localhost`, `k8sServicePort: 7445` が設定されているか（KubePrism）
- `securityContext.capabilities` から `SYS_MODULE` が除外されているか
