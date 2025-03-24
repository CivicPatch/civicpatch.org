class PlaceRepresentative < ApplicationRecord
  belongs_to :place, foreign_key: :place_name, primary_key: :name
  belongs_to :representative 
end
