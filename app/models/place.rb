class Place < ApplicationRecord
  has_many :representatives

  validates :name, presence: true
  validates :namelsad, presence: true

  self.primary_key = "gid"

  # returns city, town, village, etc.
  def place_type
    namelsad.split(" ").last
  end

  def ocd_id
    "ocd-division/country:us/state:#{state}/place:#{name}"
  end

  def self.format_place_name(place_name)
    is_capitalized = place_name == place_name.capitalize
    is_capitalized ? place_name : place_name.split('_').map(&:capitalize).join(' ')
  end
end
