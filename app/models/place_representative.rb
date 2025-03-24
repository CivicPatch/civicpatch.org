class PlaceRepresentative < ApplicationRecord
  belongs_to :place, foreign_key: :place_name, primary_key: :name
  belongs_to :representative 

  after_destroy :destroy_representative_if_no_more_place_representatives

  private


  def destroy_representative_if_no_more_place_representatives
    if PlaceRepresentative.where(representative_id: representative_id).count.zero?
      representative.destroy
    end
  end
end
