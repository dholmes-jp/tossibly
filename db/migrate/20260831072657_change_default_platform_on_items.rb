class ChangeDefaultPlatformOnItems < ActiveRecord::Migration[7.1]
  def change
    change_column_default :items, :platform, from: nil, to: "other"
  end
end
