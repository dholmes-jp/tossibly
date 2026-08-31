class ItemIdentificationSchema < RubyLLM::Schema
  string :name
  optional(:brand) { string }
  string :category
  optional(:model_number) { string }
  string :condition_guess
  string :waste_category_key, enum: WasteCategoryLookup.keys
  boolean :listable
  string :jimoty_search_keyword
  array :follow_up_questions, of: :string, max_items: 3
end
