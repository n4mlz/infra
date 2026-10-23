# GitHub Actions

このディレクトリではリポジトリ共通の GitHub Actions を管理する。

`workflows/flux-image-update-pr.yaml` は `flux-image-updates/**` branch への push を受けて、`main` 向けの PR を作成または更新し、auto-merge を要求する。Flux は service ごとに専用 branch を使う。通常の PR はこの workflow の対象外。

GitHub repository の auto-merge は有効。設定する場合は、repository 内から次を実行する。

```sh
gh api --method PATCH repos/{owner}/{repo} -F allow_auto_merge=true
```
