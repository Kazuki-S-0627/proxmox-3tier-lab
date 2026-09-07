# 構成図

以下は公開用に再構成した論理構成です。IPアドレスはすべてRFC 5737の文書用アドレスであり、実環境の値ではありません。

```mermaid
flowchart LR
    Client["Client\naccess evidence pending"]
    subgraph PVE[Proxmox VE 9.1.1 host]
        FW["FortiGate VMID 200\nport1: 192.0.2.2/24\nport2: 198.51.100.1/24\nport3: 203.0.113.1/24"]

        subgraph DMZ[DMZ - 198.51.100.0/24]
            Web["web01 · VMID 108\nNginx 1.20.1\nTCP/80"]
        end

        subgraph Internal[Internal - 203.0.113.0/24]
            App["app01 · VMID 109\nFlask 3.1.3\nTCP/5000"]
            DB["db01 · VMID 110\nPostgreSQL 13.23\nTCP/5432"]
        end
    end

    Client -. "HTTP path\nevidence pending" .-> FW
    FW -. "DMZ access\nevidence pending" .-> Web
    Web -->|"TCP/5000 via FortiGate\nallow · NAT disabled · HTTP 200"| App
    App -->|"same Internal segment\nTCP/5432 ready · HTTP 200"| DB
```

## 凡例

- 実線: ラボ内で設定と動作を確認済み
- 破線: 構成上の通信経路だが動作証跡が未収集

Web→AppはFortiGateのDMZ→Internalポリシーを通過します。App→DBは同じInternalセグメント内の通信であり、FortiGateを通過しません。図の3層はアプリケーションロールを表し、セキュリティゾーンはDMZとInternalの2つです。

SVG版は[architecture.svg](architecture.svg)です。
