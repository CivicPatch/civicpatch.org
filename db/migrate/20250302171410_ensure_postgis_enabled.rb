class EnsurePostgisEnabled < ActiveRecord::Migration[8.0]
  def up
    enable_extension "fuzzystrmatch"
    enable_extension "postgis"
    enable_extension "tiger.postgis_tiger_geocoder"
    enable_extension "topology.postgis_topology"
  end

  def down
    disable_extension "fuzzystrmatch"
    disable_extension "postgis"
    disable_extension "tiger.postgis_tiger_geocoder"
    disable_extension "topology.postgis_topology"
  end
end
