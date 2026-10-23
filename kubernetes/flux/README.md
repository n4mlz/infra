# Flux

このディレクトリはクラスタ共通の Flux 同期設定と Flux 自身の installation manifest を管理する。アプリごとの image tracking と `ImageUpdateAutomation` は各 workload のディレクトリに置く。

## Flux controller manifest の生成

`flux-system/gotk-components.yaml` は Flux CLI が生成する。CLI のバージョンは `.devcontainer/Dockerfile` の `FLUX_VERSION` に合わせ、devcontainer 内のリポジトリ root から次を実行する。

```bash
flux install \
  --version=v2.7.2 \
  --components=source-controller,kustomize-controller,helm-controller,notification-controller \
  --components-extra=image-reflector-controller,image-automation-controller \
  --export > kubernetes/flux/flux-system/gotk-components.yaml
```

`--export` は manifest を出力するだけで、クラスタには適用しない。Flux CLI または component 構成を更新した場合は、この README のコマンドも合わせて更新し、生成差分をレビューする。
