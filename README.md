# contact-infra

[contact-api](https://github.com/uraitakahito/contact-api) を Kubernetes 上で動かすためのインフラ構成リポジトリ。

[Helmfile](https://github.com/helmfile/helmfile) で複数の Helm リリースを宣言的に管理する。

## Architecture

3 つの Helm リリースを依存順に管理:

```
postgresql (GROUP 1)
    |
    v
openfga (GROUP 2)
    |
    v
contact-api (GROUP 3)
```

| Release | Chart | Description |
|---------|-------|-------------|
| postgresql | [bitnami/postgresql](https://github.com/bitnami/charts/tree/main/bitnami/postgresql) (OCI) | PostgreSQL 17。contact-api 用と OpenFGA 用の 2 DB を initdb スクリプトで作成 |
| openfga | [openfga/openfga](https://github.com/openfga/helm-charts) (OCI) | 認可サービス。PostgreSQL をデータストアに使用し、マイグレーションを自動実行 |
| contact-api | `./charts/contact-api` (カスタムチャート) | Fastify API サーバー。Helm hook Job で DB マイグレーション・シード・OpenFGA セットアップを実行 |

## Prerequisites

- [Helm](https://helm.sh/) v3+
- [Helmfile](https://github.com/helmfile/helmfile) v1.4+
- Kubernetes クラスタ (OrbStack, minikube, kind 等)
- kubectl

```bash
# Helmfile の依存プラグインを初期化
helmfile init
```

## Quick Start

```bash
# 依存関係の DAG を確認
make show-dag

# マニフェストをレンダリングして確認 (dry-run)
make template

# dev 環境にデプロイ
make sync

# デプロイ済みとの差分を確認
make diff

# dev 環境を削除
make destroy
```

## Directory Structure

```
.
├── helmfile.yaml                 # Helmfile メイン定義
├── Makefile                      # 開発者向けショートカット
├── charts/
│   └── contact-api/              # contact-api カスタム Helm チャート
│       ├── Chart.yaml
│       ├── values.yaml           # デフォルト値
│       └── templates/
│           ├── _helpers.tpl
│           ├── configmap.yaml
│           ├── secret.yaml
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── job-migrate.yaml       # DB マイグレーション (hook-weight: 0)
│           ├── job-seed.yaml          # DB シード (hook-weight: 1)
│           └── job-openfga-setup.yaml # OpenFGA ストア/モデル作成 (hook-weight: 1)
└── environments/
    ├── dev/                      # 開発環境
    │   ├── values.yaml
    │   ├── values-postgresql.yaml
    │   ├── values-openfga.yaml
    │   └── values-contact-api.yaml
    └── prod/                     # 本番環境
        ├── values.yaml
        ├── values-postgresql.yaml
        ├── values-openfga.yaml
        └── values-contact-api.yaml
```

## Environments

### dev

- パスワードを values ファイルにインラインで記載
- レプリカ数: 1
- seed Job: 有効
- OpenFGA Playground: 有効

```bash
make sync
```

### prod

[prod 環境デプロイ手順](docs/prod-deploy.md) を参照。

## Startup Sequence

Helmfile の `needs` と Helm hook の `hook-weight` により、以下の順序で起動する:

| Step | Action | Mechanism |
|------|--------|-----------|
| 1 | PostgreSQL 起動 + initdb (2 DB 作成) | Helmfile GROUP 1 |
| 2 | OpenFGA マイグレーション | OpenFGA チャート内蔵 hook Job |
| 3 | OpenFGA サービス起動 | OpenFGA Deployment |
| 4 | contact-api DB マイグレーション | Helm hook Job (weight 0) |
| 5 | contact-api DB シード | Helm hook Job (weight 1) |
| 6 | OpenFGA ストア/モデル作成 | Helm hook Job (weight 1, Step 5 と並列) |
| 7 | OpenFGA 設定ファイル生成 | Deployment initContainer |
| 8 | contact-api サーバー起動 | Deployment main container |

## contact-api Chart Configuration

`charts/contact-api/values.yaml` で設定可能な値:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `replicaCount` | `1` | Pod レプリカ数 |
| `image.repository` | `ghcr.io/uraitakahito/contact-api` | Docker イメージリポジトリ |
| `image.tag` | `latest` | Docker イメージタグ |
| `image.pullPolicy` | `IfNotPresent` | イメージ pull ポリシー |
| `service.type` | `ClusterIP` | Service タイプ |
| `service.port` | `80` | Service ポート |
| `postgresql.host` | `postgresql` | PostgreSQL ホスト名 |
| `postgresql.port` | `5432` | PostgreSQL ポート |
| `postgresql.database` | `contact_api` | データベース名 |
| `postgresql.username` | `contact_api` | データベースユーザー |
| `postgresql.password` | `""` | データベースパスワード |
| `postgresql.existingSecret` | `""` | 既存 Secret 名 (設定時は password より優先) |
| `openfga.apiUrl` | `http://openfga:8080` | OpenFGA API URL |
| `openfga.configFile` | `/shared/openfga-config.json` | OpenFGA 設定ファイルパス |
| `openfgaSetup.enabled` | `true` | OpenFGA セットアップ Job/initContainer の有効化 |
| `migration.enabled` | `true` | DB マイグレーション Job の有効化 |
| `seed.enabled` | `true` | DB シード Job の有効化 |
| `resources` | `{}` | CPU/memory リソース制限 |

## Documentation

- [prod 環境デプロイ手順](docs/prod-deploy.md) - Secret 作成からデプロイ・確認まで
- [API エンドポイント](docs/api-endpoints.md) - OrbStack 環境での API 操作例

## Related Repositories

- [contact-api](https://github.com/uraitakahito/contact-api) - API アプリケーション本体
