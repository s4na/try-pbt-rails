require "test_helper"
require "rantly"

class CommentsPbtTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      name: "Comment PBT User",
      email: "comment_pbt@example.com",
      password: "password123"
    )
    @post = @user.posts.create!(title: "Test Post for Comments", body: "Post body")
  end

  # Helper methods for PBT generators
  def login_as(user)
    post login_path, params: { email: user.email, password: "password123" }
    follow_redirect!
  end

  def random_body(length = 50)
    body = Rantly { sized(length) { string } }
    body.empty? || body.strip.empty? ? "Random comment body" : body
  end

  # ============================================
  # POST /posts/:post_id/comments - Create endpoint with PBT
  # ============================================

  test "create comment with random non-empty body succeeds" do
    login_as(@user)

    20.times do
      body_length = Rantly { range(1, 500) }
      body = Rantly { sized(body_length) { string } }
      body = "a" * body_length if body.empty? || body.strip.empty?

      assert_difference "Comment.count", 1, "Comment with body length #{body_length} should be created" do
        post post_comments_path(@post), params: { comment: { body: body } }
      end
      assert_redirected_to post_path(@post)
    end
  end

  test "create comment with empty body fails" do
    login_as(@user)

    10.times do
      assert_no_difference "Comment.count" do
        post post_comments_path(@post), params: { comment: { body: "" } }
      end
      assert_redirected_to post_path(@post)
      assert_equal "コメントの投稿に失敗しました", flash[:alert]
    end
  end

  test "create comment with whitespace-only body fails" do
    login_as(@user)

    whitespace_variants = [ " ", "  ", "\t", "\n", "   \n\t  " ]

    whitespace_variants.each do |whitespace|
      assert_no_difference "Comment.count", "Whitespace-only body should fail" do
        post post_comments_path(@post), params: { comment: { body: whitespace } }
      end
      assert_redirected_to post_path(@post)
    end
  end

  # ============================================
  # Authentication tests
  # ============================================

  test "unauthenticated user cannot create comments with any data" do
    15.times do
      body = Rantly { sized(50) { string } }
      body = "Random comment" if body.empty?

      assert_no_difference "Comment.count" do
        post post_comments_path(@post), params: { comment: { body: body } }
      end
      assert_redirected_to login_path
    end
  end

  test "unauthenticated user cannot delete comments" do
    login_as(@user)
    comment = @post.comments.create!(user: @user, body: "Test comment")
    delete logout_path  # Logout

    10.times do
      assert_no_difference "Comment.count" do
        delete post_comment_path(@post, comment)
      end
      assert_redirected_to login_path
    end
  end

  # ============================================
  # Authorization tests
  # ============================================

  test "user cannot delete other user's comment" do
    other_user = User.create!(name: "Other Commenter", email: "other_commenter@example.com", password: "password123")

    10.times do
      body = Rantly { sized(30) { string } }
      body = "Other's comment" if body.empty?

      other_comment = @post.comments.create!(user: other_user, body: body)

      login_as(@user)

      assert_no_difference "Comment.count" do
        delete post_comment_path(@post, other_comment)
      end
      assert_redirected_to post_path(@post)
      assert_equal "この操作は許可されていません", flash[:alert]

      delete logout_path
    end
  end

  test "user can delete own comment with any body content" do
    login_as(@user)

    10.times do
      body = Rantly { sized(50) { string } }
      body = "My comment" if body.empty?

      comment = @post.comments.create!(user: @user, body: body)

      assert_difference "Comment.count", -1 do
        delete post_comment_path(@post, comment)
      end
      assert_redirected_to post_path(@post)
    end
  end

  # ============================================
  # Post association tests
  # ============================================

  test "comments are correctly associated with posts" do
    login_as(@user)

    10.times do
      # Create multiple posts
      new_post = @user.posts.create!(
        title: Rantly { sized(20) { string(:alpha) } }.presence || "Random Post",
        body: "Post body"
      )

      comment_body = Rantly { sized(30) { string } }
      comment_body = "Comment for new post" if comment_body.empty?

      post post_comments_path(new_post), params: { comment: { body: comment_body } }

      created_comment = Comment.last
      assert_equal new_post.id, created_comment.post_id, "Comment should belong to correct post"
      assert_equal @user.id, created_comment.user_id, "Comment should belong to current user"
    end
  end

  # ============================================
  # Edge cases
  # ============================================

  test "create comment with very long body (stress test)" do
    login_as(@user)

    5.times do
      body_length = Rantly { range(1000, 5000) }
      body = "a" * body_length

      # SQLite TEXT type should handle large strings
      assert_difference "Comment.count", 1 do
        post post_comments_path(@post), params: { comment: { body: body } }
      end
      assert_redirected_to post_path(@post)

      created_comment = Comment.last
      assert_equal body_length, created_comment.body.length
    end
  end

  test "create comment with special characters" do
    login_as(@user)

    special_bodies = [
      "Comment with <html>tags</html>",
      "Comment with 'single' and \"double\" quotes",
      "日本語のコメント",
      "Emoji: 🎉🚀💻",
      "Mixed: Test テスト 123 !@#$%",
      "Newlines:\nLine 2\nLine 3",
      "Tabs:\tTabbed\tContent"
    ]

    special_bodies.each do |body|
      assert_difference "Comment.count", 1, "Should handle: #{body.truncate(30)}" do
        post post_comments_path(@post), params: { comment: { body: body } }
      end
    end
  end
end
