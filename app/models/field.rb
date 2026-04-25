class Field < ApplicationRecord
  SECTIONS = %w[joint-account my-account cards partner-account savings income].freeze
  SECTION_TITLES = {
    "joint-account"   => "Joint Account",
    "my-account"      => "My Account",
    "cards"           => "Credit Cards",
    "partner-account" => "Partner Account",
    "savings"         => "Savings",
    "income"          => "Income"
  }.freeze
  BEHAVIORS = %w[mine shared partner-pays partner-expense income].freeze
  BEHAVIOR_LABELS = {
    "mine"            => "My cost",
    "shared"          => "Shared 50/50 (enter total)",
    "partner-pays"    => "Owe partner",
    "partner-expense" => "Partner expense",
    "income"          => "Income"
  }.freeze

  belongs_to :month, inverse_of: :fields

  validates :key,      presence: true, uniqueness: { scope: :month_id }
  validates :label,    presence: true
  validates :section,  presence: true, inclusion: { in: SECTIONS }
  validates :behavior, presence: true, inclusion: { in: BEHAVIORS }
  validates :value,    numericality: true

  # Mirrors toKey() from electron/renderer/app.js — slug is lowercase with
  # camelCased word boundaries; a trailing integer disambiguates collisions
  # within the month.
  def self.generate_key(label, month)
    existing = month.fields.pluck(:key).to_set
    base = label.to_s.strip.downcase
                .gsub(/[^a-z0-9\s]/, "")
                .gsub(/\s+(.)/) { ::Regexp.last_match(1).upcase }
    base = "field" if base.empty?
    candidate = base
    i = 2
    while existing.include?(candidate)
      candidate = "#{base}#{i}"
      i += 1
    end
    candidate
  end

  def share_amount
    behavior == "shared" ? value * 0.5 : 0
  end

  def month_contribution
    case behavior
    when "shared" then value * 0.5
    when "income" then 0
    else value
    end
  end

  def reconciliation_contribution
    case behavior
    when "shared" then value * 0.5
    when "partner-pays", "partner-expense" then -value
    else 0
    end
  end
end
