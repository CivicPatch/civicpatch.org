require "httparty"
require "nokogiri"
require "uri"

module SearchService
  class DuckDuckGo
    def self.get_search_result_urls(query, with_site = "", discard_urls_with_partial = [])
      formatted_query = URI.encode_www_form_component(query)

      if with_site.present?
        formatted_query = "#{formatted_query} site:#{with_site}"
      end

      if discard_urls_with_partial.present?
        formatted_query = "#{formatted_query} -#{discard_urls_with_partial.join(' -')}"
      end

      puts "Formatted query = #{formatted_query}"

      results = HTTParty.get("https://html.duckduckgo.com/html?q=#{formatted_query}&format=json")
      puts "Results = #{results.body}"
      results_content = results.body

      format_search_results(results_content)
    end

    private

    def self.format_search_results(html_content)
      doc = Nokogiri::HTML(html_content)
      doc.css(".result__a").map do |link|
        # strip prefix //duckduckgo.com/l/?uddg=
        # and remove trailing suffix that starts with &rut
        decoded_link = URI.decode_www_form_component(link["href"])
        raw_link = decoded_link.gsub("//duckduckgo.com/l/?uddg=", "").gsub(/&rut=.*$/, "")
        URI.parse(raw_link).to_s
      end
    end
  end
end
