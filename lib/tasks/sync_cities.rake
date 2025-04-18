namespace :sync_cities do
  desc "Sync cities from the source to the database"
  task :sync, [ :state ] => :environment do |t, args|
    state = args[:state]

    puts "Syncing cities for #{state}"
    # Get the sync config for the state
    city_syncs = CitySync.all

    # Get the cities not present in the sync statuses
    cities = get_cities(state, city_syncs)
    create_cities(state, cities)
  end

  private

  def get_cities(state, city_syncs)
    places_yaml = Rails.root.join("data", "open-data", state, "places.json")
    places = JSON.parse(File.read(places_yaml))["places"]
    
    found_places = places.select { |place|
      place["gnis"].present? &&
        place["meta_hash"].present? &&
        place["fips"].present? &&
        # meta_hash is not present in the sync statuses
        !city_syncs.map(&:meta_hash).include?(place["meta_hash"])
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
        state: state,
        city_name: city["name"],
        meta_hash: city["meta_hash"],
        gnis: city["gnis"],
      )
    end
  end



  def get_city_directory(state, city_entry)
    possible_city_directories = [
      Rails.root.join("data", "open-data", state, city_entry["name"], "people.yml"),
      Rails.root.join("data", "open-data", state, "#{city_entry["name"]}_#{city_entry["gnis"]}", "people.yml")
    ]

    possible_city_directories.find { |file| File.exist?(file) }
  end
end
