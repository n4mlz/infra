# public-egress-routing

public Service VIP からの reply を public VLAN 側へ返すための node-local policy routing。

## 背景

wk-01 / wk-02 の eth1 は node 用 IP アドレスを持たない。
kube-vip は Service VIP だけを leader node の eth1 に付与する。

Linux の通常 route は destination-based であり、`src=<Service VIP>` の reply も main table の default route に従う。
この環境では main table の default route は management 側 eth0 なので、そのままでは public client への reply が eth0 に出て timeout する。

## 暗黙的依存

- kube-vip-cloud-provider の `range-global` は `163.220.236.73-163.220.236.76`
- kube-vip は Service VIP を eth1 に付与する
- public VLAN の gateway は `163.220.237.254`
- public VLAN の VLAN ID は `2033`

## 設定内容

- table `2033`: `default via 163.220.237.254 dev eth1 onlink`
- rule priority `2033`: `from 163.220.236.73/32` ~ `163.220.236.76/32` を table `2033` に流す

通常の node egress は main table の eth0 default route を使う。
Service VIP を source にする reply だけ eth1 へ戻す。
