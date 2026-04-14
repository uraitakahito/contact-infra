# prod 環境デプロイ手順

## 前提条件

- Kubernetes クラスタ
- Helm v3+
- Helmfile v1.4+
- kubectl

## 1. Namespace 作成

```bash
kubectl create namespace contact
```

## 2. Secret 作成

デプロイ前に 4 つの Secret を `contact` namespace に作成する。

initdb スクリプト (OpenFGA 用 DB 作成) は Helm values で管理しているため、Secret としての作成は不要。

以下の例ではパスワードをプレースホルダーにしている。実際の値に置き換えること。

```bash
POSTGRES_PASSWORD='<postgres admin password>'
CONTACT_API_PASSWORD='<contact_api_prod user password>'
OPENFGA_PASSWORD='<openfga user password>'
```

### postgresql-credentials

PostgreSQL の管理者パスワードと contact_api_prod ユーザーのパスワード。

| Key | Description |
|-----|-------------|
| `postgres-password` | postgres ユーザー (管理者) のパスワード |
| `contact-api-password` | contact_api_prod ユーザーのパスワード |

```bash
kubectl create secret generic postgresql-credentials \
  -n contact \
  --from-literal=postgres-password="${POSTGRES_PASSWORD}" \
  --from-literal=contact-api-password="${CONTACT_API_PASSWORD}"
```

### openfga-db-credentials

OpenFGA 用 PostgreSQL ユーザーのパスワード。initdb スクリプトが環境変数として参照する。

| Key | Description |
|-----|-------------|
| `OPENFGA_DB_PASSWORD` | openfga ユーザーのパスワード |

```bash
kubectl create secret generic openfga-db-credentials \
  -n contact \
  --from-literal=OPENFGA_DB_PASSWORD="${OPENFGA_PASSWORD}"
```

### openfga-datastore-credentials

OpenFGA が PostgreSQL に接続するための URI。

| Key | Description |
|-----|-------------|
| `uri` | PostgreSQL 接続文字列 |

```bash
kubectl create secret generic openfga-datastore-credentials \
  -n contact \
  --from-literal=uri="postgres://openfga:${OPENFGA_PASSWORD}@postgresql:5432/openfga?sslmode=disable"
```

### contact-api-db-credentials

contact-api が PostgreSQL に接続するためのパスワード。

| Key | Description |
|-----|-------------|
| `CONTACT_API_DB_PASSWORD` | contact_api_prod ユーザーのパスワード |

```bash
kubectl create secret generic contact-api-db-credentials \
  -n contact \
  --from-literal=CONTACT_API_DB_PASSWORD="${CONTACT_API_PASSWORD}"
```

## 3. デプロイ

```bash
helmfile -e prod sync
```

## 4. 確認

```bash
# Pod の状態確認
kubectl get pods -n contact

# contact-api のヘルスチェック
export API_URL="http://$(kubectl get svc contact-api -n contact -o jsonpath='{.spec.clusterIP}')"
curl -s "$API_URL/health/ready" | jq
```

## 5. 環境削除

```bash
helmfile -e prod destroy --args --no-hooks
```

> **Note:** `--args --no-hooks` は、OpenFGA チャートの hook Job が uninstall 時に
> ServiceAccount 削除済みの状態で再実行されハングする問題を回避するために必要。
>
> `helm uninstall` は PVC を削除しない。データを含めて完全に削除する場合は
> PVC を手動で削除する:
>
> ```bash
> kubectl delete pvc --all -n contact
> ```
