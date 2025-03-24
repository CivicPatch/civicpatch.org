class Api::RepresentativesController < ApplicationController
  def index
    ocd_id = params[:ocd_id]
    puts "calling index..."
    puts "ocd_id: #{ocd_id}"
    representatives = []

    if ocd_id.present?
      validate_ocd_id
      place_name = get_place(ocd_id)

      puts "place_name: #{place_name}"

      representatives = Representative.get_representatives_by_place_name(place_name)
    end

    render json: representatives
  end

  private

  def validate_ocd_id
    if params[:ocd_id].present?
      unless params[:ocd_id].match?(/^ocd-division\/country:us\/state:(\w{2})\/place:(\w+)$/)
        render json: { error: "Invalid OCD ID" }, status: :bad_request
      end
    end
  end

  def get_place(ocd_id)
    place_segment = ocd_id.split("/").last
    place_segment.split(":").last
  end
end
