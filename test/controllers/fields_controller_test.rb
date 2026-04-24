require "test_helper"

class FieldsControllerTest < ActionDispatch::IntegrationTest
  setup do
    log_in!
    @month = months(:january_2026)
    @month.fields.delete_all
  end

  test "create builds a field with a slugified key" do
    with_password do
      assert_difference -> { Field.where(month: @month).count }, 1 do
        post month_fields_path(@month), params: {
          field: { label: "Rent money", section: "joint-account", behavior: "shared" }
        }
      end
    end
    f = @month.fields.reload.last
    assert_equal "rentMoney", f.key
    assert_equal "Rent money", f.label
    assert_equal "shared", f.behavior
    assert_redirected_to month_path(@month)
  end

  test "create appends to position at end of month" do
    @month.fields.create!(key: "a", label: "A", section: "joint-account", behavior: "mine", position: 0)
    @month.fields.create!(key: "b", label: "B", section: "joint-account", behavior: "mine", position: 1)
    with_password do
      post month_fields_path(@month), params: {
        field: { label: "C", section: "joint-account", behavior: "mine" }
      }
    end
    assert_equal 2, @month.fields.reload.find_by(key: "c").position
  end

  test "create with duplicate label disambiguates the key" do
    @month.fields.create!(key: "rent", label: "Rent", section: "joint-account", behavior: "mine", position: 0)
    with_password do
      post month_fields_path(@month), params: {
        field: { label: "Rent", section: "joint-account", behavior: "mine" }
      }
    end
    assert_equal %w[rent rent2], @month.fields.reload.order(:position).pluck(:key)
  end

  test "create rejects a blank label" do
    with_password do
      assert_no_difference -> { Field.where(month: @month).count } do
        post month_fields_path(@month), params: { field: { label: "   ", section: "joint-account", behavior: "mine" } }
      end
    end
    assert_redirected_to month_path(@month)
    assert_match(/name is required/i, flash[:alert].to_s)
  end

  test "update changes value and behavior" do
    f = @month.fields.create!(key: "rent", label: "Rent", section: "joint-account", behavior: "mine", value: 100, position: 0)
    with_password do
      patch month_field_path(@month, f), params: { field: { value: "1200.50", behavior: "shared" } }
    end
    f.reload
    assert_in_delta 1200.50, f.value, 0.001
    assert_equal "shared", f.behavior
  end

  test "update with blank value stores zero" do
    f = @month.fields.create!(key: "rent", label: "Rent", section: "joint-account", behavior: "mine", value: 100, position: 0)
    with_password do
      patch month_field_path(@month, f), params: { field: { value: "" } }
    end
    assert_in_delta 0, f.reload.value, 0.001
  end

  test "destroy removes the field" do
    f = @month.fields.create!(key: "rent", label: "Rent", section: "joint-account", behavior: "mine", position: 0)
    with_password do
      assert_difference -> { Field.where(month: @month).count }, -1 do
        delete month_field_path(@month, f)
      end
    end
    assert_redirected_to month_path(@month)
  end

  test "authentication is required" do
    delete logout_path
    f = @month.fields.create!(key: "rent", label: "Rent", section: "joint-account", behavior: "mine", position: 0)
    patch month_field_path(@month, f), params: { field: { value: 100 } }
    assert_redirected_to login_path
  end
end
