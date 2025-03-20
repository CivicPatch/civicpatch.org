class CongressionalDistrict < ApplicationRecord
  validates :boundaries, presence: true
  validates :ocd_id, presence: true
end
