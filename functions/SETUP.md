# Cloud Functions セットアップ手順

## 1. Firebase CLIの確認

```bash
firebase --version
```

既にインストールされている場合は、バージョンが表示されます。
インストールされていない場合は：

```bash
npm install -g firebase-tools
```

## 2. Firebaseにログイン

```bash
firebase login
```

## 3. Functionsの初期化

```bash
cd /Users/yabuch/development/開発進行中/omulet_app
firebase init functions
```

以下の選択肢を選びます：
- Language: TypeScript または JavaScript
- ESLint: Yes (推奨)
- Install dependencies: Yes

## 4. 必要なパッケージのインストール

```bash
cd functions
npm install googleapis @google-cloud/translate
```

## 5. 環境変数の設定

```bash
firebase functions:config:set youtube.api_key="YOUR_YOUTUBE_API_KEY"
firebase functions:config:set translate.api_key="YOUR_TRANSLATE_API_KEY" # オプション
```

または、`.env`ファイルを使用する場合は：

```bash
# functions/.env
YOUTUBE_API_KEY=YOUR_API_KEY_HERE
GOOGLE_CLOUD_PROJECT=omulet-app
```

## 6. OAuth認証情報の設定（字幕ダウンロード用）

Google Cloud Consoleで：
1. APIとサービス > 認証情報
2. サービスアカウントを作成（または既存のものを使用）
3. サービスアカウントキーをダウンロード（JSON形式）
4. `functions/service-account-key.json`に保存
5. 環境変数を設定：
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="functions/service-account-key.json"
   ```
   または、Cloud Functionsの環境変数として設定：
   ```bash
   firebase functions:config:set google.application_credentials="service-account-key.json"
   ```

**重要**: サービスアカウントに以下の権限が必要です：
- YouTube Data API v3 の使用権限
- Firestore の読み書き権限

## 7. Functionsのビルドとデプロイ

```bash
# TypeScriptをビルド
cd functions
npm run build

# Functionsをデプロイ
cd ..
firebase deploy --only functions
```

## 8. 動作確認

Flutterアプリで動画を検索し、「この動画を教材登録」ボタンを押して、Cloud Functionsが正常に動作するか確認してください。

## 注意事項

- YouTube Data APIの字幕ダウンロードにはOAuth認証が必要です
- サービスアカウントの認証情報を安全に管理してください
- `.gitignore`に`service-account-key.json`を追加してください
