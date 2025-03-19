# README

example network trafffic
website: https://arc-gis-hub-home-arcgishub.hub.arcgis.com/datasets/SeattleCityGIS::seattle-city-council-districts/explore?location=47.576077%2C-122.292213%2C10.81
rest api: https://services.arcgis.com/ZOyb2t4B0UYuYNYH/arcgis/rest/services/Seattle_City_Council_District/FeatureServer/0/query?f=geojson&where=1=1

## Sources
* TIGERweb API for pipeline/info validation on city location
  * https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/Places_CouSub_ConCity_SubMCD/MapServer/4

## Services
* OpenAI API
  * Fuzzily interpret markdown 
  * credits: $10/month
  * gpt-o4-mini: $0.15/million tokens
* Brave Search
  * free tier - 2000 queries/month
  * NOTE: this does not index entire web, so Bing search is a fallback
* Serp API (not in use)
  * https://serpapi.com/pricing
  * free tier - 100 queries/month

# Software
* GDAL
  * Mac: `brew install gdal`

# Rake Tasks
* `rake maps:census_to_map[wa]`
  * Converts the census shapefiles to a GeoJSON files
  