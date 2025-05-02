class MapController < ApplicationController
  def index
  end

  def details
    @statefp = params[:statefp]
    @geoid = params[:geoid]

    # If required parameters are missing, prepare an empty list
    if @statefp.blank? || @geoid.blank?
      @representatives = []
    else
      # Otherwise, fetch the representatives
      @representatives = Representative.get_representatives_by_statefp_geoid(@statefp, @geoid)
    end

    # Render the partial (will be empty if @representatives is [])
    render partial: "representatives/list", formats: [ :html ]
  end

  def lat_long
    @statefp = params[:statefp]
    @geoid = params[:geoid]
    # Select the centroid coordinates (transforming to WGS84 first)
    @place = Place.where(statefp: @statefp, geoid: @geoid)
                  .select(
                    "ST_Y(ST_Centroid(ST_Transform(geom, 4326))) AS latitude",
                    "ST_X(ST_Centroid(ST_Transform(geom, 4326))) AS longitude"
                  )
                  .first # Use first since we expect one result and select doesn't return a single record

    if @place
      render json: {
        lat: @place.latitude,
        long: @place.longitude
      }
    else
      render json: { error: "Place not found" }, status: :not_found
    end
  end

  def municipality_boundaries
    # Expecting bounds parameters: sw_lat, sw_lng, ne_lat, ne_lng
    sw_lat = params[:sw_lat]
    sw_lng = params[:sw_lng]
    ne_lat = params[:ne_lat]
    ne_lng = params[:ne_lng]
    tolerance = 0.0005

    # Validate parameters
    if [ sw_lat, sw_lng, ne_lat, ne_lng ].any?(&:blank?)
      return render json: { error: "Missing boundary parameters (sw_lat, sw_lng, ne_lat, ne_lng)" }, status: :bad_request
    end

    # Create a bounding box geometry from the parameters (using SRID 4326 - WGS84)
    # Note: ST_MakeEnvelope format is (xmin, ymin, xmax, ymax) -> (lng_min, lat_min, lng_max, lat_max)
    bbox_4326 = "ST_MakeEnvelope(#{sw_lng}, #{sw_lat}, #{ne_lng}, #{ne_lat}, 4326)"

    # Find places whose geometry intersects the bounding box
    # No CDPs -- not municipalities in our case
    places_in_view = Place.where("geom && ST_Transform(#{bbox_4326}, 4269)")
                          .where.not("namelsad LIKE ?", "% CDP")
                          .select(
                            "gid, name, statefp, geoid, " \
                            "ST_AsGeoJSON(" \
                              "ST_Transform(" \
                                "ST_SimplifyPreserveTopology(geom, #{tolerance})" \
                              ", 4326)" \
                            ") as geojson"
                          )

    features = places_in_view.map do |place|
      next unless place.geojson
      {
        type: "Feature",
        id: place.gid,
        properties: { name: place.name, statefp: place.statefp, geoid: place.geoid },
        geometry: JSON.parse(place.geojson)
      }
    end.compact

    render json: {
      type: "FeatureCollection",
      features: features
    }
  end

  # New action to handle map clicks
  def locate
    lat = params[:lat].to_f
    lng = params[:lng].to_f

    # Basic validation
    if lat.nil? || lng.nil? || !lat.between?(-90, 90) || !lng.between?(-180, 180)
      return render json: { error: "Invalid latitude or longitude" }, status: :bad_request
    end

    # Create a point geometry in WGS84 (SRID 4326)
    # Note: ST_MakePoint expects longitude, latitude
    point_4326_sql = "ST_SetSRID(ST_MakePoint(#{lng}, #{lat}), 4326)"

    # Transform the point to the native SRID of the geom column (assuming 4269)
    point_native_srid_sql = "ST_Transform(#{point_4326_sql}, 4269)"

    # 1. Check if the point is strictly inside a Place
    # Exclude CDPs as before
    inside_place = Place.where("ST_Contains(geom, #{point_native_srid_sql})")
                        .where.not("namelsad LIKE ?", "% CDP")
                        .select(:gid, :name, :statefp, :geoid)
                        .first

    if inside_place
      return render json: { status: "inside", place: inside_place.attributes }
    end

    # 2. If not inside, check if it's very close to a boundary
    tolerance_degrees = 0.0001 # Approx 10-11 meters, adjust as needed
    boundary_place = Place.where("ST_DWithin(ST_Transform(geom, 4326), #{point_4326_sql}, #{tolerance_degrees})")
                          .where.not("namelsad LIKE ?", "% CDP")
                          .select(:gid, :name, :statefp, :geoid, "ST_Distance(ST_Transform(geom, 4326), #{point_4326_sql}) as distance")
                          .order("distance ASC") # Find the closest boundary
                          .first

    if boundary_place
      # Exclude the calculated distance from the returned attributes
      place_attributes = boundary_place.attributes.except("distance")
      return render json: { status: "boundary", place: place_attributes }
    end

    # 3. If neither inside nor near a boundary, it's outside
    render json: { status: "outside" }

  rescue ArgumentError => e
    render json: { error: "Invalid input parameter: #{e.message}" }, status: :bad_request
  rescue => e # Catch potential SQL or other errors
    Rails.logger.error "Error in MapController#locate: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: "An unexpected error occurred" }, status: :internal_server_error
  end
end
