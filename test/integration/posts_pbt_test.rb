require "test_helper"
require "rantly"

class PostsPbtTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      name: "PBT Test User",
      email: "pbt_test@example.com",
      password: "password123"
    )
  end

  # Helper methods for PBT generators
  def login_as(user)
    post login_path, params: { email: user.email, password: "password123" }
    follow_redirect!
  end

  def random_title(length)
    title = Rantly { sized(length) { string(:alpha) } }
    title.empty? ? "a" * length : title.slice(0, length).ljust(length, "a")
  end

  def random_body(length = 50)
    body = Rantly { sized(length) { string } }
    body.empty? ? "Random body content" : body
  end

  # ============================================
  # POST /posts - Create endpoint with PBT
  # ============================================

  test "create post with valid random titles (1-255 chars) succeeds" do
    login_as(@user)

    20.times do
      title_length = Rantly { range(1, 255) }
      title = Rantly { sized(title_length) { string(:alpha) } }
      title = "a" * title_length if title.empty? || title.length != title_length
      body = Rantly { sized(50) { string } }
      body = "Random body content" if body.empty?

      assert_difference "Post.count", 1, "Title length #{title_length} should be valid" do
        post posts_path, params: { post: { title: title, body: body } }
      end
      assert_redirected_to post_path(Post.last)
    end
  end

  test "create post with invalid titles (>255 chars) fails" do
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

  test "create post with empty title fails" do
    login_as(@user)

    10.times do
      body = Rantly { sized(100) { string } }
      body = "Some body content" if body.empty?

      assert_no_difference "Post.count" do
        post posts_path, params: { post: { title: "", body: body } }
      end
      assert_response :unprocessable_entity
    end
  end

  test "create post with empty body fails" do
    login_as(@user)

    10.times do
      title = Rantly { sized(20) { string(:alpha) } }
      title = "Valid Title" if title.empty?

      assert_no_difference "Post.count" do
        post posts_path, params: { post: { title: title, body: "" } }
      end
      assert_response :unprocessable_entity
    end
  end

  # ============================================
  # PATCH /posts/:id - Update endpoint with PBT
  # ============================================

  test "update post with valid random data succeeds" do
    login_as(@user)
    created_post = @user.posts.create!(title: "Original", body: "Original body")

    15.times do
      title_length = Rantly { range(1, 255) }
      new_title = "a" * title_length
      new_body = Rantly { sized(50) { string } }
      new_body = "Updated body" if new_body.empty?

      patch post_path(created_post), params: { post: { title: new_title, body: new_body } }
      assert_redirected_to post_path(created_post)

      created_post.reload
      assert_equal new_title, created_post.title
    end
  end

  test "update post with invalid title (>255 chars) fails" do
    login_as(@user)
    created_post = @user.posts.create!(title: "Original", body: "Original body")
    original_title = created_post.title

    10.times do
      title_length = Rantly { range(256, 400) }
      invalid_title = "a" * title_length

      patch post_path(created_post), params: { post: { title: invalid_title, body: "Body" } }
      assert_response :unprocessable_entity

      created_post.reload
      assert_equal original_title, created_post.title, "Title should not be updated with invalid length"
    end
  end

  # ============================================
  # Authentication tests with random data
  # ============================================

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

  test "unauthenticated user cannot update posts" do
    created_post = @user.posts.create!(title: "Original", body: "Original body")
    original_title = created_post.title

    10.times do
      new_title = Rantly { sized(20) { string(:alpha) } }
      new_title = "New Title" if new_title.empty?

      patch post_path(created_post), params: { post: { title: new_title, body: "New body" } }
      assert_redirected_to login_path

      created_post.reload
      assert_equal original_title, created_post.title
    end
  end

  # ============================================
  # Authorization tests
  # ============================================

  test "user cannot update other user's post with any data" do
    other_user = User.create!(name: "Other", email: "other@example.com", password: "password123")
    other_post = other_user.posts.create!(title: "Other's Post", body: "Other's content")
    original_title = other_post.title

    login_as(@user)

    10.times do
      new_title = Rantly { sized(20) { string(:alpha) } }
      new_title = "Attempted Title" if new_title.empty?

      patch post_path(other_post), params: { post: { title: new_title, body: "Attempted body" } }
      assert_redirected_to post_path(other_post)

      other_post.reload
      assert_equal original_title, other_post.title, "Other user's post should not be modified"
    end
  end

  # ============================================
  # Boundary value tests
  # ============================================

  test "title at exact boundary (255 chars) is valid" do
    login_as(@user)

    5.times do
      title = "a" * 255
      body = Rantly { sized(50) { string } }
      body = "Body content" if body.empty?

      assert_difference "Post.count", 1 do
        post posts_path, params: { post: { title: title, body: body } }
      end
    end
  end

  test "title at boundary+1 (256 chars) is invalid" do
    login_as(@user)

    5.times do
      title = "a" * 256
      body = Rantly { sized(50) { string } }
      body = "Body content" if body.empty?

      assert_no_difference "Post.count" do
        post posts_path, params: { post: { title: title, body: body } }
      end
      assert_response :unprocessable_entity
    end
  end
end
