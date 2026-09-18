class User < ApplicationRecord
  DEFAULT_ADDRESS = "1-2-3 Nakameguro, Meguro-ku, Tokyo".freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :items, dependent: :destroy
  has_many :schedules, dependent: :destroy

  before_validation :assign_default_address, on: :create

  validates :address, presence: true
  validates :name, presence: true

  private

  def assign_default_address
    self.address = DEFAULT_ADDRESS if address.blank?
  end
end
