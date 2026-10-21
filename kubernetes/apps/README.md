# アプリケーション設定

Tailnet に公開する Service の hostname は、各アプリのマニフェストへ直接書かず、[共通 hostname 設定](../platform/config/app-hostnames.yaml) に集約する。各アプリの Service annotation や hostname を使う runtime 設定では、Flux の `postBuild.substituteFrom` が読み込む変数を参照する。

この一覧は複数アプリで共有する cluster 固有値であり、個別アプリの設定ではない。また Flux の substitution は workload の apply 前に実行されるため、ConfigMap は `apps` 配下ではなく、先に適用される `platform-config` が管理する。
