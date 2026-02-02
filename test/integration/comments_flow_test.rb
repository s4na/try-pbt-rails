require "test_helper"

class CommentsFlowTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123"
    )
    @post = @user.posts.create!(title: "Test Post", body: "Test body")
  end

  test "visitor can view comments on post" do
    @post.comments.create!(user: @user, body: "Test comment")
    get post_path(@post)
    assert_response :success
    assert_select "p", "Test comment"
  end

  test "visitor cannot create comment" do
    post post_comments_path(@post), params: { comment: { body: "Test" } }
    assert_redirected_to login_path
  end

  test "user can create comment after login" do
    # Login
    post login_path, params: { email: @user.email, password: "password123" }
    follow_redirect!

    # Create comment
    assert_difference "Comment.count", 1 do
      post post_comments_path(@post), params: { comment: { body: "New comment" } }
    end
    assert_redirected_to post_path(@post)
  end

  test "user can delete own comment" do
    comment = @post.comments.create!(user: @user, body: "To delete")

    # Login
    post login_path, params: { email: @user.email, password: "password123" }
    follow_redirect!

    assert_difference "Comment.count", -1 do
      delete post_comment_path(@post, comment)
    end
    assert_redirected_to post_path(@post)
  end

  test "user cannot delete other user's comment" do
    other_user = User.create!(name: "Other", email: "other@example.com", password: "password123")
    other_comment = @post.comments.create!(user: other_user, body: "Other's comment")

    # Login as @user
    post login_path, params: { email: @user.email, password: "password123" }
    follow_redirect!

    # Try to delete other's comment
    assert_no_difference "Comment.count" do
      delete post_comment_path(@post, other_comment)
    end
    assert_equal "この操作は許可されていません", flash[:alert]
  end
end
