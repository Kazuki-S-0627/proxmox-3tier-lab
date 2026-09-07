# Proxmox 3-Tier Home Lab

![Sanitized architecture](docs/architecture.svg)

Proxmox VE 上に構築した Web / Application / Database の3層ホームラボを、公開用に再構成したポートフォリオです。これは個人学習・検証環境の記録であり、商用環境での実務経験を示すものではありません。

> [!IMPORTANT]
> このリポジトリにあるIPアドレス、オブジェクト名、設定例は公開用に置換・再構成しています。実環境の生設定やアドレスではありません。

## 目的

- FortiGateを境界にDMZと内部ネットワークを分離する
- Nginx / Flask / PostgreSQLの役割を3台に分ける
- 層間通信を必要な宛先・ポートに限定する考え方を確認する
- 通信経路ごとの切り分け手順を再現可能な形で残す

## 現在の到達点

2026-09-07、ラボ内部の `Nginx (web01) → Flask (app01) → PostgreSQL (db01)` を動作確認しました。PostgreSQLの起動時bind失敗を切り分け、systemdの起動順序を恒久修正した後、**db01をVM再起動し、PostgreSQLを手動再起動せずにApp→DBのready確認とNginx経由のHTTP 200・3件のJSON返却まで再検証済み**です。

これはdb01再起動後のサービスチェーン検証です。app01のFlaskは既存の仮想環境から手動起動しており、全VM・全サービスの自動起動を検証したという意味ではありません。また、外部Client/Mac→web01は試験時にプライベートラボネットワークへの直接経路がなかったため、別項目として未検証です。

## 構成

ハイパーバイザーはProxmox VE 9.1.1です。FortiGateと3台のサーバーVMを同一Proxmoxホスト上に配置しています。

| 配置 | VM / インターフェース | 役割・確認済みバージョン | 公開用アドレス | 待受ポート |
|---|---|---|---|---:|
| Uplink | FortiGate VMID 200 / port1 | 上位ネットワーク接続 | `192.0.2.2/24` | — |
| DMZ | FortiGate VMID 200 / port2 | DMZゲートウェイ | `198.51.100.1/24` | — |
| DMZ | web01 / VMID 108 | Rocky Linux 9.8 / Nginx 1.20.1 | `198.51.100.10/24` | TCP/80 |
| Internal | FortiGate VMID 200 / port3 | 内部ゲートウェイ | `203.0.113.1/24` | — |
| Internal | app01 / VMID 109 | Rocky Linux 9.8 / Flask 3.1.3 / Python 3.9.25 | `203.0.113.10/24` | TCP/5000 |
| Internal | db01 / VMID 110 | PostgreSQL 13.23 | `203.0.113.20/24` | TCP/5432 |

`192.0.2.0/24`、`198.51.100.0/24`、`203.0.113.0/24`はRFC 5737の文書用アドレスです。

ここでいう「3層」はWeb / Application / Databaseの役割分離を指します。ネットワーク上のセキュリティゾーンはDMZとInternalで、app01とdb01は同じInternalセグメントです。そのためApp→DBの制御は、現在の構成ではFortiGateを通過する前提にせず、ホストファイアウォールやPostgreSQLの接続元制御を確認対象にします。

## 設計・設定として確認できていること

- FortiGateのport2をDMZ、port3をInternalとして分離
- FortiGateポリシー`DMZ-to-APP`で、port2→port3、web01→app01、TCP/5000、accept、NAT無効を確認
- app01のfirewalldで、web01だけを送信元とするTCP/5000許可を確認
- web01のNginxはTCP/80、app01のFlaskは`0.0.0.0:5000`、db01のPostgreSQLはTCP/5432で待受を確認
- Nginxの実設定はapp01:5000への`proxy_pass`、`Host`、`X-Real-IP`を使用し、過去の確認で`nginx -t`に成功
- db01の`pg_hba.conf`にapp01の単一ホストだけを許可する`/32`・`scram-sha-256`ルールを確認（公開資料ではDB名・ユーザー名を置換）
- web01のSELinuxは`Enforcing`を確認。一方、今回の`getsebool httpd_can_network_connect`は値を取得できなかったため、当該ブール値の現在値は再確認待ち

## 公開資料の読み方

このリポジトリでは、内容を次の3段階に分けています。

| 表記 | 意味 |
|---|---|
| 記録済み | 非公開のラボメモで設定内容を確認できたもの |
| 公開用再構成 | 記録済みの意図を、文書用アドレスと一般名で書き直した例 |
| 確認待ち | コマンド出力やスクリーンショットが未収集で、成功を断定していないもの |

