require "test_helper"
require "rantly"

class BlogPropertyTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      name: "PBT User",
      email: "pbt@example.com",
      password: "password123"
    )
  end

  # ユーザー名は任意の文字列で、空でなければ有効
  test "user with any non-empty name is valid" do
    50.times do
      name = Rantly { sized(20) { string(:alpha) } }
      next if name.empty?

      user = User.new(
        name: name,
        email: "#{SecureRandom.hex(8)}@example.com",
        password: "password123"
      )
      assert user.valid?, "User with name '#{name}' should be valid"
    end
  end

  # 投稿のタイトルは255文字以下であれば有効
  test "post title within 255 chars is valid" do
    50.times do
      title_length = Rantly { range(1, 255) }
      title = "a" * title_length

      post = @user.posts.build(title: title, body: "Test body")
      assert post.valid?, "Post with title length #{title_length} should be valid"
    end
  end

  # 投稿のタイトルが256文字以上なら無効
  test "post title over 255 chars is invalid" do
    20.times do
      title_length = Rantly { range(256, 500) }
      title = "a" * title_length

      post = @user.posts.build(title: title, body: "Test body")
      assert_not post.valid?, "Post with title length #{title_length} should be invalid"
    end
  end

  # 投稿を作成すると、ユーザーの投稿数が1増える
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

  # コメントを作成すると、投稿のコメント数が1増える
  test "creating comment increases post comments count by 1" do
    post = @user.posts.create!(title: "Test Post", body: "Test body")

    20.times do
      comment_body = Rantly { sized(30) { string } }
      comment_body = "Comment" if comment_body.empty?

      initial_count = post.comments.count
      post.comments.create!(user: @user, body: comment_body)
      assert_equal initial_count + 1, post.comments.count
    end
  end

  # 投稿を削除すると、関連するコメントも削除される
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

  # パスワードは6文字以上であれば有効
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

  # パスワードが5文字以下なら無効
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
end
