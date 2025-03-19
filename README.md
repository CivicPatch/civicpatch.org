# README

## TODO
- [x] For every image found on page, download the image and save it to the data/state/city/images directory.
  - [x] Test images
- [x] Connect call to openai to get yml content

## ambitiously do today!
- [ ] Grab a bunch of candidate map sites and see if we can get map data
  - [x] Do top 10 duckduckgo searches for "<city> <state> city <district|ward> map
    - [ ] Search page for the following: 
      - [ ] iframe containing arcgis map (look for patterns)
      - [ ] link containing XXXX that leads to map viewer (look for patterns)
    - [ ] Drop down to selenium as needed to grab network traffic
  - [ ] Add data to <state>/<city>/info.yml under field: "map_rest_services_layer_url"
    - [ ] Naive approach -- look for district & ward in either fields, rank then use the top choice
    - [ ] Ask openai API to figure it out -- filtering out all geometry fields, then asking it to parse the rest

- [ ] Clear out the images directory before running the script
- [ ] Regression tests -- ensure any changes to html clean up doesn't muck up


example network trafffic
website: https://arc-gis-hub-home-arcgishub.hub.arcgis.com/datasets/SeattleCityGIS::seattle-city-council-districts/explore?location=47.576077%2C-122.292213%2C10.81
rest api: https://services.arcgis.com/ZOyb2t4B0UYuYNYH/arcgis/rest/services/Seattle_City_Council_District/FeatureServer/0/query?f=geojson&where=1=1

## Sources
* TIGERweb API for pipeline/info validation on city location
  * https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/Places_CouSub_ConCity_SubMCD/MapServer/4
* 

## Services
* OpenAI API
  * To fuzzily interpret markdown
  * TODO: figure out how to reduce reliance on this API for data extraction
  * credits: $10/month
  * gpt-o4-mini: $0.15/million tokens
* Brave Search
  * free tier - 2000 queries/month
  * NOTE: this does not index entire web, so Bing search is a fallback
* Serp API (not in use)
  * https://serpapi.com/pricing
  * free tier - 100 queries/month
