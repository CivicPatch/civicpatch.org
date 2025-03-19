
=begin
bundle exec ruby test/lib/services/openai_test.rb
=end
require_relative "../../../test/test_helper"
require_relative "../../../lib/services/openai"

class OpenAITest < Minitest::Test
  def setup
    @openai_service = AI::OpenAI.new

    @fixtures = {
      "seattle_wa" => { url: "https://www.seattle.gov/council/meet-the-council",
      file: "seattle_wa/city_council.html", num_council_members: 9 },
      # "tuscaloosa_al" => { url: "https://www.tuscaloosa.com/city-council", file: "tuscaloosa_al/city_council.html" },
      "san_jose_ca" => {
        url: "https://www.sanjoseca.gov/city-council",
        file: "san_jose_ca/city_council.html", num_council_members: 11 },
      "ny_ny" => { url: "https://www.nyc.gov/council", file: "ny_ny/city_council.html", num_council_members: 51 }
    }

    @fixtures.each do |fixture, url|
      stub_request(:get, url[:url])
        .to_return(status: 200, body: File.read("test/fixtures/#{url[:file]}"))
    end
  end

  # for each of the fixtures, test that the page is cleaned
  def test_city_council_page_is_cleaned
    @fixtures.each do |fixture, url|
      yaml = @openai_service.parse_city_council_page(url[:url])
      # save to file
      File.write("test/fixtures/#{fixture}/city_council_TMP.yml", yaml)
      assert_equal(yaml, File.read("test/fixtures/#{fixture}/city_council.yml"))
      # cleaned_html = @openai_service.parse_city_council_page(url[:url])
      # save to file
      # File.write("test/fixtures/#{fixture}/city_council_cleaned.md", cleaned_html)
      # assert_equal(cleaned_html, File.read(File.join(File.dirname(__FILE__), 'fixtures', "#{fixture}_cleaned.html")))
    end
  end
end
