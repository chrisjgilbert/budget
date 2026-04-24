require "test_helper"

class FieldTest < ActiveSupport::TestCase
  setup do
    @month = months(:january_2026)
  end

  def field(behavior, value)
    Field.new(
      month: @month,
      key: behavior,
      label: behavior,
      section: "joint-account",
      behavior: behavior,
      value: value
    )
  end

  # ─── month_contribution ────────────────────────────────────────────────────

  test "shared contributes 50%" do
    assert_in_delta 100, field("shared", 200).month_contribution
  end

  test "mine contributes 100%" do
    assert_in_delta 500, field("mine", 500).month_contribution
  end

  test "partner-pays contributes 100%" do
    assert_in_delta 1000, field("partner-pays", 1000).month_contribution
  end

  test "partner-expense contributes 100%" do
    assert_in_delta 350, field("partner-expense", 350).month_contribution
  end

  test "income contributes 0" do
    assert_in_delta 0, field("income", 5000).month_contribution
  end

  # ─── reconciliation_contribution ───────────────────────────────────────────

  test "shared: partner owes 50%" do
    assert_in_delta 300, field("shared", 600).reconciliation_contribution
  end

  test "partner-pays: you owe 100%" do
    assert_in_delta(-1000, field("partner-pays", 1000).reconciliation_contribution)
  end

  test "partner-expense: reduces partner debt by 100%" do
    assert_in_delta(-350, field("partner-expense", 350).reconciliation_contribution)
  end

  test "mine: no reconciliation effect" do
    assert_in_delta 0, field("mine", 999).reconciliation_contribution
  end

  test "income: no reconciliation effect" do
    assert_in_delta 0, field("income", 5000).reconciliation_contribution
  end

  test "reconciliation handles zero values" do
    assert_in_delta 0, field("shared", 0).reconciliation_contribution
    assert_in_delta 0, field("partner-pays", 0).reconciliation_contribution
  end

  # ─── validations ───────────────────────────────────────────────────────────

  test "requires a valid behavior" do
    f = field("bogus", 10)
    refute f.valid?
    assert_includes f.errors[:behavior], "is not included in the list"
  end

  test "requires a valid section" do
    f = field("mine", 10)
    f.section = "bogus"
    refute f.valid?
    assert_includes f.errors[:section], "is not included in the list"
  end

  test "requires a unique key within a month" do
    field("mine", 10).tap { |f| f.key = "rent"; f.save! }
    dup = field("mine", 20).tap { |f| f.key = "rent" }
    refute dup.valid?
    assert_includes dup.errors[:key], "has already been taken"
  end

  # ─── generate_key ──────────────────────────────────────────────────────────

  test "generate_key slugs labels into camelCase" do
    assert_equal "rent",       Field.generate_key("Rent", @month)
    assert_equal "rentMoney",  Field.generate_key("Rent money", @month)
    assert_equal "groceries",  Field.generate_key("Groceries!", @month)
    assert_equal "field",      Field.generate_key("  ", @month) # falls back to "field"
  end

  test "generate_key disambiguates collisions" do
    @month.fields.create!(key: "rent",  label: "Rent", section: "joint-account",
                          behavior: "mine", position: 0)
    assert_equal "rent2", Field.generate_key("Rent", @month)
    @month.fields.create!(key: "rent2", label: "Rent", section: "joint-account",
                          behavior: "mine", position: 1)
    assert_equal "rent3", Field.generate_key("Rent", @month)
  end

  test "allows the same key across different months" do
    field("mine", 10).tap { |f| f.key = "rent"; f.save! }
    other = Field.new(
      month: months(:february_2026),
      key: "rent", label: "Rent",
      section: "joint-account", behavior: "mine", value: 10
    )
    assert other.valid?
  end
end
