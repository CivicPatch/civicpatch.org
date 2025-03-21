require "minitest/autorun"
require "webmock/minitest"
require_relative "../../lib/scrapers/crawler_test"

class SiteCrawlerTest < Minitest::Test
  def setup
    @base_url = "http://example.com"
    @keywords = [ "city council members", "city council", "council members", "council" ]
  end

  def test_site_map_is_found
    # Sort by keyword priority

    stub_request(:get, @base_url).to_return(body: <<-HTML)
      <html>
        <body>
          <a href="/sitemap">Sitemap</a>
          <a href="/city-council">City Council</a>
          <a href="/council-members">Council Members</a>
          <a href="/council">Council</a>
        </body>
      </html>
    HTML

    stub_request(:get, "#{@base_url}/sitemap").to_return(body: <<-HTML)
      <html>
        <body>
          <a href="/city-council-members">City Council Members</a>
          <a href="/city-council">City Council</a>
          <a href="/council-members">Council Members</a>
          <a href="/council">Council</a>
        </body>
      </html>
    HTML

    sorted_urls = Scrapers::SiteCrawler.get_urls(@base_url, @keywords)

    expected_urls = [
      [ "#{@base_url}/city-council-members", "City Council Members" ],
      [ "#{@base_url}/city-council", "City Council" ],
      [ "#{@base_url}/council-members", "Council Members" ],
      [ "#{@base_url}/council", "Council" ]
    ]

    assert_equal expected_urls, sorted_urls
  end

  def test_no_external_urls_are_visited
    stub_request(:get, @base_url).to_return(body: <<-HTML)
      <html>
        <body>
          <a href="/sitemap">Sitemap</a>
          <a href="http://external.com">External</a>
        </body>
      </html>
    HTML

    stub_request(:get, "#{@base_url}/sitemap").to_return(body: <<-HTML)
      <html>
        <body>
          <a href="/city-council-members">City Council Members</a>
        </body>
      </html>
    HTML

    # This will raise an error if any request is made to a URL not stubbed
    assert_raises(WebMock::NetConnectNotAllowedError) do
      Scrapers::SiteCrawler.get_urls(@base_url, @keywords)
    end
  end
end
