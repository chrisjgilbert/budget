class Field < ApplicationRecord
  SECTIONS  = %w[joint-account my-account cards partner-account savings income].freeze
  BEHAVIORS = %w[mine shared partner-pays partner-expense income].freeze

  belongs_to :month, inverse_of: :fields

  validates :key,      presence: true, uniqueness: { scope: :month_id }
  validates :label,    presence: true
  validates :section,  presence: true, inclusion: { in: SECTIONS }
  validates :behavior, presence: true, inclusion: { in: BEHAVIORS }
  validates :value,    numericality: true

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
