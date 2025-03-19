require "test_helper"

class DataFetcherTest < Minitest::Test
  def setup
    @test_url = "https://www.seattle.gov/council/meet-the-council"
    @data_fetcher = DataFetcher.new
  end

  def test_extract_html_fetches_and_saves_html_example_1
    fixtures_dir = "test/fixtures/wa/seattle"
    destination_dir = "test/fixtures/tmp/wa/seattle"
    FileUtils.mkdir_p(destination_dir)
    html_content = File.read(Rails.root.join("#{fixtures_dir}/city_council_members.html"))

    # mock the fetch_with_client method
    @data_fetcher.stub(:fetch_with_client, html_content) do
      @data_fetcher.extract_html(@test_url, destination_dir)
    end

    assert File.exist?(Rails.root.join("#{destination_dir}/step_1_original_html.html"))
    assert File.exist?(Rails.root.join("#{destination_dir}/step_2_cleaned_html.html"))
    assert File.exist?(Rails.root.join("#{destination_dir}/step_3_markdown_content.md"))

    # assert step 2 and step 3 in the destination directory are the same as the fixtures
    assert_equal File.read(Rails.root.join("#{fixtures_dir}/step_2_cleaned_html.html")), File.read(Rails.root.join("#{destination_dir}/step_2_cleaned_html.html"))
    assert_equal File.read(Rails.root.join("#{fixtures_dir}/step_3_markdown_content.md")), File.read(Rails.root.join("#{destination_dir}/step_3_markdown_content.md"))
  end
end
