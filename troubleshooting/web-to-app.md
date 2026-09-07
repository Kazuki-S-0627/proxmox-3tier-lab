# Web→App（TCP/5000）の切り分け

## 症状

2026-09-07、実際に次の状態を確認しました。

- web01からapp01:5000の`/customers`へ接続すると`Connection refused`
- web01のNginx経由`/customers`はHTTP 502 Bad Gateway
- app01自身の`127.0.0.1:5000/customers`も`Connection refused`
- app01のTCP/5000に待受プロセスがなかった
- app01のfirewalldには、web01の単一ホストからTCP/5000を許可するrich ruleが存在した

この組み合わせから、最初の502はFortiGateポリシー不足ではなく、app01でFlaskが待ち受けていない状態と整合しました。

## 診断と復旧

1. `/opt/travelapp/app.py`と`/opt/travelapp/venv/`の存在を確認
2. 最初の起動試行は`/venv/bin/python`という誤った絶対パスを使い、exit 127で終了
3. `/opt/travelapp`で`./venv/bin/python app.py`を実行
4. Python/Flaskが`0.0.0.0:5000`で待受することを確認
5. web01からapp01:5000へHTTP応答が返るところまで復旧

ただし、Flask起動直後の`/customers`はapp01ローカル、web01→app01直接、Nginx経由のいずれもHTTP 500でした。これは接続拒否/502とは別の段階で、TCP/5000の到達後にFlaskが返したエラーです。後続の調査によりPostgreSQL接続失敗に起因することを確認しました。DB復旧後はweb01→app01直接とNginx経由の両方でHTTP 200と3件のJSONが返りました。

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

実ラボのNginx設定で確認した上流指定はapp01:5000への`proxy_pass`と、`Host`、`X-Real-IP`ヘッダーです。公開用の再構成例は[`configs/web01/nginx-reverse-proxy.example.conf`](../configs/web01/nginx-reverse-proxy.example.conf)にあります。過去の設定確認では`nginx -t`に成功しています。

## 判定の考え方

| 結果 | 次に疑う箇所 |
|---|---|
| app01自身から接続不可 | Flaskの起動状態、待受アドレス、アプリログ |
| app01自身は成功、web01から失敗 | FortiGateポリシー、経路、app01側ホストファイアウォール |
| web01からFlaskへ成功、Nginx経由で失敗 | Nginx upstream、SELinux、Nginxログ |
| Flaskが応答するがHTTP 500 | Flaskのアプリログ、DB接続、SQL処理。TCP/5000の疎通障害と分ける |
| 設定は正しいが断続的に失敗 | タイムアウト、プロセス状態、時刻を合わせた両端ログ |

## 正常動作確認

- web01→app01:5000 `/customers`: HTTP 200
- web01のNginx→app01→db01 `/customers`: HTTP 200、`Server: nginx/1.20.1`
- app01ローカルとNginx経由で同じ3件のJSONを確認

外部Client→web01は別経路であり、この確認には含めていません。

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
