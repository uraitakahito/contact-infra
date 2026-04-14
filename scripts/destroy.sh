#!/usr/bin/env bash
set -euo pipefail

# どこから実行してもリポジトリルートで動作するようにする
cd "$(dirname "$0")/.."

ENV="${1:?Usage: $0 <environment> (dev|prod)}"
NAMESPACE="${NAMESPACE:-contact}"

[[ -d "environments/${ENV}" ]] || { echo "Error: Unknown environment '${ENV}'" >&2; exit 1; }

echo "==> Destroying ${ENV} (namespace: ${NAMESPACE})"

# --no-hooks: OpenFGA の hook Job が uninstall 時に ServiceAccount 削除済みで
# 再実行されハングする問題を回避
helmfile -e "${ENV}" destroy --args --no-hooks

# helm uninstall は PVC・Secret を削除しないため明示的に削除
kubectl delete pvc --all -n "${NAMESPACE}"
kubectl delete secret --all -n "${NAMESPACE}"
