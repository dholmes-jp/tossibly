module ApplicationHelper
  def yen(amount)
    number_to_currency(amount.to_i, unit: "¥", precision: 0, format: "%u%n")
  end
end
