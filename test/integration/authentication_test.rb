require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  PASSWORD = "correct horse battery staple".freeze

  setup do
    @previous_hash = ENV["BUDGET_PASSWORD_HASH"]
    ENV["BUDGET_PASSWORD_HASH"] = BCrypt::Password.create(PASSWORD, cost: BCrypt::Engine::MIN_COST)
    Rails.cache.clear
  end

  teardown do
    ENV["BUDGET_PASSWORD_HASH"] = @previous_hash
    Rails.cache.clear
  end

  test "unauthenticated requests redirect to login" do
    get root_path
    assert_redirected_to login_path
  end

  test "login page renders for unauthenticated users" do
    get login_path
    assert_response :success
    assert_select "input[type=password]"
  end

  test "correct password logs in and redirects to root" do
    post login_path, params: { password: PASSWORD }
    assert_redirected_to root_path
  end

  test "wrong password re-renders login with alert" do
    post login_path, params: { password: "wrong" }
    assert_response :unprocessable_content
    assert_match(/wrong password/i, response.body + flash[:alert].to_s)
  end

  test "blank password fails" do
    post login_path, params: { password: "" }
    assert_response :unprocessable_content
  end

  test "authenticated users bypass the gate" do
    post login_path, params: { password: PASSWORD }
    get root_path
    # Root redirects to the latest month (or renders empty state), but never to /login
    refute_match %r{/login\z}, response.location.to_s if response.redirect?
  end

  test "authenticated users visiting /login are redirected" do
    post login_path, params: { password: PASSWORD }
    get login_path
    assert_redirected_to root_path
  end

  test "logout clears the session and redirects to login" do
    post login_path, params: { password: PASSWORD }
    delete logout_path
    assert_redirected_to login_path
    get root_path
    assert_redirected_to login_path
  end

  test "missing hash rejects any password" do
    ENV["BUDGET_PASSWORD_HASH"] = nil
    post login_path, params: { password: PASSWORD }
    assert_response :unprocessable_content
  end

  test "malformed hash rejects any password" do
    ENV["BUDGET_PASSWORD_HASH"] = "not-a-bcrypt-hash"
    post login_path, params: { password: PASSWORD }
    assert_response :unprocessable_content
  end

  test "rate limit triggers after 5 wrong attempts" do
    5.times { post login_path, params: { password: "wrong" } }
    post login_path, params: { password: "wrong" }
    assert_redirected_to login_path
    assert_match(/too many attempts/i, flash[:alert].to_s)
  end
end
