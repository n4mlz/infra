# infra

個人的なインフラを IaC と GitOps で管理するリポジトリ。

このリポジトリは public にする前提で、secret は原則として 1Password または SOPS 暗号化ファイルに退避する。
クラスタやアプリケーションの細かい手順は `docs/` と各ディレクトリの `README.md` に分けて記録する。

## 使用技術

| 領域 | 技術 |
|------|------|
| VM provisioning | OpenTofu / Terraform, Proxmox |
| Kubernetes OS | Talos Linux, talhelper |
| GitOps | Flux |
| CNI / Service datapath | Cilium |
| LoadBalancer VIP | kube-vip, kube-vip-cloud-provider |
| Ingress | Gateway API, Istio Gateway |
| TLS / DNS | cert-manager, external-dns, Cloudflare |
| Secret 管理 | 1Password Operator, SOPS age |
| 運用環境 | devcontainer, Taskfile |

## 全体像

```text
terraform/      Proxmox 上の Talos VM skeleton
talos/          Talos cluster topology と machine config 生成
kubernetes/     Flux が同期する Kubernetes desired state
docs/           設計、bootstrap 手順、runbook、security 方針
worklogs/       作業ログ
```

クラスタは Proxmox 上の Talos VM で構成する。
Kubernetes の desired state は Flux が `kubernetes/` 配下から同期する。
外部 HTTPS は kube-vip が public VLAN 上に Service VIP を広告し、Istio Gateway が Gateway API の Route を処理する。

## 主要ディレクトリ

- `terraform/proxmox/`: Talos VM を Proxmox に作成する OpenTofu / Terraform module
- `talos/`: `talconfig.yaml` と patch による Talos machine config 管理
- `kubernetes/flux/`: Flux bootstrap 生成物と Kustomization
- `kubernetes/platform/controllers/`: Cilium, kube-vip, Istio, cert-manager などの controller
- `kubernetes/platform/config/`: controller に依存する cluster-wide config
- `kubernetes/apps/`: application workload
- `docs/`: 人の記憶に依存しないための設計・手順書
- `worklogs/`: 日付ごとの作業記録

代表的な runbook:

- [Proxmox VM Provisioning](docs/runbooks/1-proxmox-vm-provisioning.md)
- [Talos Kubernetes Cluster Bootstrap](docs/runbooks/2-talos-cluster-bootstrap.md)
- [Flux GitOps Bootstrap](docs/runbooks/3-flux-gitops-bootstrap.md)
- [Secrets / TLS / DNS](docs/runbooks/4-secrets-tls-dns.md)
- [Gateway API and External Ingress Path](docs/runbooks/5-gateway-api.md)

## ドキュメント

- [Network Architecture](docs/architecture/network.md)
- [Credential Handling](docs/security/credential-handling.md)
- [Ops Devcontainer](docs/bootstrap/ops-devcontainer.md)
- [Root of Trust](docs/bootstrap/root-of-trust.md)
