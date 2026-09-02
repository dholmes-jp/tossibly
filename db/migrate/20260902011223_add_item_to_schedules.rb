class AddItemToSchedules < ActiveRecord::Migration[8.1]
  def change
    add_reference :schedules, :item, foreign_key: true
  end
end
