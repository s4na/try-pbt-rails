require "test_helper"

class PostTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      name: "Test User",
      email: "test@example.com",
      password: "password123"
    )
    @post = @user.posts.build(title: "Test Title", body: "Test body content")
  end

  test "should be valid with valid attributes" do
    assert @post.valid?
  end

  test "title should be present" do
    @post.title = ""
    assert_not @post.valid?
    assert_includes @post.errors[:title], "can't be blank"
  end

  test "title should not exceed maximum length" do
    @post.title = "a" * 256
    assert_not @post.valid?
  end

  test "body should be present" do
    @post.body = ""
    assert_not @post.valid?
    assert_includes @post.errors[:body], "can't be blank"
  end

  test "should belong to user" do
    @post.user = nil
    assert_not @post.valid?
  end

  test "should have many comments" do
    @post.save
    comment = @post.comments.create!(user: @user, body: "Test comment")
    assert_includes @post.comments, comment
  end

  test "destroying post should destroy associated comments" do
    @post.save
    @post.comments.create!(user: @user, body: "Test comment")
    assert_difference "Comment.count", -1 do
      @post.destroy
    end
  end
end
