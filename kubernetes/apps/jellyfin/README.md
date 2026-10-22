# Jellyfin

Jellyfin は `jellyfin` namespace で動作し、`jellyfin` という Tailnet hostname で公開する。設定とメディアは Longhorn volume に保存し、キャッシュは Pod の寿命に合わせて破棄する。
