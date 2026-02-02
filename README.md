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
- Request テストでの PBT の活用
- 従来のテスト（Unit/Integration）と PBT の組み合わせ

## プロジェクト構成

シンプルなブログアプリケーション:
- **User**: ユーザー登録・認証
- **Post**: ブログ記事の CRUD
- **Comment**: 記事へのコメント

## セットアップ

```bash
# Docker で起動
docker compose up -d

# テスト実行
docker compose exec app bundle exec rails test
```

---

## Model Spec での PBT

Model spec では、バリデーションや関連付けの性質をテストします。

### バリデーションのテスト

特定の値ではなく「性質」でテストを書くことで、より広い範囲をカバーできます。

```ruby
require "test_helper"
require "rantly"

class PostPropertyTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(name: "Test", email: "test@example.com", password: "password123")
  end

  # 性質: タイトルが1〜255文字なら有効
  test "post title within 255 chars is valid" do
    50.times do
      title_length = Rantly { range(1, 255) }
      title = "a" * title_length

      post = @user.posts.build(title: title, body: "Test body")
      assert post.valid?, "Post with title length #{title_length} should be valid"
    end
  end

  # 性質: タイトルが256文字以上なら無効
  test "post title over 255 chars is invalid" do
    20.times do
      title_length = Rantly { range(256, 500) }
      title = "a" * title_length

      post = @user.posts.build(title: title, body: "Test body")
      assert_not post.valid?, "Post with title length #{title_length} should be invalid"
    end
  end
end
```

### 関連付けのテスト

関連付けの不変条件をテストします。

```ruby
# 性質: 投稿を作成すると、ユーザーの投稿数が1増える
test "creating post increases user posts count by 1" do
  20.times do
    title = Rantly { sized(10) { string(:alpha) } }
    title = "Title" if title.empty?
    body = Rantly { sized(50) { string } }
    body = "Body" if body.empty?

    initial_count = @user.posts.count
    @user.posts.create!(title: title, body: body)
    assert_equal initial_count + 1, @user.posts.count
  end
end

# 性質: 投稿を削除すると、関連するコメントも全て削除される
test "deleting post deletes all its comments" do
  10.times do
    post = @user.posts.create!(title: "Test", body: "Body")
    comment_count = Rantly { range(1, 5) }

    comment_count.times do
      post.comments.create!(user: @user, body: "Comment")
    end

    comment_ids = post.comments.pluck(:id)
    post.destroy

    comment_ids.each do |id|
      assert_nil Comment.find_by(id: id), "Comment #{id} should be deleted"
    end
  end
end
```

### パスワードバリデーションのテスト

```ruby
# 性質: パスワードは6文字以上であれば有効
test "password with 6 or more chars is valid" do
  20.times do
    password_length = Rantly { range(6, 20) }
    password = "a" * password_length

    user = User.new(
      name: "Test",
      email: "#{SecureRandom.hex(8)}@example.com",
      password: password
    )
    assert user.valid?, "Password with length #{password_length} should be valid"
  end
end

# 性質: パスワードが5文字以下なら無効
test "password with less than 6 chars is invalid" do
  20.times do
    password_length = Rantly { range(1, 5) }
    password = "a" * password_length

    user = User.new(
      name: "Test",
      email: "#{SecureRandom.hex(8)}@example.com",
      password: password
    )
    assert_not user.valid?, "Password with length #{password_length} should be invalid"
  end
end
```

---

## Request Spec での PBT

Request spec では、API エンドポイントの入力バリデーションや認証・認可をテストします。

### Create エンドポイントのテスト

