class MapController < ApplicationController
  def index
  end

  def details
    @representatives = Representative.get_representatives_by_lat_long(params[:lat], params[:long])
    render partial: "representatives/list", formats: [:html]
  end
end
