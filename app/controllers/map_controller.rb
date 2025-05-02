class MapController < ApplicationController
  def index
  end

  def details
    @statefp = params[:statefp]
    @geoid = params[:geoid]
    @representatives = Representative.get_representatives_by_statefp_geoid(@statefp, @geoid)
    render partial: "representatives/list", formats: [ :html ]
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
end
