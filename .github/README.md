# GitHub Actions

このディレクトリではリポジトリ共通の GitHub Actions を管理する。

`workflows/flux-image-update-pr.yaml` は `flux-image-updates/**` branch への push で `main` 向けの PR を作成または更新する。PR workflow の成功後に `workflows/flux-image-update-auto-merge.yaml` が squash merge する。GitHub の auto-merge 機能は branch protection rule がない場合に有効化できないため、成功済み workflow から直接 merge する。Flux は service ごとに専用 branch を使い、この prefix を image update 用に予約する。

workflow の `GITHUB_TOKEN` は PR の作成を許可されている。この権限設定は default workflow permissions を `read` のまま保ち、次の `gh` コマンドで再現できる。

```sh
gh api --method PUT repos/{owner}/{repo}/actions/permissions/workflow \
  -F default_workflow_permissions=read \
  -F can_approve_pull_request_reviews=true
```

PR に競合がある場合は GitHub が merge を拒否する。競合を解消して PR workflow が再度成功した後に merge される。
