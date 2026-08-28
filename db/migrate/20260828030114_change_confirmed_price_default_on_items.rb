class ChangeConfirmedPriceDefaultOnItems < ActiveRecord::Migration[8.1]
  def up
    change_column_default :items, :confirmed_price, from: nil, to: 0
    Item.where(confirmed_price: nil).update_all(confirmed_price: 0)
  end

  def down
    change_column_default :items, :confirmed_price, from: 0, to: nil
  end
end
