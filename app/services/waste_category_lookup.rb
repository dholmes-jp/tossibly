# Plain config lookup over config/waste_categories.yml
# Decided to use this intead of a full migration to allow
# for easier edits during testing.

class WasteCategoryLookup
  FILE_PATH = Rails.root.join("config", "waste_categories.yml")

  RANGE_SEPARATOR = "–".freeze

  Category = Struct.new(
    :key, :name, :blurb, :steps, :subitems, :cost_yen, :cost_note,
    # Real sourced fee data. Only appliance_recycling_law and large_sized_waste
    # use these. The other seven categories are free and keep using cost_yen.
    :cost_yen_low, :cost_yen_high, :collection_fee_note,
    :application_url, :application_label,
    :application_required, :collection_frequency, :chip_label, :position,
    keyword_init: true
  ) do
    def application_required?
      !!application_required
    end

    # True when this category carries a real fee range rather than one flat cost.
    def ranged_cost?
      cost_yen_low.present? && cost_yen_high.present?
    end

    def cost_label
      return WasteCategoryLookup.range_label(cost_yen_low, cost_yen_high) if ranged_cost?
      return cost_note if cost_yen.nil? && cost_note.present?
      return "Free" if cost_yen.to_i.zero?

      WasteCategoryLookup.yen(cost_yen)
    end
  end

  class << self
    def all
      categories
    end

    def keys
      categories.map(&:key)
    end

    def find(key)
      return nil if key.blank?

      categories.find { |c| c.key == key.to_s }
    end

    def find!(key)
      find(key) || raise(ActiveRecord::RecordNotFound, "No waste category for key #{key.inspect}")
    end

    # Shared formatters so a category-level range and a subitem-level range
    # (resolved later by DisposalFeeEstimator) always render identically.
    def yen(amount)
      "¥#{amount.to_i.to_fs(:delimited)}"
    end

    def range_label(low, high)
      return "Free" if low.to_i.zero? && high.to_i.zero?
      return yen(low) if low.to_i == high.to_i

      "#{yen(low)}#{RANGE_SEPARATOR}#{yen(high)}"
    end

    private

    def categories
      @categories ||= YAML.load_file(FILE_PATH).deep_symbolize_keys.map do |key, attrs|
        Category.new(key: key.to_s, **attrs)
      end.sort_by(&:position)
    end
  end
end
