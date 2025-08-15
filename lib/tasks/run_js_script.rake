namespace :data do
  desc "Run the JavaScript data processing script"
  task :process => :environment do
    js_file = Rails.root.join("lib/tasks/process_data.js")
    puts "Running JS script at: #{js_file}"

    result = `node #{js_file}`
    puts result
  end
end
