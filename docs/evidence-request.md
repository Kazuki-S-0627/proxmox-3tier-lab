# 残っている追加証跡

2026-09-07に、Web→Appポリシー、app01の待受とfirewalld、App→DB、PostgreSQLの起動順序修正、db01再起動後のNginx→Flask→PostgreSQLを収集済みです。画面全体や設定バックアップは公開せず、残項目に必要な最小出力だけを集めます。

## Client→Web

未検証です。試験時はMac/PVEホストからラボのDMZ/Internalネットワークへの直接経路がありませんでした。経路を安全に用意した後、次を確認します。

```bash
curl -sS -o /dev/null -w '%{http_code}\n' http://<WEB01_IP>/
```

## web01のSELinuxブール値

SELinuxが`Enforcing`であることは確認済みですが、今回の`getsebool httpd_can_network_connect`は`Error getting active value`となり、現在値を再確認できていません。

```bash
getenforce
getsebool httpd_can_network_connect
```

必要な行だけ残し、ユーザー名とホスト名は公開前に置換します。

## 任意の追加検証

Flaskは今回`./venv/bin/python app.py`で手動起動しました。将来サービス化した場合は、app01再起動後に次を再確認します。

```bash
sudo ss -lntp | grep ':5000 '
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:5000/customers
```

## 受け渡し前の伏せ字

| 元情報 | 置換例 |
|---|---|
| 実IP | `<WEB01_IP>`、`<APP01_IP>`、`<DB01_IP>` |
| 実ホスト名 | `web01`、`app01`、`db01` |
| 個人ユーザー名 | `<USER>` |
| 実ドメイン | `example.invalid` |
| シリアル番号 | `<REDACTED_SERIAL>` |
