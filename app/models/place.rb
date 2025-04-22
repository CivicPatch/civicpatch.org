class Place < ApplicationRecord
  has_many :representatives

  validates :name, presence: true
  validates :namelsad, presence: true

  self.primary_key = "gid"

  FACTORY = RGeo::Geos.factory(srid: 4269)

  def self.find_by_lat_lon(latitude, longitude)
    where("ST_Intersects(geom, ST_SetSRID(ST_MakePoint(?, ?), 4269))", longitude, latitude)
  end

  def place_type
    namelsad.split(" ").last
  end

  def ocd_id
    "ocd-division/country:us/state:#{state}/place:#{name}"
  end

  def self.format_place_name(place_name)
    is_capitalized = place_name == place_name.capitalize
    is_capitalized ? place_name : place_name.split("_").map(&:capitalize).join(" ")
  end
end
