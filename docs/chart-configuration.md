# contact-api Chart Configuration

`charts/contact-api/values.yaml` で設定可能な値:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `replicaCount` | `1` | Pod レプリカ数 |
| `image.repository` | `contact-api` | Docker イメージリポジトリ |
| `image.tag` | `latest` | Docker イメージタグ |
| `image.pullPolicy` | `Never` | イメージ pull ポリシー |
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
| `seed.enabled` | `false` | DB シード Job の有効化 |
| `resources` | `{}` | CPU/memory リソース制限 |
