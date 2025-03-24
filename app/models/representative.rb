class Representative < ApplicationRecord
  has_many :place_representatives, dependent: :destroy
  has_many :places, through: :place_representatives

  def self.get_representatives_by_place_name(place_name)
    place_name = Place.format_place_name(place_name)
    PlaceRepresentative.where(place_name: place_name).map(&:representative)
  end
end
