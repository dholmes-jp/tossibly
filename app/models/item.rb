class Item < ApplicationRecord
  belongs_to :user
  has_many_attached :photos

  STATUSES  = %w[pending path_chosen listed disposal_booked passed_on disposed].freeze
  PLATFORMS = %w[jimoty dispose].freeze

  validates :title, presence: true
  validates :waste_category_key, inclusion: { in: WasteCategoryLookup.keys }, allow_nil: true

  def waste_category
    WasteCategoryLookup.find(waste_category_key)
  end

  def photo_urls
    photos.map { |photo| photo.blob.url }
  end
end
