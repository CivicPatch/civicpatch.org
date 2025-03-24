class Representative < ApplicationRecord
  has_many :place_representatives
  has_many :places, through: :place_representatives
end
