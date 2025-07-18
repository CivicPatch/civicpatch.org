namespace :maps do
  desc "Sync map data from the source to the database"
  task sync: :environment do |t, args|
    # Get all .maps folders under data/open-adata

    states = Dir.glob(Rails.root.join("data", "open-data", "*", ".maps")).map do |path|
      File.basename(File.dirname(path))
    end

    states.each do |state|
      puts "Syncing map data for state: #{state}"
      sync_map_data(state)
    end
  end
end

def self.sync_map_data(state)
  geojson_path = Rails.root.join(
    "data", "open-data", state, ".maps",
    "municipalities.geojson"
  )

  puts "Importing for #{state} from #{geojson_path}"

  sh "#{File.expand_path('../scripts/sync_map.sh', __FILE__)} #{geojson_path}"

  # Update OCD IDs from municipalities.json
  json_path = Rails.root.join('data', 'open-data', state, 'municipalities.json')
  municipalities_data = JSON.parse(File.read(json_path))

  # Create a lookup hash by geoid
  municipalities_by_geoid = municipalities_data['municipalities'].index_by { |m| m['geoid'] }

  # Update each municipality in the database
  Municipality.where(state: state).find_each do |municipality|
    if json_data = municipalities_by_geoid[municipality.geoid]
      # Update ocd_ids if they exist in the JSON
      if json_data['ocd_ids'].present?
        municipality.update(ocd_ids: json_data['ocd_ids'])
        puts "Updated #{municipality.name} (#{municipality.geoid}) with OCD IDs: #{json_data['ocd_ids'].join(', ')}"
      end
    else
      puts "Warning: No matching JSON data found for #{municipality.name} (#{municipality.geoid})"
    end
  end
end 
