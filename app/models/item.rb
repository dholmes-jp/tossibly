class Item < ApplicationRecord
  belongs_to :user
  has_many_attached :photos

  STATUSES  = %w[pending path_chosen listed disposal_booked passed_on disposed].freeze
  PLATFORMS = %w[jimoty dispose].freeze

  store_accessor :nearby_listings,
                 :nearby_count, :free_count, :typical_price,
                 :price_low, :price_high, :search_scope, :checked_at

  attribute :nearby_count,  :integer
  attribute :free_count,    :integer
  attribute :typical_price, :integer
  attribute :price_low,     :integer
  attribute :price_high,    :integer
  attribute :checked_at,    :datetime

  validates :title, presence: true
  validates :waste_category_key, inclusion: { in: WasteCategoryLookup.keys }, allow_nil: true

  def waste_category
    WasteCategoryLookup.find(waste_category_key)
  end

  def processed?
    processed_at.present?
  end

  def nearby_listings_found?
    nearby_count.to_i.positive?
  end

  def photo_urls
    photos.map { |photo| photo.blob.url }
  end
end
