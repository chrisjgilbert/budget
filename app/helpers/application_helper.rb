module ApplicationHelper
  # GBP-formatted amount, no decimals. Mirrors fmt() from electron/renderer/budget.js.
  def gbp(amount)
    amount = amount.to_f
    sign = amount.negative? ? "-" : ""
    "#{sign}£#{amount.abs.round.to_s.reverse.scan(/\d{1,3}/).join(',').reverse}"
  end

  def signed_gbp(amount)
    amount = amount.to_f
    amount.positive? ? "+#{gbp(amount)}" : gbp(amount)
  end

  def sidebar_badge_classes(amount)
    if amount.positive?
      "bg-emerald-500/20 text-emerald-400"
    elsif amount.negative?
      "bg-rose-500/20 text-rose-400"
    else
      "bg-white/10 text-slate-300"
    end
  end

  def summary_value_color(amount)
    if amount.positive?
      "text-emerald-600"
    elsif amount.negative?
      "text-rose-600"
    else
      "text-slate-900"
    end
  end
end
