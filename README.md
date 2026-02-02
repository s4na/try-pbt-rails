# try-pbt-rails

RailsでProperty-Based Testing (PBT) を実践するためのサンプルプロジェクト。

## Property-Based Testing とは

従来のテストでは具体的な入力値を指定してテストを書きますが、PBTでは「プロパティ（性質）」を定義し、ランダムに生成された多数の入力に対してその性質が成り立つかを検証します。

**従来のテスト:**
```ruby
test "reverse twice" do
  assert_equal "hello", "hello".reverse.reverse
  assert_equal "world", "world".reverse.reverse
end
```

**Property-Based Testing:**
```ruby
test "reverse twice returns original string" do
  100.times do
    s = Rantly { string }
    assert_equal s, s.reverse.reverse  # 任意の文字列で成り立つ
  end
end
```

## このプロジェクトで学べること

- Rails アプリケーションへの PBT の導入方法
- [rantly](https://github.com/rantly-rb/rantly) gem の使い方
- Model テストでの PBT の活用
- 従来のテスト（Unit/Integration）と PBT の組み合わせ

## プロジェクト構成

シンプルなブログアプリケーション:
- **User**: ユーザー登録・認証
- **Post**: ブログ記事の CRUD
- **Comment**: 記事へのコメント

## テストの種類

### 1. Model テスト (`test/models/`)
バリデーションや関連付けの基本テスト

### 2. Integration テスト (`test/integration/`)
認証・認可を含むフローのテスト

### 3. Property-Based テスト (`test/property/`)
rantly を使った性質ベースのテスト

```ruby
# 例: タイトルが255文字以内なら有効
test "post title within 255 chars is valid" do
  50.times do
    title_length = Rantly { range(1, 255) }
    title = "a" * title_length
    post = @user.posts.build(title: title, body: "Test")
    assert post.valid?
  end
end
```

## セットアップ

```bash
# Docker で起動
docker compose up -d

# テスト実行
docker compose exec app bundle exec rails test
```

## PBT のポイント

### いつ PBT を使うか
- 入力の範囲が広い場合（文字列、数値、配列など）
- 数学的な性質がある場合（可換性、結合性など）
- エッジケースを網羅したい場合

### PBT で見つかりやすいバグ
- 境界値の処理ミス
- 特殊文字の処理漏れ
- 空入力や極端に長い入力の処理

## 参考リンク

- [rantly](https://github.com/rantly-rb/rantly) - Ruby の PBT ライブラリ
- [PropEr](https://proper-testing.github.io/) - Erlang の PBT（概念の参考に）
- [QuickCheck](https://hackage.haskell.org/package/QuickCheck) - Haskell の元祖 PBT
