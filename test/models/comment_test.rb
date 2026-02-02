require "test_helper"

class CommentTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123"
    )
    @post = @user.posts.create!(title: "Test Post", body: "Test body")
    @comment = @post.comments.build(user: @user, body: "Test comment")
  end

  test "should be valid with valid attributes" do
    assert @comment.valid?
  end

  test "body should be present" do
    @comment.body = ""
    assert_not @comment.valid?
    assert_includes @comment.errors[:body], "can't be blank"
  end

  test "should belong to user" do
    @comment.user = nil
    assert_not @comment.valid?
  end

  test "should belong to post" do
    @comment.post = nil
    assert_not @comment.valid?
  end
end
