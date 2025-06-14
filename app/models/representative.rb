class Representative < ApplicationRecord
  belongs_to :municipality

  def self.get_representatives_by_ocd_id(ocd_id)
    state, county, place = get_ocd_id_parts(ocd_id)
    state_code = state_to_state_code(state)

    puts "State code: #{state_code}"
    puts "Municipality: #{place}"

    municipality = Municipality.find_by_state_and_geoid(state, place)

    # TODO: Handle county
    Representative.where(municipality: municipality).map(&:data)
  end

  def self.get_representatives_by_state_geoid(state, geoid)
    puts "State: #{state}, Geoid: #{geoid}"
    municipality = Municipality.find_by_state_and_geoid(state, geoid)

    return [] if municipality.nil?

    Representative.where(municipality: municipality).map(&:data)
  end

  def self.get_representatives_by_lat_long(lat, long)
    lat_float = lat.to_f
    long_float = long.to_f
    municipalities = Municipality.find_by_lat_lon(lat_float, long_float)

    if municipalities.empty?
      return []
    end

    # Get all representatives for all municipalities in one query
    Representative.where(municipality_id: municipalities.pluck(:geoid)).map(&:data)
  end

  def self.get_ocd_id_parts(ocd_id)
    parts = ocd_id.split("/")

    if parts.count == 4
      state = parts[2].split(":").last
      place = parts[3].split(":").last
      puts "State: #{state}, Place: #{place}"
      [ state, nil, place.capitalize ]
    else
      state = parts[2].split(":").last
      county = parts[3].split(":").last
      place = parts[4].split(":").last
      puts "State: #{state}, County: #{county}, Place: #{place}"
      [ state, county.capitalize, place.capitalize ]
    end
  end

  def self.format_name(name)
    name.gsub("_", " ").split(" ").map(&:capitalize).join(" ")
  end

  def self.to_person(open_data_person)
    contact_details = []
    links = []
    sources = []

    person = {
      "name" => open_data_person["name"],
      "image" => open_data_person["cdn_image"],
      "links" => links
    }

    person["other_names"] = open_data_person["roles"]&.map do |role|
      {
        "name" => role
      }
    end

    if open_data_person["email"].present?
      contact_details << {
        "type" => "email",
        "value" => open_data_person["email"],
        "label" => "Email"
      }
    end

    if open_data_person["phone_number"].present?
      contact_details << {
        "type": "phone",
        "value": open_data_person["phone_number"],
        "label": "Phone"
      }
    end

    if open_data_person["website"].present?
      links << {
        "note": "Website",
        "url": open_data_person["website"]
      }
    end

    if open_data_person["sources"].present?
      open_data_person["sources"].each do |source|
        sources << {
          "url": source
        }
      end
    end

    person["contact_details"] = contact_details
    person["links"] = links
    person["sources"] = sources

    person
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
