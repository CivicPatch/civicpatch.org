require "minitest/autorun"
require "minitest/pride"

require_relative "../../../lib/services/duck_duck_go"

class DuckDuckGoTest < Minitest::Test
  def setup
    @fixture_path = File.join(File.dirname(__FILE__), "fixtures", "city_council.html")
    @html_content = File.read(@fixture_path)
    @duck_duck_go = SearchService::DuckDuckGo.new("seattle washington city council")

    # Mock the HTTP request
    # stub_request(:get, "https://duckduckgo.com/?q=seattle+washington+city+council")
    #  .to_return(status: 200, body: @html_content, headers: {})
  end

  def test_clean_html_removes_navigation_elements
    result = @duck_duck_go.get_search_result_urls
  end
end