```ruby
require "test_helper"
require "rantly"

class PostsPbtTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(name: "Test", email: "test@example.com", password: "password123")
  end

  def login_as(user)
    post login_path, params: { email: user.email, password: "password123" }
    follow_redirect!
  end

  # 性質: 有効なタイトル（1-255文字）なら作成成功
  test "create post with valid random titles succeeds" do
    login_as(@user)

    20.times do
      title_length = Rantly { range(1, 255) }
      title = "a" * title_length
      body = "Random body content"

      assert_difference "Post.count", 1, "Title length #{title_length} should be valid" do
        post posts_path, params: { post: { title: title, body: body } }
      end
      assert_redirected_to post_path(Post.last)
    end
  end

  # 性質: 無効なタイトル（256文字以上）なら作成失敗
  test "create post with invalid titles fails" do
    login_as(@user)

    15.times do
      title_length = Rantly { range(256, 500) }
      title = "a" * title_length
      body = "Valid body content"

      assert_no_difference "Post.count", "Title length #{title_length} should be invalid" do
        post posts_path, params: { post: { title: title, body: body } }
      end
      assert_response :unprocessable_entity
    end
  end
end
```

### 認証のテスト

```ruby
# 性質: 未認証ユーザーはどんなデータでも投稿を作成できない
test "unauthenticated user cannot create posts with any data" do
  10.times do
    title = Rantly { sized(20) { string(:alpha) } }
    title = "Random Title" if title.empty?
    body = Rantly { sized(50) { string } }
    body = "Random body" if body.empty?

    assert_no_difference "Post.count" do
      post posts_path, params: { post: { title: title, body: body } }
    end
    assert_redirected_to login_path
  end
end
```

### 認可のテスト

```ruby
# 性質: ユーザーは他人の投稿をどんなデータでも更新できない
test "user cannot update other user's post with any data" do
  other_user = User.create!(name: "Other", email: "other@example.com", password: "password123")
  other_post = other_user.posts.create!(title: "Other's Post", body: "Content")
  original_title = other_post.title

  login_as(@user)

  10.times do
    new_title = Rantly { sized(20) { string(:alpha) } }
    new_title = "Attempted Title" if new_title.empty?

    patch post_path(other_post), params: { post: { title: new_title, body: "Attempted" } }
    
    other_post.reload
    assert_equal original_title, other_post.title, "Other user's post should not be modified"
  end
end
```

### 境界値のテスト

```ruby
# 性質: タイトルが境界値（255文字）なら有効
test "title at exact boundary (255 chars) is valid" do
  login_as(@user)

  5.times do
    title = "a" * 255
    body = "Body content"

    assert_difference "Post.count", 1 do
      post posts_path, params: { post: { title: title, body: body } }
    end
  end
end

# 性質: タイトルが境界値+1（256文字）なら無効
test "title at boundary+1 (256 chars) is invalid" do
  login_as(@user)

  5.times do
    title = "a" * 256
    body = "Body content"

    assert_no_difference "Post.count" do
      post posts_path, params: { post: { title: title, body: body } }
    end
    assert_response :unprocessable_entity
  end
end
```

---

## Rantly の基本的な使い方

```ruby
require "rantly"

# 数値の生成
Rantly { range(1, 100) }          # 1〜100のランダムな整数
Rantly { integer }                 # 任意の整数
Rantly { float }                   # 任意の浮動小数点数

# 文字列の生成
Rantly { string }                  # ランダムな文字列
Rantly { string(:alpha) }          # アルファベットのみ
Rantly { string(:digit) }          # 数字のみ
Rantly { sized(10) { string } }    # 長さを指定

# 配列・選択
Rantly { array(5) { integer } }    # 整数5個の配列
Rantly { choose(1, 2, 3) }         # 1, 2, 3からランダムに選択
Rantly { freq([3, :a], [1, :b]) }  # 重み付き選択（aが75%、bが25%）

# 条件付き生成
Rantly { guard(integer > 0) }      # 正の整数のみ
```

---

## LLM 時代における PBT の価値

### 1. LLM が考えつかないエッジケースを自動で発見

LLM がコードを生成する時代、人間が手動でテストケースを考える必要性は減っています。しかし、LLM も人間も「思いつかない」エッジケースは存在します。

PBT はランダムな入力を大量に生成するため、人間や LLM が想定しなかったケースを自動的に発見できます。

```ruby
# LLM が生成したコードに対して、1000パターンの入力を自動テスト
test "function handles any valid input" do
  1000.times do
    input = Rantly { generate_random_input }
    result = llm_generated_function(input)
    assert valid_output?(result), "Failed for input: #{input}"
  end
end
```

### 2. LLM 生成コードの品質保証

