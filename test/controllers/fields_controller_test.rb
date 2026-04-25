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

  # ─── Turbo Stream responses ────────────────────────────────────────────────

  TURBO_STREAM = Mime[:turbo_stream].to_s.freeze

  test "create responds with turbo stream replacing section, summary, sidebar" do
    with_password do
      post month_fields_path(@month),
        params: { field: { label: "Rent", section: "joint-account", behavior: "shared" } },
        as: :turbo_stream
    end
    assert_response :success
    assert_equal TURBO_STREAM, response.media_type
    body = response.body
    assert_match %r{action="replace" target="section-joint-account"}, body
    assert_match %r{action="replace" target="summary-card"}, body
    assert_match %r{action="replace" target="sidebar-month-#{@month.id}"}, body
  end

  test "value-only update emits a narrow turbo stream that leaves the input alone" do
    f = @month.fields.create!(key: "rent", label: "Rent", section: "joint-account",
                              behavior: "shared", value: 100, position: 0)
    with_password do
      patch month_field_path(@month, f),
        params: { field: { value: "1200" } },
        as: :turbo_stream
    end
    body = response.body
    assert_match %r{action="replace" target="share-#{f.id}"}, body
    assert_match %r{action="replace" target="section-joint-account-header"}, body
    assert_match %r{action="replace" target="summary-card"}, body
    assert_match %r{action="replace" target="sidebar-month-#{@month.id}"}, body
    refute_match %r{target="section-joint-account"[^-]}, body # no full-section replace
    refute_match %r{target="field-#{f.id}"}, body             # no row replace
  end

  test "non-value update replaces the affected section" do
    f = @month.fields.create!(key: "rent", label: "Rent", section: "joint-account",
                              behavior: "mine", value: 100, position: 0)
    with_password do
      patch month_field_path(@month, f),
        params: { field: { label: "Rent 2", behavior: "shared" } },
        as: :turbo_stream
    end
    body = response.body
    assert_match %r{action="replace" target="section-joint-account"}, body
    assert_match %r{action="replace" target="summary-card"}, body
  end

  test "update that moves a field across sections replaces both sections" do
    f = @month.fields.create!(key: "rent", label: "Rent", section: "joint-account",
                              behavior: "mine", value: 100, position: 0)
    with_password do
      patch month_field_path(@month, f),
        params: { field: { section: "my-account" } },
        as: :turbo_stream
    end
    body = response.body
    assert_match %r{action="replace" target="section-my-account"}, body
    assert_match %r{action="replace" target="section-joint-account"}, body
  end

  test "destroy emits a remove stream plus header/summary/sidebar updates" do
    f = @month.fields.create!(key: "rent", label: "Rent", section: "joint-account",
                              behavior: "mine", value: 100, position: 0)
    with_password do
      delete month_field_path(@month, f), as: :turbo_stream
    end
    body = response.body
    assert_match %r{action="remove" target="field-#{f.id}"}, body
    assert_match %r{action="replace" target="section-joint-account-header"}, body
    assert_match %r{action="replace" target="summary-card"}, body
  end

  # ─── Authentication ────────────────────────────────────────────────────────

  test "authentication is required" do
    delete logout_path
    f = @month.fields.create!(key: "rent", label: "Rent", section: "joint-account",
                              behavior: "mine", position: 0)
    patch month_field_path(@month, f), params: { field: { value: 100 } }
    assert_redirected_to login_path
  end
end
