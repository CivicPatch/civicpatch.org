
require 'net/http'
require 'uri'
require 'json'


class GeocodingService
    @@last_nominatim_request_time = nil
    # Geocode an address string to a latitude/longitude hash or nil if not found.
    # @param [String] address The address to geocode.
    # @return [Hash{Symbol => Float}, nil] Returns a hash with keys :lat and :lng as floats, or nil if not found.
    def self.geocode_address(address)
        encoded_address = URI.encode_www_form_component(address)
        census_geocoder_url = "https://geocoding.geo.census.gov/geocoder/locations/onelineaddress?address=#{encoded_address}&benchmark=4&format=json"
        uri = URI(census_geocoder_url)
        port = uri.scheme == "https" ? 443 : uri.port
        http = Net::HTTP.new(uri.host, port)
        http.use_ssl = (uri.scheme == "https")
        request = Net::HTTP::Get.new(uri)
        response = http.request(request)

        Rails.logger.info "[GEOCODING] Response code from Census Geocoder: #{response.code}"
        if response.is_a?(Net::HTTPSuccess)
            result = JSON.parse(response.body)
            matches = result.dig('result', 'addressMatches')
            Rails.logger.info "[GEOCODING] Address matches found: #{matches.size}"
            if matches && matches.any?
                coords = matches.first['coordinates']
                return {
                    lat: coords['y'].to_f,
                    lng: coords['x'].to_f
                }
            end
          # no extra end here
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
            if defined?(Rails) && Rails.logger
                Rails.logger.info "Nominatim URI: #{nominatim_uri}"
            else
                puts "Nominatim URI: #{nominatim_uri}"
            end
            nominatim_uri.query = URI.encode_www_form(nominatim_params)
            headers = {
                "User-Agent" => "civicpatch.org/1.0 (admin@civicpatch.org)",
                "Accept-Language" => "en"
            }
            # Simple rate limiting: 1 request per second
            if @@last_nominatim_request_time
                elapsed = Time.now - @@last_nominatim_request_time
                sleep(1.0 - elapsed) if elapsed < 1.0
            end
            nom_request = Net::HTTP::Get.new(nominatim_uri, headers)
            nom_response = Net::HTTP.start(nominatim_uri.host, nominatim_uri.port, use_ssl: nominatim_uri.scheme == "https") do |http|
                http.request(nom_request)
            end
            @@last_nominatim_request_time = Time.now
            Rails.logger.info "[GEOCODING] Nominatim response code: #{nom_response.code}"
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
