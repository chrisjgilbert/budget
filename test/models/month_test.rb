require "test_helper"

class MonthTest < ActiveSupport::TestCase
  def build_month(*fields_attrs)
    m = Month.new(year: 2026, month: 3)
    fields_attrs.each_with_index do |attrs, i|
      m.fields.build(
        key: "#{attrs[:behavior]}_#{i}",
        label: attrs[:behavior],
        section: attrs[:section] || "joint-account",
        behavior: attrs[:behavior],
        value: attrs[:value]
      )
    end
    m
  end

  def field(behavior, value, section: "joint-account")
    { behavior: behavior, value: value, section: section }
  end

  # ─── monthly_total ─────────────────────────────────────────────────────────

  test "monthly_total: shared at 50%" do
    assert_in_delta 100, build_month(field("shared", 200)).monthly_total
  end

  test "monthly_total: mine at 100%" do
    assert_in_delta 500, build_month(field("mine", 500)).monthly_total
  end

  test "monthly_total: partner-pays at 100%" do
    assert_in_delta 1000, build_month(field("partner-pays", 1000)).monthly_total
  end

  test "monthly_total: partner-expense at 100%" do
    assert_in_delta 350, build_month(field("partner-expense", 350)).monthly_total
  end

  test "monthly_total: excludes income" do
    assert_in_delta 0, build_month(field("income", 5000)).monthly_total
  end

  test "monthly_total: zero for empty fields" do
    assert_in_delta 0, build_month.monthly_total
  end

  test "monthly_total: sums mixed behaviors" do
    m = build_month(
      field("shared", 800),       # 400
      field("mine", 200),         # 200
      field("partner-pays", 100), # 100
      field("income", 5000)       # 0
    )
    assert_in_delta 700, m.monthly_total
  end

  # ─── income_total ──────────────────────────────────────────────────────────

  test "income_total: sums all income fields" do
    m = build_month(field("income", 5000), field("income", 500))
    assert_in_delta 5500, m.income_total
  end

  test "income_total: ignores non-income fields" do
    m = build_month(field("mine", 1000), field("shared", 500))
    assert_in_delta 0, m.income_total
  end

  test "income_total: zero when no income fields" do
    assert_in_delta 0, build_month.income_total
  end

  # ─── diff ──────────────────────────────────────────────────────────────────

  test "diff: income minus monthly total" do
    m = build_month(field("income", 5000), field("mine", 2000))
    assert_in_delta 3000, m.diff
  end

  test "diff: negative when spending exceeds income" do
    m = build_month(field("income", 1000), field("mine", 1500))
    assert_in_delta(-500, m.diff)
  end

  test "diff: zero when balanced" do
    m = build_month(field("income", 1000), field("shared", 2000))
    assert_in_delta 0, m.diff
  end

  # ─── reconciliation ────────────────────────────────────────────────────────

  test "reconciliation: zero for empty fields" do
    assert_in_delta 0, build_month.reconciliation
  end

  test "reconciliation: positive means partner owes you" do
    # shared(800) -> +400; partner-pays(200) -> -200 => +200
    m = build_month(field("shared", 800), field("partner-pays", 200))
    assert_in_delta 200, m.reconciliation
  end

  test "reconciliation: negative means you owe partner" do
    # partner-pays(2000) -> -2000; shared(400) -> +200 => -1800
    m = build_month(field("partner-pays", 2000), field("shared", 400))
    assert_in_delta(-1800, m.reconciliation)
  end

  test "reconciliation: complex scenario combining all behaviors" do
    # shared(800)          -> +400
    # partner-pays(1000)   -> -1000
    # partner-expense(350) -> -350
    # mine(500)            ->  0
    # income(5000)         ->  0
    # net: -950
    m = build_month(
      field("shared", 800),
      field("partner-pays", 1000),
      field("partner-expense", 350),
      field("mine", 500),
      field("income", 5000)
    )
    assert_in_delta(-950, m.reconciliation)
  end

  # ─── joint_transfer ────────────────────────────────────────────────────────

  test "joint_transfer: sums full value of shared fields" do
    m = build_month(field("shared", 800), field("shared", 200), field("mine", 500))
    assert_in_delta 1000, m.joint_transfer
  end

  test "joint_transfer: ignores non-shared fields" do
    m = build_month(field("mine", 500), field("partner-pays", 300), field("income", 5000))
    assert_in_delta 0, m.joint_transfer
  end

  # ─── section_total ─────────────────────────────────────────────────────────

  test "section_total: sums all fields in the given section" do
    m = build_month(
      field("mine", 100,   section: "my-account"),
      field("shared", 200, section: "my-account"),
      field("mine", 50,    section: "cards")
    )
    assert_in_delta 300, m.section_total("my-account")
    assert_in_delta 50,  m.section_total("cards")
  end

  test "section_total: zero for unknown section" do
    m = build_month(field("mine", 100, section: "my-account"))
    assert_in_delta 0, m.section_total("nonexistent")
  end

  # ─── label ─────────────────────────────────────────────────────────────────

  test "label: formatted month and year" do
    assert_equal "January 2026",  Month.new(year: 2026, month: 1).label
    assert_equal "December 2026", Month.new(year: 2026, month: 12).label
  end

  # ─── validations ───────────────────────────────────────────────────────────

  test "requires year and month" do
    m = Month.new
    refute m.valid?
    assert m.errors[:year].present?
    assert m.errors[:month].present?
  end

  test "month must be between 1 and 12" do
    refute Month.new(year: 2026, month: 0).valid?
    refute Month.new(year: 2026, month: 13).valid?
    assert Month.new(year: 2026, month: 6).valid?
  end

  test "month + year combination must be unique" do
    Month.create!(year: 2027, month: 5)
    dup = Month.new(year: 2027, month: 5)
    refute dup.valid?
    assert_includes dup.errors[:month], "has already been taken"
  end

  test "chronological scope orders by year then month" do
    Month.delete_all
    [ [ 2025, 12 ], [ 2026, 1 ], [ 2025, 6 ], [ 2026, 3 ] ].each do |y, mo|
      Month.create!(year: y, month: mo)
    end
    assert_equal [ [ 2025, 6 ], [ 2025, 12 ], [ 2026, 1 ], [ 2026, 3 ] ],
                 Month.chronological.pluck(:year, :month)
  end
end
