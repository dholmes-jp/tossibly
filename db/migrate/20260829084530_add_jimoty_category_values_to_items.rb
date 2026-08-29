class AddJimotyCategoryValuesToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :jimoty_category_value, :string
    add_column :items, :jimoty_large_genre_value, :string
    add_column :items, :jimoty_medium_genre_value, :string
  end
end
