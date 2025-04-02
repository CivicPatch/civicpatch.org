namespace :sync_cities do
  desc "Sync cities from the source to the database"
  task :sync, [ :state ] => :environment do |t, args|
    state = args[:state]

    puts "Syncing cities for #{state}"
    # Get the sync config for the state
    sync_statuses = {} # Object of hash key to gnis id, fips, and city name
    sync_statuses_file_path = Rails.root.join("lib", "tasks", "syncs", "#{state}.yml")
    sync_statuses = YAML.load_file(sync_statuses_file_path) if File.exist?(sync_statuses_file_path)

    # Get the cities not present in the sync statuses
    cities = get_cities(state, sync_statuses)

    # Create the cities in the database
    create_cities(state, cities)

    # Update the sync statuses
    cities.each do |city|
      sync_statuses[city["gnis"]] = { 
        "gnis" => city["gnis"], 
        "fips" => city["fips"], 
        "city_name" => city["name"], 
        "meta_hash" => city["meta_hash"] }
    end
    File.write(sync_statuses_file_path, sync_statuses.to_yaml)
  end

  private

  def get_cities(state, sync_statuses)
    places_yaml = Rails.root.join("data", "open-data", state, "places.yml")
    places = YAML.load_file(places_yaml)["places"]
    found_places = places.select { |place|
      place["gnis"].present? && 
        place["meta_hash"].present? && 
        place["fips"].present? &&
        # meta_hash is not present in the sync statuses
        !sync_statuses.values.map { |status| status["meta_hash"] }.include?(place["meta_hash"])
    }
    puts "Found cities: #{found_places.count}"

    found_places
  end

  def create_cities(state, cities)
    puts "Creating #{cities.size} cities"

    cities.each do |city|
      gnis_id = "0#{city["gnis"]}" # Weird -- there's a leading 0 for every gnis id
      puts "Processing city: #{city["name"]}" # Debugging output
      ## Remove existing representatives
      puts "Removing existing representatives for #{city["name"]}" # Debugging output

      fips = city["fips"].split("-")
      state_code = fips[0]
      place_fp = fips[1]
      place = Place.find_by(statefp: state_code, placefp: place_fp)

      if place.nil?
        puts "Place not found for #{city["name"]} in #{state} with fips #{fips}"
        next
      end

      Representative.where(place: place).destroy_all

      ## Create new representatives
      city_directory_file = get_city_directory(state, city)
      puts "Loading city directory file: #{city_directory_file}"
      city_directory = YAML.load_file(city_directory_file)
      people = city_directory["people"]

      puts "People: #{people.size}"

      people.each do |person|
        #puts "Creating representative for #{person["name"]}"
        #puts "Person: #{person}"
        Representative.create(
          name: person["name"],
          data: person,
          place: place
        )
      end
    end
  end

    

  def get_city_directory(state, city_entry)
    possible_city_directories = [
      Rails.root.join("data", "open-data", state, city_entry["name"], "directory.yml"),
      Rails.root.join("data", "open-data", state, "#{city_entry["name"]}_#{city_entry["gnis"]}", "directory.yml")
    ]

    possible_city_directories.find { |file| File.exist?(file) }
  end
end
