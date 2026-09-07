# 検証マトリクス

この表は「設定確認」「実動作」「未検証」を分けます。結果は2026-09-07に非公開ラボで取得し、ここでは秘密情報と実アドレスを除いた要約だけを掲載します。

| ID | 確認対象 | 期待結果 | 現在の根拠 | 状態 |
|---|---|---|---|---|
| V-01 | FortiGateのゾーン分離 | port2がDMZ、port3がInternal | インターフェース設定を確認 | 設定確認済み |
| V-02 | web01のNginx待受 | TCP/80でLISTEN | IPv4/IPv6の80待受を確認 | 検証済み |
| V-03 | app01のFlask待受 | `0.0.0.0:5000`でLISTEN | 正しいvenv Pythonで起動後に待受を確認 | 検証済み（手動起動） |
| V-04 | db01のPostgreSQL待受 | 実IPとloopbackの5432でLISTEN | systemd修正後のdb01再起動直後に確認 | 検証済み |
| V-05 | Web→Appポリシー | web01からapp01のTCP/5000を許可 | `DMZ-to-APP`: port2→port3、送受信元、service、acceptを確認 | 設定確認済み |
| V-06 | Web→AppのNAT | 当該通信でNATを行わない | 同ポリシーのNAT無効を確認 | 設定確認済み |
| V-07 | app01のfirewalld | web01の単一ホストからTCP/5000を許可 | `/32`送信元のrich ruleを確認 | 設定確認済み |
| V-08 | web01のSELinux | Nginxが上流へ接続できる | `Enforcing`は確認。`getsebool`はactive value取得エラー | ブール値再確認待ち |
| V-09 | Client→Web | 外部ClientからHTTP応答を取得できる | Client/PVEホストからラボネットワークへの直接経路なし | 未検証 |
| V-10 | App→DB ready | app01からdb01:5432がready | db01再起動後に`accepting connections` | 検証済み |
| V-11 | Flask→PostgreSQL | `/customers`がDB結果を返す | app01ローカルでHTTP 200、3件のJSON | 検証済み |
| V-12 | Web→App直接 | web01からapp01:5000が応答 | DB復旧後にHTTP 200、同じ3件のJSON | 検証済み |
| V-13 | Nginx→Flask→PostgreSQL | web01のNginx経由でDB結果を返す | db01再起動後、Nginx 1.20.1からHTTP 200、同じ3件のJSON | 検証済み |
| V-14 | PostgreSQL恒久対策 | db01再起動後も手動再起動なしで実IPにbind | `After`/`Wants`確認後、VM再起動とV-04/V-10/V-11/V-13を再試験 | 検証済み |

## 再起動後の確認要約

```text
db01: <DB01_IP>:5432, 127.0.0.1:5432, [::1]:5432 LISTEN
app01: <DB01_IP>:5432 - accepting connections
app01: GET /customers - HTTP/1.1 200 OK
web01: GET /customers via Nginx 1.20.1 - HTTP/1.1 200 OK
response: 3 records (sanitized summary: TOKYO/TANAKA, OSAKA/SATO, FUKUOKA/SUZUKI)
```

この再試験で再起動したのはdb01です。Flaskは`./venv/bin/python app.py`で手動起動済みのプロセスを使用しました。

## 証跡を追加するときのルール

- コマンド全文より、確認に必要な行だけを載せる
- 実IPは`<WEB01_IP>`、`<APP01_IP>`、`<DB01_IP>`などへ置換する
- ユーザー名、ホームディレクトリ、FQDN、MACアドレス、シリアル番号を削除する
- FortiGateのシリアル番号、ライセンス情報、管理者名を削除する
- スクリーンショットはブラウザ全体ではなく対象箇所だけを切り出す
- 「成功」の記載には、実行日、観点、期待結果、実結果を添える
