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
task talos:pull-age-key
task talos:gen-secret
task talos:render
```

生成された `talos/talsecret.sops.yaml` は commit する。

## 他 PC で作業する場合

```bash
task talos:pull-age-key
task talos:render
```

## ノード適用

```bash
NODE=cp-01 BOOT_IP=<maintenance-ip> task talos:apply
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
  talsecret.sops.yaml     # encrypted Talos secrets
  cilium-values.yaml      # Cilium Helm values (initial bootstrap only。Flux 移行後は kubernetes/platform/cilium/helmrelease.yaml が canonical source)
  patches/
    cni.yaml              # CNI none + kube-proxy disabled
  Taskfile.yml            # talos operations
```
