namespace :od do
  desc "Clone a specific folder from the CivicPatch/open-data repository via SSH"
  task sync: :environment do
    repo_url = "git@github.com:CivicPatch/open-data.git" # SSH URL of the repository
    folder_name = "data" # The folder you want to clone (replace with actual folder name)
    destination = Rails.root.join("data", "open-data") # Where to copy the folder (replace with actual path)

    # Create a temporary directory for cloning
    temp_dir = "tmp/updated-data"
    FileUtils.mkdir_p(temp_dir)

    # Clone the repository
    puts "Cloning repository #{repo_url}..."
    system("git clone #{repo_url} #{temp_dir}")

    # Remove existing data/open-data files
    FileUtils.rm_rf(destination)

    # Create the destination directory if it doesn't exist
    FileUtils.mkdir_p(destination)

    # Copy the specified folder to the destination
    puts "Copying #{folder_name} to #{destination}..."
    FileUtils.cp_r("#{temp_dir}/#{folder_name}/.", destination)

    # Copy the data_source/<state>/municipalities.json file to the destination
    municipalities_files = Dir.glob("#{temp_dir}/data_source/*/municipalities.json")
    municipalities_files.each do |municipalities_file|
      state = municipalities_file.split("/").last(2).first
      puts "Copying #{municipalities_file} to #{destination}/#{state}/municipalities.json"
      FileUtils.cp_r(municipalities_file, "#{destination}/#{state}/municipalities.json")
    end

    puts "Successfully cloned #{folder_name} to #{destination}."

    # Copy over data_source/<state>/places.json to data/open-data/<state>/places.json
    # Grab list of available places.json files
    places_files = Dir.glob("#{temp_dir}/data_source/*/places.json")
    places_files.each do |places_file|
      state = places_file.split("/").last(2).first
      puts "Copying #{places_file} to #{destination}/#{state}/places.json"
      FileUtils.cp_r(places_file, "#{destination}/#{state}/places.json")
    end

    # Clean up the temporary directory
    FileUtils.rm_rf(temp_dir)
  end
end
