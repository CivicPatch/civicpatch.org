class DashboardController < ApplicationController
  def index
    # Set up default panel variables for the dashboard layout
    @panel = 'home'
    @address = nil
    @representatives = nil
    @searched = false
  end

  def panel
    @panel = params[:panel]
    case @panel
    when 'home'
      # No special setup needed
    when 'progress_map'
      # No special setup needed
    when 'address_search'
      @address = params[:address]
      @searched = false
      @representatives = nil
      if request.post? && @address.present?
        @searched = true
        begin
          geo_result = GeocodingService.geocode_address(@address)
          if geo_result && geo_result[:lat] && geo_result[:lng]
            @representatives = Representative.get_representatives_by_lat_long(geo_result[:lat], geo_result[:lng])
          else
            @representatives = []
          end
        rescue => e
          Rails.logger.error("Geocoding error: #{e.message}")
          @representatives = []
        end
      end
      if turbo_frame_request?
        render partial: 'dashboard/address_search', locals: { address: @address, representatives: @representatives, searched: @searched }
      else
        redirect_to dashboard_panel_path(panel: 'address_search', address: @address)
      end
      return
    else
      # fallback
      @panel = 'home'
    end
    respond_to do |format|
      format.html { render :index }
    end
  end
end