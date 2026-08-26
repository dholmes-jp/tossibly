class Item < ApplicationRecord
  belongs_to :user
  has_many_attached :photos

  STATUSES  = %w[pending path_chosen listed disposal_booked passed_on disposed].freeze
  PLATFORMS = %w[mercari jimoty dispose].freeze

  validates :title, presence: true
end
