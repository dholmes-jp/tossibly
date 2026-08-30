# Resolves a real disposal fee estimate for an Item.
#
# Only two categories carry real fee data — appliance_recycling_law and
# large_sized_waste. Everything else is free and just proxies the category's
# own cost_label, so this service is safe to call for any item.
#
#   DisposalFeeEstimator.call(item) # => Estimate
#
# Matching is longest-keyword-wins on word boundaries, NOT substring order.
# Both matter: word boundaries are what stop "can" matching "canvas" (the
# tote-bag bug), and longest-wins is what lets "electric bicycle" (¥1,300)
# beat "bicycle" (¥800) and "double-pedestal desk" (¥3,000) beat "desk"
# (¥1,300) while the YAML stays in readable ascending-fee order.

class DisposalFeeEstimator
  FEE_TIERED_CATEGORIES = %w[appliance_recycling_law large_sized_waste].freeze

  APPROXIMATE_NOTE = "We couldn't pin down the exact item type, so this shows " \
                     "the full range for this category — the exact fee is " \
                     "confirmed when you apply.".freeze

  Estimate = Struct.new(
    :label, :low, :high, :notes, :application_url, :application_label, :matched_key,
    keyword_init: true
  ) do
    def notes?
      notes.present?
    end

    def application_link?
      application_url.present?
    end
  end

  def self.call(item)
    new(item).call
  end

  def initialize(item)
    @item = item
  end

  def call
    return generic_estimate unless fee_tiered?

    subitem = best_matching_subitem
    subitem ? subitem_estimate(subitem) : fallback_estimate
  end

  private

  attr_reader :item

  def category
    @category ||= item.waste_category
  end

  def fee_tiered?
    category.present? && FEE_TIERED_CATEGORIES.include?(category.key)
  end

  # Free categories (and items with no category yet) keep their existing label.
  def generic_estimate
    Estimate.new(
      label: category&.cost_label,
      notes: [category&.cost_note].compact_blank
    )
  end

  def subitem_estimate(subitem)
    Estimate.new(
      label: subitem[:cost_label_override].presence ||
             WasteCategoryLookup.range_label(subitem[:cost_yen_low], subitem[:cost_yen_high]),
      low: subitem[:cost_yen_low],
      high: subitem[:cost_yen_high],
      notes: [subitem[:cost_note], category.collection_fee_note].compact_blank,
      application_url: category.application_url,
      application_label: category.application_label,
      matched_key: subitem[:key]
    )
  end

  # Nothing matched — show the category's full span and say so.
  def fallback_estimate
    Estimate.new(
      label: category.cost_label,
      low: category.cost_yen_low,
      high: category.cost_yen_high,
      notes: [APPROXIMATE_NOTE, category.collection_fee_note].compact_blank,
      application_url: category.application_url,
      application_label: category.application_label
    )
  end

  def best_matching_subitem
    matches = []

    Array(category.subitems).each_with_index do |subitem, index|
      Array(subitem[:keywords]).each do |keyword|
        term = normalize(keyword)
        next if term.blank?
        next unless haystack.match?(/\b#{Regexp.escape(term)}\b/)

        # Sort key: longest keyword first, earlier subitem breaks ties.
        matches << [term.length, -index, subitem]
      end
    end

    matches.max_by { |length, position, _subitem| [length, position] }&.last
  end

  # Title and category are the two English descriptive fields identification
  # fills in. Description is deliberately excluded — too noisy for keyword hits.
  def haystack
    @haystack ||= normalize([item.title, item.category].compact.join(" "))
  end

  # Collapses punctuation to single spaces on both sides of the match, so
  # "air-con" / "air con" and "e-bike" / "e bike" don't miss each other.
  def normalize(text)
    text.to_s.downcase.gsub(/[^a-z0-9]+/, " ").strip
  end
end
