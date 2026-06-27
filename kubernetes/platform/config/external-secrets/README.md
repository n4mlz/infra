# External Secrets 設定

このディレクトリは External Secrets Operator が 1Password から値を取得し、Kubernetes Secret を生成するための設定を管理する。

## 構成

| ディレクトリ | 内容 |
|--------------|------|
| `bootstrap` | External Secrets Operator が 1Password を読むための service account token。SOPS で `stringData` のみ暗号化する |
| `stores` | `Infra` vault を参照する `ClusterSecretStore` |
| `externalsecrets` | 1Password item field から Kubernetes Secret の形へ変換する `ExternalSecret` |

## 1Password item

1Password の item title と field label は安定した API として扱う。`.env` 全体を 1Password に置かず、field 単位で値を置き、Kubernetes Secret の形は `ExternalSecret.spec.target.template` で Git 管理する。

| item title | field label | 用途 |
|------------|-------------|------|
| `Cloudflare cert-manager DNS01 token` | `token` | cert-manager DNS01 challenge |
| `Cloudflare external-dns token` | `token` | external-dns の DNS record 管理 |

## 利用可能 namespace

`ClusterSecretStore` は `secrets.n4mlz.dev/onepassword-infra: "true"` label を持つ namespace からのみ利用できる。新しい namespace で 1Password の `Infra` vault を読む必要がある場合は、対象 namespace にこの label を明示的に付ける。

## SOPS bootstrap secret

`bootstrap/op-service-account-token.sops.yaml` は 1Password SDK provider 用 service account token だけを保持する。平文 token を Git に置かない。再生成する場合は `.local/sops/age/keys.txt` を復元してから SOPS で暗号化する。
