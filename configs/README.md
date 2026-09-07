# 公開用設定例

このディレクトリは、非公開ラボメモに残っている設計意図を公開向けに再構成したものです。生の設定エクスポートではありません。

## 収録範囲

- `inventory.example.yml`: 公開用アドレスと役割の一覧
- `fortigate/`: インターフェース、アドレスオブジェクト、Web→Appポリシーの再構成例
- `web01/`: NginxとSELinuxの公開用例
- `app01/`: 現在確認できているFlaskの範囲
- `db01/`: PostgreSQLの確認範囲と起動順序drop-in

## 注意

- アドレスはRFC 5737の文書用アドレスです。
- FortiGateのポリシーID、オブジェクト名は公開用の仮名です。
- Nginx設定は、実機で確認した`proxy_pass`、`Host`、`X-Real-IP`だけを文書用アドレスで再構成しています。実機からのコピーではありません。
- PostgreSQLのsystemd drop-inは検証した3行だけを再構成しています。
- Flaskソース、DB名・ユーザー名・認証情報、PostgreSQL設定ファイル全体は掲載していません。
