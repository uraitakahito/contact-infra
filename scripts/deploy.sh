#!/usr/bin/env bash
set -euo pipefail

# どこから実行してもリポジトリルートで動作するようにする
cd "$(dirname "$0")/.."

ENV="${1:?Usage: $0 <environment> (dev|prod)}"
NAMESPACE="${NAMESPACE:-contact}"

# 環境ディレクトリの存在チェック
[[ -d "environments/${ENV}" ]] || { echo "Error: Unknown environment '${ENV}'" >&2; exit 1; }

# dev デフォルトパスワード
if [[ "${ENV}" == "dev" ]]; then
  POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-dev-postgres-password}"
  CONTACT_API_PASSWORD="${CONTACT_API_PASSWORD:-dev-contact-api-password}"
  OPENFGA_PASSWORD="${OPENFGA_PASSWORD:-dev-openfga-password}"
fi

# パスワード必須チェック
: "${POSTGRES_PASSWORD:?must be set}"
: "${CONTACT_API_PASSWORD:?must be set}"
: "${OPENFGA_PASSWORD:?must be set}"

echo "==> Deploying to ${ENV} (namespace: ${NAMESPACE})"

# 1. Namespace
# create --dry-run=client で YAML を生成し apply に渡すことで、
# ファイル不要かつ冪等 (既存でもエラーにならない) な作成を実現する。
# 以下の Secret 作成でも同じパターンを使用。
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# 2. Secrets
# パスワード等の機密情報は Secret に格納する (ConfigMap は平文で誰でも読めるため)
kubectl create secret generic postgresql-credentials \
  -n "${NAMESPACE}" \
  --from-literal=postgres-password="${POSTGRES_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

# initdb スクリプトに環境変数として渡す一般ユーザーのパスワード
kubectl create secret generic postgresql-initdb-credentials \
  -n "${NAMESPACE}" \
  --from-literal=CONTACT_API_DB_PASSWORD="${CONTACT_API_PASSWORD}" \
  --from-literal=OPENFGA_DB_PASSWORD="${OPENFGA_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic openfga-datastore-credentials \
  -n "${NAMESPACE}" \
  --from-literal=uri="postgres://openfga:${OPENFGA_PASSWORD}@postgresql:5432/openfga?sslmode=disable" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic contact-api-db-credentials \
  -n "${NAMESPACE}" \
  --from-literal=CONTACT_API_DB_PASSWORD="${CONTACT_API_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

# 3. Deploy
helmfile -e "${ENV}" sync