LLM が生成したコードが正しく動作するか確認する際、具体的なテストケースだけでは不十分です。PBT を使えば、生成されたコードが「性質」を満たしているかを網羅的に検証できます。

```ruby
# LLM に「ソート関数」を生成させた後の検証
test "sort function satisfies sorting properties" do
  100.times do
    arr = Rantly { array(20) { integer } }
    sorted = llm_generated_sort(arr)
    
    # 性質1: 長さが変わらない
    assert_equal arr.length, sorted.length
    
    # 性質2: 要素が保存される
    assert_equal arr.sort, sorted.sort
    
    # 性質3: 昇順に並んでいる
    sorted.each_cons(2) { |a, b| assert a <= b }
  end
end
```

### 3. 仕様を「性質」として定義することで LLM への指示が明確に

PBT では仕様を「入力と出力の関係（性質）」として表現します。この考え方は、LLM にコード生成を依頼する際のプロンプトにも活かせます。

**曖昧な指示:**
> 「ユーザー名のバリデーションを実装して」

**性質ベースの明確な指示:**
> 「以下の性質を満たすユーザー名バリデーションを実装して:
> - 空文字列は無効
> - 1〜50文字なら有効
> - 51文字以上は無効
> - 英数字とアンダースコアのみ許可」

性質として仕様を考える習慣は、LLM とのコミュニケーションをより正確にします。

### 4. テスト生成を LLM に任せても網羅性が担保される

LLM にテストを書かせる場合でも、「PBT で書いて」と指示することで、LLM が思いつく具体例に依存せず、網羅的なテストが得られます。

```ruby
# LLM に「このバリデーションのテストを書いて」と依頼

# 従来のテスト（LLM が考えた具体例のみ）
test "validates title" do
  assert Post.new(title: "Hello").valid?
  assert_not Post.new(title: "").valid?
  assert_not Post.new(title: "a" * 256).valid?
end

# PBT（網羅的）
test "validates title length property" do
  100.times do
    length = Rantly { range(0, 300) }
    title = "a" * length
    post = Post.new(title: title, body: "body")
    
    if length.between?(1, 255)
      assert post.valid?, "Title with #{length} chars should be valid"
    else
      assert_not post.valid?, "Title with #{length} chars should be invalid"
    end
  end
end
```

### まとめ: LLM × PBT のシナジー

| 課題 | PBT での解決 |
|------|-------------|
| LLM が全てのエッジケースを考慮できない | ランダム入力で自動発見 |
| LLM 生成コードの信頼性 | 性質ベースで網羅検証 |
| LLM への仕様伝達が曖昧 | 性質として明確に定義 |
| LLM 生成テストの網羅性 | PBT 形式で生成させる |

---

## PBT のポイント

### いつ PBT を使うか
- 入力の範囲が広い場合（文字列、数値、配列など）
- 数学的な性質がある場合（可換性、結合性など）
- エッジケースを網羅したい場合
- LLM 生成コードを検証する場合

### PBT で見つかりやすいバグ
- 境界値の処理ミス
- 特殊文字の処理漏れ
- 空入力や極端に長い入力の処理
- 型変換の問題

### 従来のテストとの使い分け

| 観点 | 従来のテスト | PBT |
|------|------------|-----|
| 目的 | 具体的な動作確認 | 性質の網羅的検証 |
| テストケース | 人間が設計 | 自動生成 |
| 再現性 | 完全に再現可能 | シードで再現 |
| デバッグ | 容易 | 失敗時の入力確認が必要 |
| 適用範囲 | ピンポイント | 広範囲 |

**推奨: 両方を組み合わせる**
- 重要なパスは従来のテストで明示的に確認
- 境界条件やエッジケースは PBT で網羅

---

## 参考リンク

- [rantly](https://github.com/rantly-rb/rantly) - Ruby の PBT ライブラリ
- [PropEr](https://proper-testing.github.io/) - Erlang の PBT（概念の参考に）
- [QuickCheck](https://hackage.haskell.org/package/QuickCheck) - Haskell の元祖 PBT
- [Hypothesis](https://hypothesis.works/) - Python の PBT ライブラリ
