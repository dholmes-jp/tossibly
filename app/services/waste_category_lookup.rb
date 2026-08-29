# Plain config lookup over config/waste_categories.yml
# Decided to use this intead of a full migration to allow
# for easier edits during testing.

class WasteCategoryLookup
  FILE_PATH = Rails.root.join("config", "waste_categories.yml")

  Category = Struct.new(
    :key, :name, :blurb, :steps, :subitems, :cost_yen, :cost_note,
    :application_required, :collection_frequency, :chip_label, :position,
    keyword_init: true
  ) do
    def application_required?
      !!application_required
    end

    def cost_label
      return cost_note if cost_yen.nil? && cost_note.present?
      return "Free" if cost_yen.to_i.zero?

      "¥#{cost_yen}"
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

    private

    def categories
      @categories ||= YAML.load_file(FILE_PATH).deep_symbolize_keys.map do |key, attrs|
        Category.new(key: key.to_s, **attrs)
      end.sort_by(&:position)
    end
  end
end
