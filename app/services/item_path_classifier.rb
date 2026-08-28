# Maps an Item onto one of five disposal "buckets" using loose keyword matching
# against its `category`, `jimoty_category` and `title`.
#
# This is a deliberately disposable plain Ruby object (NOT an ActiveRecord
# concern) so it can be deleted in a single step once the data model grows a
# real, structured waste-category field. Until then it's the single source of
# truth for which layout the item show page renders.
#
#   ItemPathClassifier.call(item) # => :single_path
#
# Only :single_path renders the one-card, dispose-only layout. The other four
# buckets all render the two-path (Jimoty / Dispose) layout and differ only in
# the copy and cost shown in the Dispose panel.

class ItemPathClassifier
  # ---------------------------------------------------------------------------
  # Placeholder data
  #
  # Everything in this block is a stand-in until real comps / fee data sources
  # exist. It lives here, in one place, purely so it's easy to find and swap
  # out later. Every value is within the ¥0–5,000 range agreed for the mock.
  # ---------------------------------------------------------------------------

  # Stand-in "similar listings nearby" comps used by the Jimoty panel.
  PLACEHOLDER_COMPS = {
    nearby_listings: 5,
    asking_low: 1_000,
    asking_high: 4_000
  }.freeze

  # Stand-in disposal fee for Home Appliance Recycling Law items (¥0–5,000).
  APPLIANCE_RECYCLING_FEE = 4_300

  # Stand-in disposal fee for generic bulky / large-sized waste (¥0–5,000).
  BULKY_GENERIC_FEE = 2_000

  # Stand-in count of designated small-appliance drop-off points shown as a stat.
  DROPOFF_POINTS = 10

  # ---------------------------------------------------------------------------
  # Keyword tables (all matched as downcased substrings)
  # ---------------------------------------------------------------------------

  SINGLE_PATH_KEYWORDS = [
    "wrapper", "packaging", "pet bottle", "bottle", "can", "food waste",
    "kitchen garbage", "paper waste", "cardboard", "plastic bag", "snack",
    "beverage", "drink"
  ].freeze

  DESIGNATED_SMALL_APPLIANCE_KEYWORDS = [
    "phone", "smartphone", "mobile", "game console", "handheld game",
    "music player", "digital camera", "video camera", "camcorder",
    "electronic dictionary", "calculator", "car navigation", "cable",
    "charger", "adapter"
  ].freeze

  APPLIANCE_RECYCLING_LAW_KEYWORDS = [
    "refrigerator", "freezer", "air conditioner", "aircon", "washing machine",
    "dryer", "tv", "television"
  ].freeze

  BULKY_GENERIC_KEYWORDS = [
    "chair", "sofa", "couch", "table", "desk", "bed", "mattress", "dresser",
    "shelf", "bookcase", "wardrobe", "bicycle", "bike"
  ].freeze

  # Loose hints for guessing the right household bin for a :single_path item.
  # Display copy only — falls back to a generic phrase when nothing obvious hits.
  RECYCLABLE_BIN_HINTS = ["pet bottle", "bottle", "can", "cardboard", "paper waste"].freeze
  COMBUSTIBLE_BIN_HINTS = [
    "wrapper", "packaging", "plastic bag", "snack", "beverage", "drink",
    "food waste", "kitchen garbage"
  ].freeze

  def self.call(item)
    new(item).call
  end

  def initialize(item)
    @item = item
  end

  def call
    return :single_path if match?(SINGLE_PATH_KEYWORDS)
    return :designated_small_appliance if match?(DESIGNATED_SMALL_APPLIANCE_KEYWORDS)
    return :appliance_recycling_law if match?(APPLIANCE_RECYCLING_LAW_KEYWORDS)
    return :bulky_generic if match?(BULKY_GENERIC_KEYWORDS)

    :small_item_generic
  end

  # Best-effort bin label for a :single_path item, used only in display copy.
  def single_path_bin
    return "recyclables" if match?(RECYCLABLE_BIN_HINTS)
    return "combustible waste" if match?(COMBUSTIBLE_BIN_HINTS)

    "regular household waste"
  end

  private

  def match?(keywords)
    keywords.any? { |keyword| haystack.include?(keyword) }
  end

  def haystack
    @haystack ||= [@item.category, @item.jimoty_category, @item.title]
                  .compact.join(" ").downcase
  end
end
