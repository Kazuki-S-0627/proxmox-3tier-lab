# App→DB（TCP/5432）の切り分け

## 発生した障害

2026-09-07、Flaskを起動してTCP/5000の接続拒否を解消した後も、`/customers`がHTTP 500を返しました。app01のログはPostgreSQLへの接続エラーを示していました。

- app01→db01のICMP: 5/5応答
- app01からdb01:5432への`pg_isready`: `no response`
- db01のPostgreSQLサービス: active
- db01ローカルの`pg_isready`: `accepting connections`
- db01の実待受: `127.0.0.1:5432`と`[::1]:5432`だけ

app01とdb01は同じInternalセグメントにいるため、このApp→DB通信はFortiGateを通過しません。L3到達性、DBサービス状態、実待受アドレスを分けて確認しました。

## 設定とログの証拠

- `SHOW listen_addresses;`: `localhost,<DB01_IP>`
- `SHOW config_file;`: `/var/lib/pgsql/data/postgresql.conf`
- `SHOW hba_file;`: `/var/lib/pgsql/data/pg_hba.conf`
- `pg_hba.conf`: `host <DB_NAME> <APP_DB_USER> <APP01_IP>/32 scram-sha-256`に相当するルール
- PostgreSQLログ: `could not bind IPv4 address "<DB01_IP>": Cannot assign requested address`
- PostgreSQL開始: 18:34:37 JST
- `network-online.target`到達: 18:34:55 JST（18秒後）
- stockのPostgreSQL unit: `After=network.target`のみ
- `network-online.target`: `NetworkManager-wait-online.service`に依存

設定上は実IPを待受対象に含めている一方、起動時にそのIPへbindできず、実際にはloopbackだけで稼働していました。時刻関係とエラーログから、ネットワーク準備前のPostgreSQL起動が主因と強く整合しました。

## 診断用の一度だけの再起動

ユーザー承認のもと、IPが利用可能な状態で`systemctl restart postgresql`を一度だけ実行しました。設定ファイルやunitはこの時点では変更していません。

再起動後は`<DB01_IP>:5432`、`127.0.0.1:5432`、`[::1]:5432`で待受し、app01の`pg_isready`が`accepting connections`になりました。続けて、app01ローカルの`/customers`、web01→app01直接、Nginx経由のすべてでHTTP 200と同じ3件のJSONを確認しました。この結果は起動順序仮説を強く支持しました。

## 恒久対策

PostgreSQLを`network-online.target`の後に起動するsystemd drop-inを追加しました。

```ini
[Unit]
Wants=network-online.target
After=network-online.target
```

`systemctl show postgresql -p After -p Wants`を実行し、`After`と`Wants`の両方に`network-online.target`が含まれることを確認しました。公開用ファイルは[`configs/db01/postgresql-network-online.example.conf`](../configs/db01/postgresql-network-online.example.conf)です。

## VM再起動による検証

db01をVM再起動し、その後はPostgreSQLを手動再起動せずに確認しました。

1. db01: `<DB01_IP>:5432`、`127.0.0.1:5432`、`[::1]:5432`でLISTEN
2. app01: db01:5432への`pg_isready`が`accepting connections`
3. app01: `http://127.0.0.1:5000/customers`がHTTP 200、3件のJSON
4. web01: Nginx経由`http://127.0.0.1/customers`がHTTP 200、`Server: nginx/1.20.1`、同じ3件のJSON

一度だけのサービス再起動で復旧したことに加え、drop-in適用後のVM再起動でも手動介入なしに実IPへbindし、3層のHTTP処理まで成功しました。この再現と反証試験により、起動順序不足によるbind失敗への恒久対策が有効と判断しました。

## 切り分け順

1. db01でPostgreSQLがTCP/5432を待ち受けているか確認する
2. db01自身でPostgreSQLのready状態を確認する
3. app01からdb01のTCP/5432へ到達できるか確認する
4. DBの待受アドレスと接続元制御を確認する
5. OS側ファイアウォールと経路を確認する
6. 必要な場合だけFortiGateを通過する構成か、実際のL2/L3経路を確認する

## コマンド例

db01:

```bash
sudo ss -lntp | grep ':5432 '
sudo -u postgres pg_isready
```

app01:

```bash
pg_isready -h <DB01_IP> -p 5432
```

## 注意点

- 接続文字列、DBユーザー名、パスワードをコマンドラインやスクリーンショットに出さない
- `pg_hba.conf`を公開するときは実ネットワーク、ユーザー、DB名を置換する
- 同一セグメントならFortiGateポリシーを通過しない場合があるため、通信経路を先に確認する
- 接続成功とSQL処理成功は別々に記録する
- `active (running)`だけで外部向けアドレスへのLISTEN成功とは判断しない
- 本検証のVM再起動対象はdb01のみ。Flaskは既存venvから手動起動済みで、全サービスの自動起動検証ではない
