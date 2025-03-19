# utility functions
def city_data_dir(state, city)
  Rails.root.join("data", state, city)
end
