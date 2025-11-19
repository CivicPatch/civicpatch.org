class Api::RepresentativesController < ApplicationController
  protect_from_forgery with: :null_session

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

  def search
    address = params[:address]
    if address.blank?
      render json: { error: "Address is required" }, status: :bad_request
      return
    end
    begin
      Rails.logger.info "Searching for address: #{address}"

      # Use a geocoding service to convert address to coordinates
      coordinates = geocode_address(address)

      if coordinates
        Rails.logger.info "Geocoded to coordinates: lat=#{coordinates[:lat]}, lng=#{coordinates[:lng]}"
        representatives = Representative.get_representatives_by_lat_long(coordinates[:lat], coordinates[:lng])
        Rails.logger.info "Found #{representatives.length} representatives"
        render json: { representatives: representatives, address: address }
      else
        Rails.logger.error "Unable to geocode address: #{address}"
        render json: { error: "Unable to geocode address" }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Error searching representatives: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: "An error occurred while searching: #{e.message}" }, status: :internal_server_error
    end
  end

    def address_search
    @address = params[:address]
    @representatives = []
    @searched = false

    if request.post?
      @searched = true
      if @address.blank?
        flash[:alert] = 'Address is required.'
        redirect_to address_search_path and return
      else
        begin
          Rails.logger.info "Searching for address: #{@address}"
          coordinates = GeocodingService.geocode_address(@address)
          if coordinates
            @representatives = Representative.get_representatives_by_lat_long(coordinates[:lat], coordinates[:lng])
            Rails.logger.info "Found #{@representatives.length} representatives"
            print("this is the data:", @representatives)
            redirect_to address_search_path(address: @address, searched: true, lat: coordinates[:lat], lng: coordinates[:lng]) and return
          else
            Rails.logger.error "Unable to geocode address: #{@address}"
            flash[:alert] = 'Unable to geocode address.'
            redirect_to address_search_path(address: @address, searched: true) and return
          end
        rescue => e
          Rails.logger.error "Geocoding error: #{e.message}"
          flash[:alert] = "An error occurred while geocoding: #{e.message}"
          redirect_to address_search_path(address: @address, searched: true) and return
        end
      end
    elsif params[:searched]
      @searched = true
      if @address.present?
        if params[:lat].present? && params[:lng].present?
          coordinates = { lat: params[:lat], lng: params[:lng] }
        else
          coordinates = GeocodingService.geocode_address(@address)
        end
        if coordinates
          @representatives = Representative.get_representatives_by_lat_long(coordinates[:lat], coordinates[:lng])
        end
      end
    end
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

  def geocode_address(address)
    # Simple geocoding using a free service (you can replace with Google Maps API, etc.)
    begin
      require "net/http"
      require "uri"
      require "json"

      # Using Nominatim (OpenStreetMap) - free geocoding service
      encoded_address = URI.encode_www_form_component(address)
      # Using Census Geocoding Service
      # uri = URI("https://nominatim.openstreetmap.org/search?q=#{encoded_address}&format=json&limit=1&countrycodes=us")
      uri = URI("https://geocoding.geo.census.gov/geocoder/locations/onelineaddress?address=#{encoded_address}&benchmark=4&format=json")

      puts uri


      response = Net::HTTP.get(uri)
      data = JSON.parse(response)

      if data["result"]["addressMatches"].any?
        location = data["result"]["addressMatches"].first
        {
          lat: location["coordinates"]["y"].to_f,
          lng: location["coordinates"]["x"].to_f
        }
      else
        nil
      end
    rescue => e
      Rails.logger.error "Geocoding error: #{e.message}"
      nil
    end
  end
end
