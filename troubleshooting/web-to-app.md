# Web→App（TCP/5000）の切り分け

## 症状

web01からapp01のFlaskへ接続できない、またはNginx経由でエラーになる場合を想定します。これは再現可能な切り分け手順であり、実際に発生した障害記録ではありません。

## 切り分け順

1. app01でFlaskがTCP/5000を待ち受けているか確認する
2. app01自身からローカル接続できるか確認する
3. web01からapp01のTCP/5000へ接続できるか確認する
4. FortiGateでDMZ→Internalのポリシー、宛先、サービス、NATを確認する
5. web01のSELinux設定を確認する
6. NginxとFlaskのログを必要な時間帯に絞って確認する

## コマンド例

app01:

```bash
sudo ss -lntp | grep ':5000 '
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:5000/
```

web01:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' http://<APP01_IP>:5000/
getsebool httpd_can_network_connect
sudo nginx -t
```

## 判定の考え方

| 結果 | 次に疑う箇所 |
|---|---|
| app01自身から接続不可 | Flaskの起動状態、待受アドレス、アプリログ |
| app01自身は成功、web01から失敗 | FortiGateポリシー、経路、app01側ホストファイアウォール |
| web01からFlaskへ成功、Nginx経由で失敗 | Nginx upstream、SELinux、Nginxログ |
| 設定は正しいが断続的に失敗 | タイムアウト、プロセス状態、時刻を合わせた両端ログ |

## 記録テンプレート

- 発生条件:
- 影響範囲:
- 直前変更:
- 確認した事実:
- 原因:
- 対処:
- 正常動作確認:
- 再発防止:

公開するときは、実IP、ホスト名、ユーザー名、ログ内の識別子を置換します。
