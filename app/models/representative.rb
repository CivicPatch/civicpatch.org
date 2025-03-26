class Representative < ApplicationRecord
  belongs_to :place

  def self.get_representatives_by_ocd_id(ocd_id)
    state, county, place = get_ocd_id_parts(ocd_id)
    state_code = state_to_state_code(state)

    puts "State code: #{state_code}"
    puts "Place: #{place}"

    place = Place.find_by(name: format_name(place), statefp: state_to_state_code(state))

    # TODO: Handle county
    place.representatives
  end

  def self.get_ocd_id_parts(ocd_id)
    parts = ocd_id.split("/")

    if parts.count == 4
      state = parts[2].split(":").last
      place = parts[3].split(":").last
      puts "State: #{state}, Place: #{place}"
      [state, nil, place.capitalize]
    else
      state = parts[2].split(":").last
      county = parts[3].split(":").last
      place = parts[4].split(":").last
      puts "State: #{state}, County: #{county}, Place: #{place}"
      [state, county.capitalize, place.capitalize]
    end
  end

  def self.format_name(name)
    name.gsub("_", " ").split(" ").map(&:capitalize).join(" ")
  end

  def self.state_to_state_code(state)
    case state
    when "mi"
      "26"
    when "wa"
      "53"
    end
  end
end
