# db01

非公開ラボメモから確認できる範囲は次のとおりです。

- 役割: Database層
- データベース: PostgreSQL 13.23
- 待受: 実IPとloopbackのTCP/5432
- 配置: Internal側
- 接続元制御: app01の単一ホストを`/32`で許可し、`scram-sha-256`認証を使用
- 起動順序: `network-online.target`への`Wants`と`After`をdrop-inで追加

drop-in適用後にdb01をVM再起動し、PostgreSQLの手動再起動なしで実IPへのbind、App→DB ready、Nginx経由のHTTP 200まで確認しました。

公開用drop-in: [`postgresql-network-online.example.conf`](postgresql-network-online.example.conf)

データベース名、ユーザー、接続文字列、認証情報、`postgresql.conf`/`pg_hba.conf`全体、未確認のOS情報は掲載していません。
