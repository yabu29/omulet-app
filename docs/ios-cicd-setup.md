# iOS CI/CD セットアップガイド

このプロジェクトでは、fastlaneとGitHub Actionsを使用してiOSアプリの自動ビルドと配布を行います。

## 必要な準備

### 1. App Store Connect API Keyの作成

1. [App Store Connect](https://appstoreconnect.apple.com/)にログイン
2. Users and Access > Keys に移動
3. App Store Connect API キーを作成
4. キーID、Issuer ID、.p8ファイルをダウンロード

### 2. GitHub Secretsの設定

GitHubリポジトリの Settings > Secrets and variables > Actions で以下のシークレットを設定：

- `APP_STORE_CONNECT_API_KEY_CONTENT`: App Store Connect API Keyの.p8ファイルの内容（ファイル全体をコピー&ペースト）
- `APP_STORE_CONNECT_KEY_ID`: App Store Connect API KeyのKey ID（例: `ABC123DEF4`）

**設定手順**:

1. App Store Connectでダウンロードした`.p8`ファイルを開く
2. ファイルの内容全体をコピー（`-----BEGIN PRIVATE KEY-----`から`-----END PRIVATE KEY-----`まで）
3. GitHub Secretsの`APP_STORE_CONNECT_API_KEY_CONTENT`にペースト
4. Key IDを`APP_STORE_CONNECT_KEY_ID`に設定

**注意**: `.p8`ファイルは一度しかダウンロードできないため、安全に保管してください。

### 3. fastlaneのAppfile設定

`ios/fastlane/Appfile` を編集して、以下を設定：

- `apple_id`: あなたのApple IDメールアドレス
- `app_identifier`: バンドルID（既に設定済み: `com.leo.omuee`）
- `itc_team_id`: App Store Connect Team ID（既に設定済み: `W92T9A5F6P`）
- `team_id`: Developer Portal Team ID（既に設定済み: `W92T9A5F6P`）

## ローカルでのfastlaneセットアップ

```bash
cd ios
bundle install
```

## 使用方法

### ローカルでビルド

```bash
cd ios
bundle exec fastlane build
```

### ローカルでTestFlightにアップロード

```bash
cd ios
export APP_STORE_CONNECT_API_KEY_PATH=/path/to/AuthKey_XXXXXXXXXX.p8
bundle exec fastlane beta
```

### ローカルでApp Storeにアップロード

```bash
cd ios
export APP_STORE_CONNECT_API_KEY_PATH=/path/to/AuthKey_XXXXXXXXXX.p8
bundle exec fastlane release
```

## GitHub Actionsワークフロー

### 自動実行タイミング

- **devブランチへのpush**: TestFlightに自動アップロード
- **mainブランチへのpush**: TestFlight + App Storeに自動アップロード
- **v*タグのpush**: TestFlight + App Storeに自動アップロード
- **Pull Request**: ビルドのみ実行（アップロードなし）
- **手動実行**: workflow_dispatchで選択可能

### 手動実行

1. GitHubリポジトリの Actions タブに移動
2. "iOS Build and Deploy" ワークフローを選択
3. "Run workflow" をクリック
4. リリースタイプを選択：
   - `build`: ビルドのみ
   - `testflight`: TestFlightにアップロード
   - `appstore`: App Storeにアップロード

## バージョン管理

バージョン番号は`pubspec.yaml`で管理します：

```yaml
version: 1.0.0+1  # バージョン名 + ビルド番号
```

ビルド番号は自動的に3桁のゼロ埋め（001, 002, 003...）として設定されます。

## トラブルシューティング

### fastlaneのエラー

- `bundle install` を実行して依存関係をインストール
- `pod install` を実行してCocoaPodsの依存関係をインストール

### App Store Connect API Keyのエラー

- API Keyの権限を確認（App ManagerまたはAdmin権限が必要）
- Issuer IDとKey IDが正しいか確認
- .p8ファイルのパスが正しいか確認

### ビルドエラー

- Xcodeのバージョンを確認
- Flutterのバージョンを確認（`flutter --version`）
- 証明書とプロビジョニングプロファイルが正しく設定されているか確認
