# GitHub Actions

このディレクトリではリポジトリ共通の GitHub Actions を管理する。

`workflows/flux-image-update-pr.yaml` は `flux-image-updates/**` branch への push を受けて、`main` 向けの PR を作成または更新し、auto-merge を要求する。Flux は service ごとに専用 branch を使い、この branch prefix を image update 用に予約する。

GitHub repository の auto-merge は有効。workflow の `GITHUB_TOKEN` は PR の作成と承認を許可されている。この権限設定は default workflow permissions を `read` のまま保ち、次の `gh` コマンドで再現できる。

```sh
gh api --method PUT repos/{owner}/{repo}/actions/permissions/workflow \
  -F default_workflow_permissions=read \
  -F can_approve_pull_request_reviews=true

gh api --method PATCH repos/{owner}/{repo} -F allow_auto_merge=true
```
