class Api::RepresentativesController < ApplicationController
  def index
    ocd_id = params[:ocd_id]
    representatives = []

    if ocd_id.present?
      validate_ocd_id

      representatives = Representative.get_representatives_by_ocd_id(ocd_id)
    elsif params[:lat].present? && params[:long].present?
      representatives = Representative.get_representatives_by_lat_long(params[:lat], params[:long])
    end

    render json: representatives
  end

  private

  def validate_ocd_id
    if params[:ocd_id].present?
      unless valid_ocd_id?(params[:ocd_id])
        render json: { error: "Invalid OCD ID" }, status: :bad_request
      end
    end
  end

  def valid_ocd_id?(ocd_id)
    # Define regex patterns for OCD ID formats
    state_place_pattern = /^ocd-division\/country:us\/state:(?<state>\w{2})\/place:(?<place>\w+)$/
    county_place_pattern = /^ocd-division\/country:us\/state:(?<state>\w{2})\/county:(?<county>\w+)\/place:(?<place>\w+)$/

    # Check if the OCD ID matches either pattern
    ocd_id.match?(state_place_pattern) || ocd_id.match?(county_place_pattern)
  end
end
