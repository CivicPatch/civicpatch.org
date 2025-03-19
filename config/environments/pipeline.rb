# use production settings
require File.expand_path("../production.rb", __FILE__)

Rails.application.configure do
  # override production settings
  config.serve_static_files = true
end
