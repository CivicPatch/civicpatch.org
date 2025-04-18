namespace :sync_cities do
  desc "Sync cities from the source to the database"
  task sync: :environment do
    # Get the sync config for the state
    city_syncs = CitySync.all

    # Get the cities not present in the sync statuses
    cities_to_sync = get_cities(city_syncs)
    create_cities(cities_to_sync)
  end

  private

  def get_cities(city_syncs)
    # Return array of hash of meta_hash => [state, place]
    city_sync_hashes = city_syncs.map(&:meta_hash)

    cities_to_sync = []
    places_files = Dir.glob(Rails.root.join("data", "open-data", "**", "places.json"))
    places_files.each do |places_file|
      state = places_file.split("/").last(2).first
      places = JSON.parse(File.read(places_file))["places"]
      places.each do |place|
        next if place["meta_hash"].blank? || city_sync_hashes.include?(place["meta_hash"])
        cities_to_sync << {
          "state" => state,
          **place
        }
      end
    end

    cities_to_sync
  end

  def create_cities(cities)
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
      state = city["state"]
      city_directory_file = get_city_directory(state, city)
      puts "Loading city directory file: #{city_directory_file}"
      city_directory = YAML.load_file(city_directory_file)
      people = city_directory

      puts "People: #{people.size}"

      people.each do |person|
        # puts "Creating representative for #{person["name"]}"
        # puts "Person: #{person}"
        Representative.create(
          name: person["name"],
          data: person,
          place: place
        )
      end

      CitySync.create(
        state: state, # Filled out in get_cities
        city_name: city["name"],
        meta_hash: city["meta_hash"],
        gnis: city["gnis"],
      )
    end
  end



  def get_city_directory(state, city_entry)
    puts "Getting city directory for #{city_entry} in #{state}"
    possible_city_directories = [
      Rails.root.join("data", "open-data", state, city_entry["name"], "people.yml"),
      Rails.root.join("data", "open-data", state, "#{city_entry["name"]}_#{city_entry["gnis"]}", "people.yml")
    ]

    possible_city_directories.find { |file| File.exist?(file) }
  end
end
