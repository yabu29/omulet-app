# Cloud Functions デバッグガイド

## エラー: `[firebase_functions/internal] INTERNAL`

このエラーが発生した場合、以下の手順でデバッグしてください。

## 1. Cloud Functionsのログを確認

```bash
firebase functions:log
```

または、特定の関数のログを確認：

```bash
firebase functions:log --only registerVideoFromSearch
```

## 2. 環境変数の確認

### YouTube API Keyの設定

```bash
# 方法1: functions.config()を使用（非推奨だが動作する）
firebase functions:config:set youtube.api_key="YOUR_API_KEY"

# 方法2: 環境変数を使用（推奨）
# .envファイルを作成
echo "YOUTUBE_API_KEY=YOUR_API_KEY_HERE" > functions/.env
```

### 環境変数の確認

```bash
firebase functions:config:get
```

## 3. OAuth認証情報の確認

字幕ダウンロードにはOAuth認証が必要です。

### サービスアカウントの作成

1. Google Cloud Consoleにアクセス
2. IAM & Admin > Service Accounts
3. サービスアカウントを作成
4. キーをダウンロード（JSON形式）
5. `functions/service-account-key.json`に保存

### 環境変数の設定

```bash
export GOOGLE_APPLICATION_CREDENTIALS="functions/service-account-key.json"
```

または、Cloud Functionsの環境変数として設定：

```bash
# .envファイルに追加
echo "GOOGLE_APPLICATION_CREDENTIALS=service-account-key.json" >> functions/.env
```

## 4. よくあるエラーと解決方法

### エラー: "YouTube API key is not configured"

**解決方法:**
```bash
firebase functions:config:set youtube.api_key="YOUR_API_KEY_HERE"
firebase deploy --only functions
```

### エラー: "Failed to authenticate with YouTube API"

**解決方法:**
- サービスアカウントキーが正しく設定されているか確認
- サービスアカウントにYouTube Data API v3の権限があるか確認

### エラー: "No captions found for this video"

**解決方法:**
- 動画に字幕が存在するか確認
- 公開字幕が有効になっているか確認

## 5. ローカルでのテスト

```bash
# Emulatorを起動
firebase emulators:start --only functions

# 別のターミナルでテスト
curl -X POST http://localhost:5001/omulet-app/us-central1/registerVideoFromSearch \
  -H "Content-Type: application/json" \
  -d '{"data": {"videoId": "IAuI9AYPj_I"}}'
```

## 6. デプロイ後の確認

```bash
# Functionsの一覧を確認
firebase functions:list

# 特定の関数の詳細を確認
firebase functions:describe registerVideoFromSearch
```
