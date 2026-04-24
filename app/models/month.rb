class Month < ApplicationRecord
  has_many :fields, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :month

  validates :year, presence: true,
                   numericality: { only_integer: true, greater_than: 1900, less_than: 3000 }
  validates :month, presence: true,
                    numericality: { only_integer: true, in: 1..12 },
                    uniqueness: { scope: :year }

  scope :chronological, -> { order(:year, :month) }

  def label
    Date.new(year, month, 1).strftime("%B %Y")
  end

  def monthly_total
    fields.sum(&:month_contribution)
  end

  def income_total
    fields.select { |f| f.behavior == "income" }.sum(&:value)
  end

  def diff
    income_total - monthly_total
  end

  def reconciliation
    fields.sum(&:reconciliation_contribution)
  end

  def joint_transfer
    fields.select { |f| f.behavior == "shared" }.sum(&:value)
  end

  def section_total(section_id)
    fields.select { |f| f.section == section_id }.sum(&:value)
  end
end