現時点で、サービス配置、Web→Appの許可ポリシー、NAT無効、app01のホストファイアウォール、App→DB、ラボ内部のNginx→Flask→PostgreSQLは「検証済み」です。Client→Webとweb01のSELinuxブール値の現在値は「確認待ち」です。詳細は[検証マトリクス](docs/validation-matrix.md)に分離して記録しています。

## セキュリティ上の考え方

- Web層だけをDMZに配置し、App / DB層は内部側に配置
- Web→Appは宛先とTCP/5000を限定
- 層間通信で不要なNATを行わず、送信元を識別できる設計
- app01のfirewalldとPostgreSQLの接続元制御でも送信元をweb01/app01の単一ホストに限定
- 公開物には実IP、認証情報、生の設定バックアップ、鍵、証明書を含めない

管理アクセスの制限、ログ設定、TLS化は本リポジトリの検証範囲外です。Web→Appの境界制御は確認済みですが、同一Internalセグメント上のApp→DBはFortiGateを通らず、PostgreSQLの接続元制御を確認しています。

## 障害対応と恒久対策

今回の実測では、次の順で障害を切り分けました。

1. Flask停止中はweb01→app01:5000が`Connection refused`、Nginx経由がHTTP 502
2. `./venv/bin/python app.py`でFlaskを起動し、`0.0.0.0:5000`の待受を確認。ただし`/customers`はDB接続失敗でHTTP 500
3. app01→db01はICMP疎通できる一方、`pg_isready`は`no response`
4. db01のPostgreSQLはactiveでローカルreadyだったが、5432はloopbackだけで待受
5. PostgreSQLログで起動時の`Cannot assign requested address`を確認。PostgreSQL開始は18:34:37 JST、`network-online.target`到達は18:34:55 JSTで18秒後だった
6. 診断用に一度だけPostgreSQLを再起動すると実IPでも待受し、App→DBとHTTP 200が復旧
7. systemd drop-inで`network-online.target`への`Wants`と`After`を追加し、依存関係を確認
8. db01をVM再起動。手動サービス再起動なしで実IPの5432待受、App→DB ready、Flask 200、Nginx 200、同じ3件のJSON返却を確認

再起動による復旧と恒久対策後の再起動試験が一致したため、起動順序不足によるbind失敗を原因として検証済みと判断しました。公開用drop-inは[`configs/db01/postgresql-network-online.example.conf`](configs/db01/postgresql-network-online.example.conf)、詳細な証拠と判断過程は[App→DBの切り分け記録](troubleshooting/app-to-db.md)にあります。

## リポジトリ構成

```text
.
├── README.md
├── LICENSE
├── SECURITY.md
├── configs/
│   ├── README.md
│   ├── inventory.example.yml
│   ├── fortigate/
│   ├── web01/
│   ├── app01/
│   └── db01/
├── docs/
│   ├── architecture.md
│   ├── architecture.svg
│   ├── evidence-request.md
│   ├── publication-checklist.md
│   └── validation-matrix.md
├── scripts/
│   └── prepublish-audit.sh
└── troubleshooting/
    ├── app-to-db.md
    └── web-to-app.md
```

## 確認手順

1. [検証マトリクス](docs/validation-matrix.md)で、記録済みと確認待ちを区別します。
2. [残っている追加証跡](docs/evidence-request.md)の最小コマンドだけを実行します。
3. 出力中のIP、ホスト名、ユーザー名、パスを伏せてから追記します。
4. `./scripts/prepublish-audit.sh`を実行します。
5. [公開前チェックリスト](docs/publication-checklist.md)を目視で確認します。

## トラブルシューティング

- [Web→App（TCP/5000）](troubleshooting/web-to-app.md)
- [App→DB（TCP/5432）](troubleshooting/app-to-db.md)

切り分けは、サービス待受 → ローカル接続 → 経路 → FortiGateポリシー → OS側制御 → アプリケーションログ、の順で実施します。

## 今後の更新候補

- 外部Client→Webの経路を用意し、HTTP応答を検証
- web01の`httpd_can_network_connect`現在値を再確認
- Flaskのサービス化とapp01再起動後の自動起動試験
- 管理用ネットワークと管理元制限を明文化
- HTTPS化と証明書管理方針を追加

## License

MIT License。詳細は[LICENSE](LICENSE)を参照してください。
