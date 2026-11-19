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

## platform-config と apps の依存

`apps` は hostname substitution に使う `app-hostnames` ConfigMap が先に作られるよう `platform-config` に依存する。`platform-config` は External Secrets のリソースも適用するが、1Password の可用性を待たない。secret の取得失敗で `platform-config` を NotReady にすると `apps` 全体が止まり、Flux image automation も動作しなくなるため、`platform-config` に `wait: true` を設定しない。

## image update branch

`ImageUpdateAutomation` は `flux-system` GitRepository の `main` を checkout し、workload ごとの branch に push する。`flux-system/kustomization.yaml` は image-automation-controller の `GitAllBranchReferences` を無効化し、既存の更新 branch を `main` と最新の image 更新から作り直す。squash merge 後も古い branch の履歴を引き継いで競合することを防ぐ。この branch は Flux 専用であり、手動の変更を置かない。
