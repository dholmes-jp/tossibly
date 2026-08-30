class AddWasteCategoryFieldsToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :waste_category_key, :string
    add_column :items, :listable, :boolean, null: false, default: true
  end
end
