namespace :sync_map do
  desc "Sync map data from the source to the database"
  task :sync, [ :type, :state ] => :environment do |t, args|
    type = args[:type] # can be place or cd
    state = args[:state]

    # map of statename to statefp
    state_map = {
      "wa" => "53",
      "or" => "41"
    }

    shapefile_path = Rails.root.join(
      "data", "open-data", state, ".maps",
      "#{type}_2024/tl_2024_#{state_map[state]}_#{type}.shp")

    puts "Importing for #{state} from #{shapefile_path}"

    sh "#{File.expand_path('../scripts/sync_map.sh', __FILE__)} #{shapefile_path} #{type}"
  end
end
