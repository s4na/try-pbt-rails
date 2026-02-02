require "test_helper"

class PostsFlowTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123"
    )
  end

  test "visitor can view posts index" do
    get posts_path
    assert_response :success
    assert_select "h1", "ブログ記事一覧"
  end

  test "visitor cannot create post" do
    get new_post_path
    assert_redirected_to login_path
  end

  test "user can create post after login" do
    # Login
    post login_path, params: { email: @user.email, password: "password123" }
    assert_redirected_to root_path
    follow_redirect!

    # Create post
    get new_post_path
    assert_response :success

    assert_difference "Post.count", 1 do
      post posts_path, params: { post: { title: "New Post", body: "Post content" } }
    end
    assert_redirected_to post_path(Post.last)
  end

  test "user can edit own post" do
    post = @user.posts.create!(title: "Original", body: "Original body")

    # Login
    post login_path, params: { email: @user.email, password: "password123" }
    follow_redirect!

    # Edit
    get edit_post_path(post)
    assert_response :success

    patch post_path(post), params: { post: { title: "Updated", body: "Updated body" } }
    assert_redirected_to post_path(post)

    post.reload
    assert_equal "Updated", post.title
  end

  test "user can delete own post" do
    created_post = @user.posts.create!(title: "To Delete", body: "Delete me")

    # Login
    post login_path, params: { email: @user.email, password: "password123" }
    follow_redirect!

    assert_difference "Post.count", -1 do
      delete post_path(created_post)
    end
    assert_redirected_to posts_path
  end

  test "user cannot edit other user's post" do
    other_user = User.create!(name: "Other", email: "other@example.com", password: "password123")
    other_post = other_user.posts.create!(title: "Other's Post", body: "Content")

    # Login as @user
    post login_path, params: { email: @user.email, password: "password123" }
    follow_redirect!

    # Try to edit other's post
    get edit_post_path(other_post)
    assert_redirected_to post_path(other_post)
    assert_equal "この操作は許可されていません", flash[:alert]
  end
end
