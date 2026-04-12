# API エンドポイント

OrbStack 環境では、ClusterIP に macOS ホストから直接アクセスできます。

## ベース URL

```bash
# ClusterIP を確認
kubectl get svc contact-api -n contact -o jsonpath='{.spec.clusterIP}'

# 環境変数に設定しておくと便利
export API_URL="http://$(kubectl get svc contact-api -n contact -o jsonpath='{.spec.clusterIP}')"
```

以下の例では `$API_URL` を使用します。

## ヘルスチェック

```bash
# Liveness
curl -s "$API_URL/health/live" | jq

# Readiness
curl -s "$API_URL/health/ready" | jq
```

レスポンス:
```json
{"status":"ok"}
```

## フォームテンプレート一覧取得

```bash
curl -s "$API_URL/form-templates?locale=ja" | jq
```

レスポンス:
```json
{
  "success": 1,
  "data": [
    {
      "id": 1,
      "name": "contact-form",
      "displayName": "問い合わせフォーム",
      "fields": [
        {
          "id": 1,
          "name": "lastName",
          "fieldType": "text",
          "validation": { "type": "none" },
          "isRequired": true,
          "displayOrder": 1,
          "label": "姓",
          "placeholder": "",
          "helpText": "戸籍上の姓を入力してください",
          "options": [],
          "cssClass": "form-control",
          "htmlId": "field-last-name"
        }
      ],
      "createdAt": "2026-04-08T12:00:00.000Z",
      "updatedAt": "2026-04-08T12:00:00.000Z"
    },
    {
      "id": 2,
      "name": "simple-form",
      "displayName": "シンプルフォーム",
      "fields": ["..."],
      "createdAt": "2026-04-08T12:00:00.000Z",
      "updatedAt": "2026-04-08T12:00:00.000Z"
    }
  ]
}
```

※ `fields` は省略しています。実際のレスポンスでは各テンプレートの全フィールドが含まれます。

## フォームテンプレート詳細取得

```bash
curl -s "$API_URL/form-templates/1?locale=ja" | jq
```

レスポンス:
```json
{
  "success": 1,
  "data": {
    "id": 1,
    "name": "contact-form",
    "displayName": "問い合わせフォーム",
    "fields": [
      {
        "id": 1,
        "name": "lastName",
        "fieldType": "text",
        "validation": { "type": "none" },
        "isRequired": true,
        "displayOrder": 1,
        "label": "姓",
        "placeholder": "",
        "helpText": "戸籍上の姓を入力してください",
        "options": [],
        "cssClass": "form-control",
        "htmlId": "field-last-name"
      },
      {
        "id": 2,
        "name": "firstName",
        "fieldType": "text",
        "validation": { "type": "none" },
        "isRequired": true,
        "displayOrder": 2,
        "label": "名",
        "placeholder": "",
        "helpText": "戸籍上の名を入力してください",
        "options": [],
        "cssClass": "form-control",
        "htmlId": "field-first-name"
      },
      {
        "id": 3,
        "name": "email",
        "fieldType": "text",
        "validation": { "type": "email" },
        "isRequired": true,
        "displayOrder": 3,
        "label": "メールアドレス",
        "placeholder": "例: yamada@example.com",
        "helpText": "返信先として使用します",
        "options": [],
        "cssClass": "form-control",
        "htmlId": "field-email"
      },
      {
        "id": 4,
        "name": "phone",
        "fieldType": "text",
        "validation": { "type": "phone" },
        "isRequired": false,
        "displayOrder": 4,
        "label": "電話番号",
        "placeholder": "例: 090-1234-5678",
        "helpText": "日中に連絡可能な番号を入力してください",
        "options": [],
        "cssClass": "form-control",
        "htmlId": "field-phone"
      },
      {
        "id": 5,
        "name": "category",
        "fieldType": "select",
        "validation": { "type": "none" },
        "isRequired": true,
        "displayOrder": 5,
        "label": "お問い合わせ種別",
        "placeholder": "",
        "helpText": "最も近い種別を選択してください",
        "options": [
          { "value": "general", "labels": { "ja": "一般的なお問合せ", "en": "General Inquiry" } },
          { "value": "product", "labels": { "ja": "製品/サービスについて", "en": "Products/Services" } },
          { "value": "recruitment", "labels": { "ja": "採用について", "en": "Recruitment" } },
          { "value": "other", "labels": { "ja": "その他", "en": "Other" } }
        ],
        "cssClass": "form-select",
        "htmlId": "field-category"
      },
      {
        "id": 6,
        "name": "message",
        "fieldType": "textarea",
        "validation": { "type": "none" },
        "isRequired": true,
        "displayOrder": 6,
        "label": "メッセージ",
        "placeholder": "",
        "helpText": "お問い合わせ内容をできるだけ具体的にご記入ください",
        "options": [],
        "cssClass": "form-control form-textarea",
        "htmlId": "field-message"
      }
    ],
    "createdAt": "2026-04-08T12:00:00.000Z",
    "updatedAt": "2026-04-08T12:00:00.000Z"
  }
}
```

## フォームテンプレート作成

```bash
curl -s -X POST "$API_URL/form-templates" \
  -H "Content-Type: application/json" \
  -H "X-User-Id: admin" \
  -d '{"name": "feedback-form", "translations": {"ja": "フィードバック", "en": "Feedback"}, "fields": [{"name": "email", "fieldType": "text", "validationType": "email", "isRequired": true, "displayOrder": 1}, {"name": "message", "fieldType": "textarea", "isRequired": true, "displayOrder": 2}]}' | jq
```

