namespace :od do
  desc "Clone a specific folder from the CivicPatch/open-data repository via SSH"
  task :sync do
    repo_url = "git@github.com:CivicPatch/open-data.git" # SSH URL of the repository
    folder_name = "data" # The folder you want to clone (replace with actual folder name)
    destination = Rails.root.join("data", "open-data") # Where to copy the folder (replace with actual path)

    # Create a temporary directory for cloning
    temp_dir = "tmp/updated-data"
    FileUtils.mkdir_p(temp_dir)

    # Clone the repository
    puts "Cloning repository #{repo_url}..."
    system("git clone #{repo_url} #{temp_dir}")

    # Check if the folder exists in the cloned repository
    if Dir.exist?("#{temp_dir}/#{folder_name}")
      # Create the destination directory if it doesn't exist
      FileUtils.mkdir_p(destination)

      # Copy the specified folder to the destination
      puts "Copying #{folder_name} to #{destination}..."
      FileUtils.cp_r("#{temp_dir}/#{folder_name}/.", destination)

      puts "Successfully cloned #{folder_name} to #{destination}."
    else
      puts "Folder #{folder_name} does not exist in the repository."
    end

    # Clean up the temporary directory
    FileUtils.rm_rf(temp_dir)
  end
end
