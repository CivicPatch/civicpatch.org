require "fileutils"
require "open3"
require "yaml"

# Run rake task:
# bin/rake public:build_static

namespace :public do
  desc "Clone city data repo and generate static HTML files"
  task build_static: :environment do
    repo_url     = "https://github.com/CivicPatch/open-data.git"
    tmp_dir      = Rails.root.join("tmp", "open-data")
    output_root  = Rails.root.join("public", "open-data")

    ##
    # 1. Cleanup and clone
    ##
    FileUtils.rm_rf(tmp_dir)
    FileUtils.mkdir_p(tmp_dir)

    puts "Cloning #{repo_url}..."
    stdout, stderr, status = Open3.capture3("git clone --depth=1 #{repo_url} #{tmp_dir}")

    unless status.success?
      puts "Git clone failed:"
      puts stderr
      exit(1)
    end

    puts "Clone complete."

    ##
    # 2. Process states inside data/
    ##
    data_dir = tmp_dir.join("data")
    unless Dir.exist?(data_dir)
      puts "ERROR: No data/ directory found in repo."
      exit(1)
    end

    Dir.glob(data_dir.join("*")).each do |state_path|
      next unless File.directory?(state_path)

      state = File.basename(state_path)
      puts "Processing state: #{state}"

      state_yaml_files = Dir.glob(File.join(state_path, "*.yml"))

      ##
      # 3. For each locality (each .yml file)
      ##
      state_yaml_files.each do |yaml_file|
        locality_data = YAML.load_file(yaml_file)
        locality_name = File.basename(yaml_file, ".yml")
        locality_slug = locality_name.parameterize

        # Output directory
        state_output_dir = output_root.join(state)
        FileUtils.mkdir_p(state_output_dir)

        output_file_path = state_output_dir.join("#{locality_slug}.html")

        html = ApplicationController.renderer.render(
          template: "static-open-data/show",
          locals: { city_name: locality_name, people: locality_data }
        )

        File.write(output_file_path, html)
        puts "Generated: #{output_file_path}"
      end
    end

    ##
    # 5. Cleanup temporary repo
    ##
    FileUtils.rm_rf(tmp_dir)
    puts "All static pages generated."
  end
end
