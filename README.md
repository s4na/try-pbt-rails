# try-pbt-rails

Property-Based Testing (PBT) を Rails で試すプロジェクト

## 開発環境

### 必要なもの

- Docker
- Docker Compose

### 起動方法

```bash
# コンテナをビルドして起動
docker compose up -d

# Railsサーバーにアクセス
# http://localhost:3000

# コンテナ内でコマンド実行
docker compose exec app bundle exec rails console

# テスト実行
docker compose exec app bundle exec rails test

# コンテナ停止
docker compose down
```

## PBT (Property-Based Testing)

このプロジェクトでは [rantly](https://github.com/rantly-rb/rantly) を使って Property-Based Testing を行います。

```ruby
# 例: 文字列を2回reverseすると元に戻る
property_of { string }.check do |s|
  assert_equal s, s.reverse.reverse
end
```
