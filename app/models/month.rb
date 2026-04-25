class Month < ApplicationRecord
  has_many :fields, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :month

  validates :year, presence: true,
                   numericality: { only_integer: true, greater_than: 1900, less_than: 3000 }
  validates :month, presence: true,
                    numericality: { only_integer: true, in: 1..12 },
                    uniqueness: { scope: :year }

  scope :chronological, -> { order(:year, :month) }

  # Mirrors addMonth() from electron/renderer/app.js: next calendar month after
  # the latest, or the current month if none exist; copies fields forward,
  # zeroing any marked reset_on_new.
  def self.create_next
    latest = chronological.last
    year, month = if latest
      latest.month == 12 ? [ latest.year + 1, 1 ] : [ latest.year, latest.month + 1 ]
    else
      now = Time.current
      [ now.year, now.month ]
    end

    return nil if exists?(year: year, month: month)

    new_month = create!(year: year, month: month)
    latest&.fields&.each do |f|
      new_month.fields.create!(
        key: f.key, label: f.label, section: f.section, behavior: f.behavior,
        reset_on_new: f.reset_on_new, position: f.position,
        value: f.reset_on_new? ? 0 : f.value
      )
    end
    new_month
  end

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
