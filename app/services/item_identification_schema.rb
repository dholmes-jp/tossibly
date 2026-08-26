class ItemIdentificationSchema < RubyLLM::Schema
  string :name
  optional(:brand) { string }
  string :category
  optional(:model_number) { string }
  string :condition_guess
  array :follow_up_questions, of: :string, max_items: 3
end
