# app01

非公開ラボメモから確認できる範囲は次のとおりです。

- 役割: Application層
- OS: Rocky Linux 9.8
- アプリケーション: Flask 3.1.3 / Python 3.9.25
- 仮想環境: `/opt/travelapp/venv`
- DBドライバー: psycopg 3.2.13 / psycopg-binary 3.2.13
- 起動確認: `/opt/travelapp`で`./venv/bin/python app.py`を手動実行
- 待受: `0.0.0.0:5000`
- 配置: Internal側
- firewalld: web01の単一ホストからTCP/5000を許可するrich ruleを確認

Flaskのソースコード、DB接続情報、実行ユーザーは掲載していません。今回確認した起動方法は手動実行であり、systemdサービス化やapp01再起動後の自動起動は未検証です。
