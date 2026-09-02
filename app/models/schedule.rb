class Schedule < ApplicationRecord
  belongs_to :user
  belongs_to :item, optional: true

  # Waste categories with a real, fixed recurring collection day on Meguro's
  # regular ward calendar, and the CSS dot class the calendar view draws for
  # each (was hardcoded separately as SchedulesController#index's
  # @weekly_schedule wday hash, plus an inline Saturday check in the view —
  # unified here so there's one definition instead of three). Every other
  # waste category (mercury products, used paper, designated small
  # appliances, batteries, appliance-recycling-law items, large-sized waste)
  # has no single fixed date: it's a drop-off point, a group collection with
  # no citywide day, or something you apply for and get assigned a date — so
  # #collected_on? is false and #next_collection_date_for returns nil for those.
  FIXED_COLLECTION_DOT_CLASSES = {
    "combustible" => "combustibles",
    "recyclable" => "recyclables",
    "non_combustible" => "non-combustibles"
  }.freeze

  # True if this waste category is actually collected on the given date.
  def self.collected_on?(date, waste_category_key)
    case waste_category_key
    when "combustible" then [2, 5].include?(date.wday) # Tuesday, Friday
    when "recyclable" then date.wday == 4 # Thursday
    when "non_combustible" then date.saturday? && (date.day.between?(1, 7) || date.day.between?(15, 21))
    else false
    end
  end

  # Next date this waste category is actually collected on, or nil if it has
  # no fixed schedule — callers should fall back to asking the user to add
  # the date manually once they know it (e.g. after contacting the ward
  # office for large-sized waste or an appliance-recycling-law item).
  def self.next_collection_date_for(waste_category_key, from: Date.current)
    return nil unless FIXED_COLLECTION_DOT_CLASSES.key?(waste_category_key)

    (0..45).map { |offset| from + offset.days }.find { |date| collected_on?(date, waste_category_key) }
  end
end
