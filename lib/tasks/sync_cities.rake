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
    places_yaml = Rails.root.join("data", "open-data", "data", "us", state, "places.yml")
    places = YAML.load_file(places_yaml)["places"]
    found_places = places.select { |place| place["last_city_scrape_run"].present? }.map{ |place| place["place"] }
    puts "Found cities: #{found_places}"

    found_places
  end

  def create_cities(state, cities)
    puts "Creating #{cities.size} cities"

    cities.each do |city_name|
      # Remove existing representatives
      PlaceRepresentative.where(place_name: city_name).destroy_all

      # Create new representatives
      city_directory_file = Rails.root.join(
        "data", 
        "open-data", 
        "data", 
        "us", 
        state, 
        city_name, 
        "directory.yml")
      puts "Loading city directory file: #{city_directory_file}"
      city_directory = YAML.load_file(city_directory_file)
      people = city_directory["people"]

      people.each do |person|
        representative = Representative.create(
          name: person["name"],
          email: person["email"],
          phone_number: person["phone_number"],
          position: person["position"],
          website_url: person["website"],
        )
        PlaceRepresentative.create(
          place_name: city_name,
          representative_id: representative.id,
        )
      end
    end
  end
end
