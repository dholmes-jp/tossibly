class AddNearbyListingsToItems < ActiveRecord::Migration[8.1]
  def up

    add_column :items, :nearby_listings, :jsonb, default: {}, null: false
    # The Japanese search term the AI builds for us, e.g. "日立冷蔵庫".
    add_column :items, :jimoty_search_keyword, :string
    add_column :items, :processed_at, :datetime
    execute "UPDATE items SET processed_at = NOW()"
  end

  def down
    remove_column :items, :nearby_listings
    remove_column :items, :jimoty_search_keyword
    remove_column :items, :processed_at
  end
end