レスポンス (201 Created):
```json
{
  "success": 1,
  "data": {
    "id": 3,
    "name": "feedback-form",
    "displayName": "Feedback",
    "fields": [
      {
        "id": 7,
        "name": "email",
        "fieldType": "text",
        "validation": { "type": "email" },
        "isRequired": true,
        "displayOrder": 1,
        "label": "Email",
        "placeholder": "",
        "helpText": "",
        "options": [],
        "cssClass": "form-control",
        "htmlId": ""
      },
      {
        "id": 8,
        "name": "message",
        "fieldType": "textarea",
        "validation": { "type": "none" },
        "isRequired": true,
        "displayOrder": 2,
        "label": "Message",
        "placeholder": "",
        "helpText": "",
        "options": [],
        "cssClass": "form-control",
        "htmlId": ""
      }
    ],
    "createdAt": "2026-04-08T12:00:00.000Z",
    "updatedAt": "2026-04-08T12:00:00.000Z"
  }
}
```

## 問い合わせ作成

```bash
curl -s -X POST "$API_URL/contacts" \
  -H "Content-Type: application/json" \
  -H "X-User-Id: yamada" \
  -d '{"templateId": 1, "data": {"lastName": "山田", "firstName": "太郎", "email": "yamada@example.com", "phone": "090-1234-5678", "category": "general", "message": "詳細を教えてください"}}' | jq
```

レスポンス:
```json
{
  "success": 1,
  "data": {
    "id": 1,
    "templateId": 1,
    "userId": "yamada",
    "data": {
      "lastName": "山田",
      "firstName": "太郎",
      "email": "yamada@example.com",
      "phone": "090-1234-5678",
      "category": "general",
      "message": "詳細を教えてください"
    },
    "status": "new",
    "createdAt": "2026-04-08T12:00:00.000Z",
    "updatedAt": "2026-04-08T12:00:00.000Z"
  }
}
```

バリデーションエラー時は `?locale=ja` で日本語メッセージを取得できます:

```bash
curl -s -X POST "$API_URL/contacts?locale=ja" \
  -H "Content-Type: application/json" \
  -H "X-User-Id: yamada" \
  -d '{"templateId": 1, "data": {}}' | jq
```

レスポンス:
```json
{
  "success": 0,
  "data": {
    "code": 10003,
    "message": "Form validation failed: lastName:required; firstName:required; email:required; category:required; message:required",
    "details": [
      { "field": "lastName", "code": "required", "message": "姓は必須です" },
      { "field": "firstName", "code": "required", "message": "名は必須です" },
      { "field": "email", "code": "required", "message": "メールアドレスは必須です" },
      { "field": "category", "code": "required", "message": "お問い合わせ種別は必須です" },
      { "field": "message", "code": "required", "message": "メッセージは必須です" }
    ]
  }
}
```

## 問い合わせ一覧取得

```bash
# 全件取得（認可済みのもののみ）
curl -s -H "X-User-Id: yamada" "$API_URL/contacts" | jq

# ステータスでフィルタ
curl -s -H "X-User-Id: yamada" "$API_URL/contacts?status=new" | jq

# テンプレートでフィルタ
curl -s -H "X-User-Id: yamada" "$API_URL/contacts?templateId=1" | jq
```

レスポンス:
```json
{
  "success": 1,
  "data": [
    {
      "id": 1,
      "templateId": 1,
      "userId": "yamada",
      "data": {
        "lastName": "山田",
        "firstName": "太郎",
        "email": "yamada@example.com",
        "phone": "090-1234-5678",
        "category": "general",
        "message": "詳細を教えてください"
      },
      "status": "new",
      "createdAt": "2026-04-08T12:00:00.000Z",
      "updatedAt": "2026-04-08T12:00:00.000Z"
    }
  ]
}
```

## 問い合わせ個別取得

```bash
curl -s -H "X-User-Id: yamada" "$API_URL/contacts/1" | jq
```

レスポンス:
```json
{
  "success": 1,
  "data": {
    "id": 1,
    "templateId": 1,
    "userId": "yamada",
    "data": {
      "lastName": "山田",
      "firstName": "太郎",
      "email": "yamada@example.com",
      "phone": "090-1234-5678",
      "category": "general",
      "message": "詳細を教えてください"
    },
    "status": "new",
    "createdAt": "2026-04-08T12:00:00.000Z",
    "updatedAt": "2026-04-08T12:00:00.000Z"
  }
}
```

## 問い合わせステータス更新

```bash
curl -s -X PATCH "$API_URL/contacts/1/status" \
  -H "Content-Type: application/json" \
  -H "X-User-Id: yamada" \
  -d '{"status": "in_progress"}' | jq
```

レスポンス:
```json
{
  "success": 1,
  "data": {
    "id": 1,
    "templateId": 1,
    "userId": "yamada",
    "data": {
      "lastName": "山田",
      "firstName": "太郎",
      "email": "yamada@example.com",
      "phone": "090-1234-5678",
      "category": "general",
      "message": "詳細を教えてください"
    },
    "status": "in_progress",
    "createdAt": "2026-04-08T12:00:00.000Z",
    "updatedAt": "2026-04-08T12:01:00.000Z"
  }
}
```

## 問い合わせ削除

```bash
curl -s -X DELETE "$API_URL/contacts/1" \
  -H "X-User-Id: yamada" \
  -w "\nHTTP Status: %{http_code}\n"
```

レスポンス:
```json
{
  "success": 1,
  "data": null
}
```
