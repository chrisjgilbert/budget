require "test_helper"

class MonthsControllerTest < ActionDispatch::IntegrationTest
  setup { log_in! }

  test "empty state renders when no months exist" do
    Month.delete_all
    with_password do
      get months_path
    end
    assert_response :success
    assert_select "form[action='#{months_path}'][method='post']"
    assert_match(/No months yet/, response.body)
  end

  test "index redirects to the latest month when months exist" do
    Month.delete_all
    Month.create!(year: 2025, month: 11)
    latest = Month.create!(year: 2026, month: 1)
    with_password do
      get months_path
    end
    assert_redirected_to month_path(latest)
  end

  test "show renders the selected month with sidebar and summary" do
    Month.delete_all
    m = Month.create!(year: 2026, month: 3)
    with_password do
      get month_path(m)
    end
    assert_response :success
    assert_select "#summary-card"
    Field::SECTIONS.each { |s| assert_select "#section-#{s}" }
  end

  test "create builds the next month after the latest and copies fields forward" do
    Month.delete_all
    previous = Month.create!(year: 2026, month: 3)
    previous.fields.create!(key: "rent",   label: "Rent",   section: "joint-account",
                            behavior: "shared", value: 1200, position: 0)
    previous.fields.create!(key: "coffee", label: "Coffee", section: "my-account",
                            behavior: "mine",   value: 45,   reset_on_new: true, position: 1)

    with_password do
      assert_difference -> { Month.count }, 1 do
        post months_path
      end
    end
    created = Month.last
    assert_equal [ 2026, 4 ], [ created.year, created.month ]
    assert_redirected_to month_path(created)

    assert_equal 2, created.fields.count
    rent   = created.fields.find_by(key: "rent")
    coffee = created.fields.find_by(key: "coffee")
    assert_in_delta 1200, rent.value,   0.001
    assert_in_delta 0,    coffee.value, 0.001 # reset_on_new zeroes the copy
  end

  test "create rolls the year when starting from December" do
    Month.delete_all
    Month.create!(year: 2026, month: 12)
    with_password { post months_path }
    created = Month.last
    assert_equal [ 2027, 1 ], [ created.year, created.month ]
  end

  test "create with no existing months uses the current calendar month" do
    Month.delete_all
    now = Time.current
    with_password { post months_path }
    created = Month.last
    assert_equal [ now.year, now.month ], [ created.year, created.month ]
  end

end
