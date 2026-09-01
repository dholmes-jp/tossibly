module ApplicationHelper
  include SimpleCalendar::CalendarHelper

  def yen(amount)
    number_to_currency(amount.to_i, unit: "¥", precision: 0, format: "%u%n")
  end

  def time_of_day_greeting(time = Time.current)
    case time.hour
    when 5..11  then "Good morning"
    when 12..17 then "Good afternoon"
    else             "Good evening"
    end
  end
end
