class ChangeFunctionalDefaultOnItems < ActiveRecord::Migration[8.1]
  def change
    change_column_default :items, :functional, from: nil, to: true
  end
end
