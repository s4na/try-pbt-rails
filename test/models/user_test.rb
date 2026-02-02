require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = User.new(
      name: "Test User",
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "should be valid with valid attributes" do
    assert @user.valid?
  end

  test "name should be present" do
    @user.name = ""
    assert_not @user.valid?
    assert_includes @user.errors[:name], "can't be blank"
  end

  test "email should be present" do
    @user.email = ""
    assert_not @user.valid?
  end

  test "email should be unique" do
    @user.save
    duplicate_user = @user.dup
    # Same email should be invalid
    assert_not duplicate_user.valid?
  end

  test "email should have valid format" do
    invalid_emails = [ "user", "user@", "@example.com", "user@.com" ]
    invalid_emails.each do |invalid_email|
      @user.email = invalid_email
      assert_not @user.valid?, "#{invalid_email.inspect} should be invalid"
    end
  end

  test "password should have minimum length" do
    @user.password = @user.password_confirmation = "a" * 5
    assert_not @user.valid?
  end

  test "should authenticate with correct password" do
    @user.save
    assert @user.authenticate("password123")
  end

  test "should not authenticate with incorrect password" do
    @user.save
    assert_not @user.authenticate("wrongpassword")
  end
end
