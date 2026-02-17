# API Keys 設定

このディレクトリには、APIキーの設定ファイルが含まれています。

## ファイル構成

- `api_keys.dart.template` - テンプレートファイル（リポジトリに含まれる）
- `api_keys.dart` - 実際のAPIキーを含むファイル（`.gitignore`で除外）

## ローカル開発時の設定

1. `api_keys.dart.template`をコピーして`api_keys.dart`を作成：
   ```bash
   cp lib/config/api_keys.dart.template lib/config/api_keys.dart
   ```

2. `api_keys.dart`を開き、`YOUR_YOUTUBE_API_KEY_HERE`を実際のAPIキーに置き換える

## CI/CD時の設定

GitHub ActionsやFastlaneを使用する場合、環境変数`YOUTUBE_API_KEY`を設定すると、自動的に`api_keys.dart`が生成されます。

### GitHub Actions

GitHubリポジトリの Settings > Secrets and variables > Actions で以下を設定：
- `YOUTUBE_API_KEY`: YouTube Data API v3のAPIキー

### Fastlane（ローカル実行時）

```bash
export YOUTUBE_API_KEY="your_api_key_here"
fastlane ios beta
```

## 注意事項

- `api_keys.dart`は`.gitignore`に追加されているため、リポジトリには含まれません
- 実際のAPIキーをリポジトリにコミットしないでください
- Google Cloud ConsoleでAPIキーの制限を設定することを推奨します（Android/iOSアプリ制限）
