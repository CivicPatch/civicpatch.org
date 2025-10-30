class Municipality < ApplicationRecord
  has_many :representatives

  validates :name, presence: true
  validates :geoid, presence: true

  self.primary_key = "geoid"

  FACTORY = RGeo::Geos.factory(srid: 4269)

  scope :with_state, ->(state) { where("state ILIKE ?", state) }

  def self.find_by_lat_lon(latitude, longitude)
  Rails.logger.info "Searching for municipalities at lat=#{latitude}, lon=#{longitude}"

  # Transform coordinates to match the geometry SRID
  # Nominatim returns WGS84 (SRID 4326), so we transform to match the geometry
  result = where("ST_Intersects(geom, ST_Transform(ST_SetSRID(ST_MakePoint(?, ?), 4326), ST_SRID(geom)))", longitude, latitude)

    Rails.logger.info "Found #{result.count} municipalities"
    result
  end

  def ocd_id
  "ocd-division/country:us/state:#{state}/place:#{name}"
  end

  def self.format_place_name(place_name)
  is_capitalized = place_name == place_name.capitalize
    is_capitalized ? place_name : place_name.split("_").map(&:capitalize).join(" ")
  end

  def self.find_by_state_and_geoid(state, geoid, select_clause = nil)
  query = with_state(state).where(geoid: geoid)
    select_clause ? query.select(select_clause) : query
  end
end
