ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end

TEST_PASSWORD = "correct horse battery staple".freeze
TEST_PASSWORD_HASH = BCrypt::Password.create(TEST_PASSWORD, cost: BCrypt::Engine::MIN_COST).freeze

module AuthenticationHelpers
  def with_password(hash = TEST_PASSWORD_HASH)
    previous = ENV["BUDGET_PASSWORD_HASH"]
    ENV["BUDGET_PASSWORD_HASH"] = hash
    yield
  ensure
    ENV["BUDGET_PASSWORD_HASH"] = previous
  end

  def log_in!
    with_password do
      post login_path, params: { password: TEST_PASSWORD }
    end
  end
end

class ActionDispatch::IntegrationTest
  include AuthenticationHelpers

  setup { Rails.cache.clear }
end
