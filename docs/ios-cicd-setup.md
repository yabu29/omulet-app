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

### 3. fastlane matchのセットアップ（証明書とプロビジョニングプロファイルの管理）

このプロジェクトでは、`fastlane match`を使用して証明書とプロビジョニングプロファイルを管理します。

#### 3.1. 証明書用のGitリポジトリの作成

1. GitHubで新しい**プライベートリポジトリ**を作成（例: `omulet-app-certificates`）
2. このリポジトリは証明書とプロビジョニングプロファイルを暗号化して保存するために使用します

#### 3.2. Matchfileの設定

`ios/fastlane/Matchfile`が既に作成されています。証明書用のGitリポジトリURLを確認・更新してください：

```ruby
git_url("https://github.com/yabu29/omulet-app-certificates.git")  # あなたのリポジトリURLに変更
```

#### 3.3. ローカルで証明書とプロビジョニングプロファイルを生成

初回のみ、ローカルで以下のコマンドを実行して証明書とプロビジョニングプロファイルを生成します：

```bash
cd ios
bundle exec fastlane match appstore
```

このコマンドで：
- Apple Developer Portalに証明書とプロビジョニングプロファイルが作成されます
- 指定したGitリポジトリに暗号化して保存されます
- 暗号化パスワードの入力が求められます（後でGitHub Secretsに設定します）

**重要**: 暗号化パスワードは安全に保管してください。CI/CDで使用します。

#### 3.4. GitHub Secretsの追加設定

GitHubリポジトリの Settings > Secrets and variables > Actions で以下を追加：

- `MATCH_PASSWORD`: matchで使用する暗号化パスワード（上記で設定したパスワード）
- `APP_STORE_CONNECT_ISSUER_ID`: App Store Connect API KeyのIssuer ID（既に設定済みの場合は確認のみ）

### 4. fastlaneのAppfile設定

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

### 署名エラー（No profiles for 'com.leo.omuee' were found）

このエラーは、CI環境で証明書とプロビジョニングプロファイルが見つからない場合に発生します。

**解決方法**:

1. **matchのセットアップが完了しているか確認**
   - ローカルで`bundle exec fastlane match appstore`を実行して証明書を生成済みか確認
   - 証明書用のGitリポジトリが正しく設定されているか確認

2. **GitHub Secretsの確認**
   - `MATCH_PASSWORD`が正しく設定されているか確認
   - `APP_STORE_CONNECT_API_KEY_CONTENT`、`APP_STORE_CONNECT_KEY_ID`、`APP_STORE_CONNECT_ISSUER_ID`が設定されているか確認

3. **Matchfileの確認**
   - `ios/fastlane/Matchfile`の`git_url`が正しいリポジトリを指しているか確認
   - リポジトリがプライベートで、アクセス可能か確認

4. **証明書用リポジトリへのアクセス**
   - CI環境から証明書用リポジトリにアクセスできるか確認
   - 必要に応じて、Deploy KeyまたはPersonal Access Tokenを設定
