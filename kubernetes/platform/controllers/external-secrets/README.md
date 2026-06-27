# External Secrets Operator

このディレクトリは External Secrets Operator 本体を HelmRelease として管理する。

External Secrets Operator は 1Password SDK provider を使う。1Password Connect Server は導入しない。provider 用 service account token は `kubernetes/platform/config/external-secrets/bootstrap` の SOPS 暗号化 Secret で管理する。
