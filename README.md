# contact-infra

[contact-api](https://github.com/uraitakahito/contact-api) を Kubernetes 上で動かすためのインフラ構成リポジトリ。

[Helmfile](https://github.com/helmfile/helmfile) で複数の Helm リリースを宣言的に管理する。

## Architecture

3 つの Helm リリースを依存順に管理:

| Release | Chart | Description |
|---------|-------|-------------|
| postgresql | [bitnami/postgresql](https://github.com/bitnami/charts/tree/main/bitnami/postgresql) (OCI) | contact-api 用と OpenFGA 用の 2 DB を initdb スクリプトで作成 |
| openfga | [openfga/openfga](https://github.com/openfga/helm-charts) (OCI) | 認可サービス。PostgreSQL をデータストアに使用し、マイグレーションを自動実行 |
| contact-api | `./charts/contact-api` (カスタムチャート) | Fastify API サーバー。Helm hook Job で DB マイグレーション・シード・OpenFGA セットアップを実行 |

## Prerequisites

- [Helm](https://helm.sh/) v3+
- [Helmfile](https://github.com/helmfile/helmfile) v1.4+
- Kubernetes クラスタ (OrbStack, minikube, kind 等)
- kubectl

```bash
helm plugin list
helm plugin install --verify=false https://github.com/databus23/helm-diff
helm plugin install --verify=false https://github.com/helm-unittest/helm-unittest
```

## デプロイ手順

### dev

```bash
# 1. Namespace 作成
kubectl create namespace contact

# 2. Secret 作成
kubectl create secret generic postgresql-credentials \
  -n contact \
  --from-literal=postgres-password='dev-postgres-password' \
  --from-literal=contact-api-password='dev-contact-api-password'

kubectl create secret generic postgresql-init-scripts \
  -n contact \
  --from-literal=create-openfga-db.sh='#!/bin/bash
set -e
PGPASSWORD="$(cat /opt/bitnami/postgresql/secrets/postgres-password)" psql -v ON_ERROR_STOP=1 --username postgres <<-EOSQL
  CREATE USER openfga WITH PASSWORD '"'"'dev-openfga-password'"'"';
  CREATE DATABASE openfga OWNER openfga;
EOSQL'

kubectl create secret generic openfga-datastore-credentials \
  -n contact \
  --from-literal=uri='postgres://openfga:dev-openfga-password@postgresql:5432/openfga?sslmode=disable'

kubectl create secret generic contact-api-db-credentials \
  -n contact \
  --from-literal=CONTACT_API_DB_PASSWORD='dev-contact-api-password'

# 3. デプロイ
helmfile -e dev sync

# マニフェストをレンダリングして確認 (dry-run)
helmfile -e dev template

# 依存関係の DAG を確認
helmfile -e dev show-dag

# デプロイ済みとの差分を確認
helmfile -e dev diff

# dev 環境を削除
helmfile -e dev destroy --args --no-hooks
kubectl delete pvc --all -n contact
kubectl delete secret --all -n contact
```

> **Note:** `--args --no-hooks` は、サードパーティチャート (OpenFGA) の hook Job が
> uninstall 時に ServiceAccount 削除済みの状態で再実行されハングする問題を回避するために必要。
> また `helm uninstall` は PVC や Secret を削除しないため、クリーンな再デプロイには
> `kubectl delete pvc` と `kubectl delete secret` で明示的に削除する必要がある。

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
| `postgresql.database` | `contact_api_dev` | データベース名 |
| `postgresql.username` | `contact_api_dev` | データベースユーザー |
| `postgresql.password` | `""` | データベースパスワード |
| `postgresql.existingSecret` | `""` | 既存 Secret 名 (設定時は password より優先) |
| `openfga.apiUrl` | `http://openfga:8080` | OpenFGA API URL |
| `openfga.configFile` | `/shared/openfga-config.json` | OpenFGA 設定ファイルパス |
| `openfgaSetup.enabled` | `true` | OpenFGA セットアップ Job/initContainer の有効化 |
| `migration.enabled` | `true` | DB マイグレーション Job の有効化 |
| `seed.enabled` | `false` | DB シード Job の有効化 |
| `resources` | `{}` | CPU/memory リソース制限 |

## Unit Tests

[helm-unittest](https://github.com/helm-unittest/helm-unittest) でカスタムチャートのテンプレートを検証する。

```bash
helm unittest charts/contact-api
```

## Coding Conventions

values ファイル内の文字列値はすべてダブルクォートで囲む。
[Helm 公式ベストプラクティス](https://helm.sh/docs/chart_best_practices/values/)に従い、
YAML の暗黙的な型変換による事故を防止する。

```yaml
# Good
image:
  repository: "contact-api"
  tag: "latest"
  pullPolicy: "Never"

# Bad
image:
  repository: contact-api
  tag: latest
  pullPolicy: Never
```

整数・ブーリアン・空オブジェクト/配列はクォートしない。

## Documentation

- [prod 環境デプロイ手順](docs/prod-deploy.md) - Secret 作成からデプロイ・確認まで
- [API エンドポイント](docs/api-endpoints.md) - OrbStack 環境での API 操作例

## Related Repositories

- [contact-api](https://github.com/uraitakahito/contact-api) - API アプリケーション本体
