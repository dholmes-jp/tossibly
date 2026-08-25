class ItemListingSchema < RubyLLM::Schema
  string :title
  string :title_ja
  string :description
  string :description_ja
  string :category
  optional(:brand) { string }
  optional(:model_number) { string }
  optional(:suggested_price) { integer }
  optional(:disposal_fee) { integer }
  string :platform, enum: %w[mercari jimoty]
  optional(:jimoty_category) { string }
end
