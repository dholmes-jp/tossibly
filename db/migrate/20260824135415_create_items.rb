class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.string :category
      t.string :platform
      t.text :description
      t.text :description_ja
      t.string :title_ja
      t.string :age
      t.boolean :functional
      t.string :brand
      t.string :model_number
      t.integer :suggested_price
      t.integer :disposal_fee
      t.string :jimoty_category

      t.timestamps
    end
  end
end
