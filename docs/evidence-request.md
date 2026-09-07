# 追加証跡の最小セット

READMEの「確認待ち」を更新するために必要な出力だけを集めます。画面全体や設定バックアップは不要です。

## Client→Web

```bash
curl -sS -o /dev/null -w '%{http_code}\n' http://<WEB01_IP>/
```

## web01

```bash
sudo ss -lntp | grep ':80 '
getenforce
getsebool httpd_can_network_connect
curl -sS -o /dev/null -w '%{http_code}\n' http://<APP01_IP>:5000/
```

必要な行だけ残し、`<APP01_IP>`を含む実アドレス、ユーザー名、ホスト名は公開前に置換します。

## app01

```bash
sudo ss -lntp | grep ':5000 '
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:5000/
pg_isready -h <DB01_IP> -p 5432
```

`pg_isready`がない場合は追加インストールを急がず、利用中の方法を確認してから代替します。データベース名・ユーザー名・接続文字列は共有しません。

## db01

```bash
sudo ss -lntp | grep ':5432 '
sudo -u postgres pg_isready
```

PostgreSQLの設定ファイル全体、データ、ダンプは共有しません。

## FortiGate

次の4点が見える箇所だけを、値を伏せたスクリーンショットまたはテキストで用意します。

1. 送信元インターフェースがDMZ側であること
2. 宛先インターフェースがInternal側であること
3. 送信元がweb01、宛先がapp01、サービスがTCP/5000であること
4. NATが無効であること

設定の全量エクスポート、診断ファイル、ライセンス画面は共有しません。

## 受け渡し前の伏せ字

| 元情報 | 置換例 |
|---|---|
| 実IP | `<WEB01_IP>`、`<APP01_IP>`、`<DB01_IP>` |
| 実ホスト名 | `web01`、`app01`、`db01` |
| 個人ユーザー名 | `<USER>` |
| 実ドメイン | `example.invalid` |
| シリアル番号 | `<REDACTED_SERIAL>` |
