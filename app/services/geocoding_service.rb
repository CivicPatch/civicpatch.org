
require 'net/http'
require 'uri'
require 'json'


class GeocodingService
    # Geocode an address string to a latitude/longitude hash or nil if not found.
    # @param [String] address The address to geocode.
    # @return [Hash{Symbol => Float}, nil] Returns a hash with keys :lat and :lng as floats, or nil if not found.
    def self.geocode_address(address)
        encoded_address = URI.encode_www_form_component(address)
        census_geocoder_url = "https://geocoding.geo.census.gov/geocoder/locations/onelineaddress?address=#{encoded_address}&benchmark=4&format=json"
        uri = URI(census_geocoder_url)
        response = Net::HTTP.get_response(uri)
        result = JSON.parse(response.body)
        matches = result.dig('result', 'addressMatches')
        if matches && matches.any?
            coords = matches.first['coordinates']
            return {
                lat: coords['y'].to_f,
                lng: coords['x'].to_f
            }
        end
        begin
            nominatim_url = "https://nominatim.openstreetmap.org/search"
            nominatim_params = {
                q: address,
                format: 'json',
                limit: 1,
                countrycodes: 'us'
            }
            nominatim_uri = URI(nominatim_url)
            nominatim_uri.query = URI.encode_www_form(nominatim_params)
            nom_response = Net::HTTP.get_response(nominatim_uri)
            if nom_response.is_a?(Net::HTTPSuccess)
                nom_data = JSON.parse(nom_response.body)
                if nom_data.any?
                    loc = nom_data.first
                    return {
                        lat: loc['lat'].to_f,
                        lng: loc['lon'].to_f
                    }
                end
            end
        rescue => e
            if defined?(Rails) && Rails.logger
                Rails.logger.error "Nominatim fallback error: #{e.message}"
            else
                warn "Nominatim fallback error: #{e.message}"
            end
        end
        nil
    end
end
