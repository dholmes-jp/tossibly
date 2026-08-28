class AddConfirmedPriceToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :confirmed_price, :integer
  end
end
