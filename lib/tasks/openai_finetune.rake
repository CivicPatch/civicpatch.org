namespace :openai_finetune do
  desc "Finetune the OpenAI model"
  task :extract_city_info do
      service = Service::OpenAIService.new

    # "seattle_wa" => { key: "seattle_wa", url: "https://www.seattle.gov/council/meet-the-council" },
    # "ny_ny" => { key: "ny_ny", url: "https://council.nyc.gov/districts/" },
    # "boston_ma" => { key: "boston_ma", url: "https://www.boston.gov/departments/city-council" },
    # "chicago_il" => { key: "chicago_il", url: "https://chicago.councilmatic.org/council-members/" },
    # "st_petersburg_fl" => { key: "st_petersburg_fl", url: "https://www.stpete.org/government/mayor___city_council/city_council/index.php" },
    # "corpus_christi_tx" => { key: "corpus_christi_tx", url: "https://www.corpuschristitx.gov/our-government/mayor-and-council/council-members/" },
    # "austin_tx" => { key: "austin_tx", url: "https://www.austintexas.gov/austin-city-council" },
    # "elizabeth_nj" => { key: "elizabeth_nj", url: "https://www.elizabethnj.org/215/City-Council" },
    # "sacramento_ca" => { key: "sacramento_ca", url: "https://www.cityofsacramento.gov/mayor-council" },
    # "albuquerque_nm" => { key: "albuquerque_nm", url: "https://www.cabq.gov/council/find-your-councilor" },
    # "bad_example" => { key: "bad_example", url: "https://www.cabq.gov/council/frequently-asked-questions-faq" },

    data_training_dir = Rails.root.join("data/training_data")
    examples = [ { key: "seattle_wa", url: "https://www.seattle.gov/council/meet-the-council" },
    { key: "ny_ny", url: "https://council.nyc.gov/districts/" },
    { key: "boston_ma", url: "https://www.boston.gov/departments/city-council" },
    { key: "chicago_il", url: "https://chicago.councilmatic.org/council-members/" },
    { key: "st_petersburg_fl", url: "https://www.stpete.org/government/mayor___city_council/city_council/index.php" },
    { key: "corpus_christi_tx", url: "https://www.corpuschristitx.gov/our-government/mayor-and-council/council-members/" },
    { key: "austin_tx", url: "https://www.austintexas.gov/austin-city-council" },
    { key: "elizabeth_nj", url: "https://www.elizabethnj.org/215/City-Council" },
    { key: "sacramento_ca", url: "https://www.cityofsacramento.gov/mayor-council" },
    { key: "albuquerque_nm", url: "https://www.cabq.gov/council/find-your-councilor" },
    { key: "bad_example", url: "https://www.cabq.gov/council/frequently-asked-questions-faq" } ]

    # create a jsonl file with the examples
    File.open("data/training_data/fine_tuning_extract_city_info_data.jsonl", "w") do |file|
      examples.each do |example|
        expected_content = File.read(data_training_dir.join("#{example[:key]}/expected_output.yml"))
        system_instructions, user_instructions = service.generate_city_info_prompt(expected_content, example[:url])
        puts user_instructions

        file.puts({
          "prompt": system_instructions + "\n\n" + user_instructions,
          "completion": expected_content
        }.to_json)

        # add prompts and completion to the jsonl file
      end
    end
  end
end
