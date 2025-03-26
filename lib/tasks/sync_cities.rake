namespace :sync_cities do
  desc "Sync cities from the source to the database"
  task :sync, [:state] => :environment do |t, args|
    state = args[:state]

    puts "Syncing cities for #{state}"

    # Get the cities from the source
    cities = get_cities(state)

    # Create the cities in the database
    create_cities(state, cities)
  end

  private

  def get_cities(state)
    places_yaml = Rails.root.join("data", "open-data", "us", state, "places.yml")
    places = YAML.load_file(places_yaml)["places"]
    found_places = places.select { |place| place["last_city_scrape_run"].present? }
    puts "Found cities: #{found_places.count}"

    found_places
  end
  # TODO TEMPRARRYR

  def create_cities(state, cities)
    puts "Creating #{cities.size} cities"

    Representative.destroy_all
    cities.each do |city|
      gnis_id = "0#{city["gnis"]}" # Weird -- there's a leading 0 for every gnis id
      puts "Processing city: #{city["name"]}" # Debugging output
      # Remove existing representatives
      puts "Removing existing representatives for #{city["name"]}" # Debugging output

      fips = city["fips"].split("-")
      state_code = fips[0]
      place_fp = fips[1]
      place = Place.find_by(statefp: state_code, placefp: place_fp)

      if place.nil?
        puts "Place not found for #{city["name"]} in #{state} with fips #{fips}"
        next
      end

      # Create new representatives
      city_directory_file = get_city_directory(state, city)
      puts "Loading city directory file: #{city_directory_file}"
      city_directory = YAML.load_file(city_directory_file)
      people = city_directory["people"]

      people.each do |person|
        Representative.create(
          name: person["name"],
          email: person["email"],
          phone_number: person["phone_number"],
          position: person["position"],
          website_url: person["website"],
          place: place
        )
      end
    end
  end

  def get_city_directory(state, city_entry)
    possible_city_directories = [
      Rails.root.join("data", "open-data", "us", state, city_entry["name"], "directory.yml"),
      Rails.root.join("data", "open-data", "us", state, "#{city_entry["name"]}_#{city_entry["gnis"]}", "directory.yml"),
    ]

    possible_city_directories.find { |file| File.exist?(file) }
  end
end
