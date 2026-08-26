class AddStatusToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :status, :string, default: "pending", null: false
  end
end
