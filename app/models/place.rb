class Place < ApplicationRecord
  has_many :place_representatives
  has_many :representatives, through: :place_representatives

  validates :name, presence: true
  validates :namelsad, presence: true

  # returns city, town, village, etc.
  def place_type
    namelsad.split(" ").last
  end
end
