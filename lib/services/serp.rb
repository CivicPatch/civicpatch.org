module SearchService
  class Serp
    def self.get_search_result_urls(query, with_site = "", discard_urls_with_partial = [])
      formatted_query = URI.encode_www_form_component(query)

      if with_site.present?
        formatted_query = "#{formatted_query} site:#{with_site}"
      end

      if discard_urls_with_partial.present?
        formatted_query = "#{formatted_query} -#{discard_urls_with_partial.join(' -')}"
      end

      results = HTTParty.get(
        "https://serpapi.com/search?q=#{formatted_query}&api_key=#{Rails.application.credentials.serp_token}"
      )

      results_content = JSON.parse(results.body)

      results_content["organic_results"].map { |result| format_url(result["link"]) }
    end

    def self.format_url(url)
      url.gsub(" ", "%20")
    end
  end
end
