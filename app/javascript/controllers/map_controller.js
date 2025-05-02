import { Controller } from "@hotwired/stimulus"
import L from 'leaflet'
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = {
    statefp: String,
    geoid: String,
  }

  // This is Seattle, WA
  statefpValue = "53"
  geoidValue = "5363000"

  marker = null

  markerIcon = L.icon({
    iconUrl: 'map-marker.png',

    iconSize: [51, 51], // size of the icon
    iconAnchor: [25, 51], // point of the icon which will correspond to marker's location
    popupAnchor: [-3, -76] // point from which the popup should open relative to the iconAnchor
  });

  boundariesLayer = null // Layer group for boundaries
  debounceTimeout = null // For debouncing map move events

  // --- Theme Setup ---
  colorPalette = ['#3182ce', '#63b3ed', '#4299e1', '#319795', '#81e6d9', '#4fd1c5']; // Example Blue/Teal palette
  colorIndex = 0;
  // ------------------

  setMarker(lat, long) {
    if (this.marker) {
      this.marker.remove()
    }
    const position = [lat, long];
    this.marker = L.marker(position, { icon: this.markerIcon }).addTo(this.map);

    this.map.setView(position, this.map.getZoom());
  }

  connect() {
    const url = new URL(window.location.href)
    const statefp = url.searchParams.get('statefp') || this.statefpValue
    const geoid = url.searchParams.get('geoid') || this.geoidValue

    this.initializeMap(statefp, geoid)

    // Load initial boundaries for the current view
    this.loadBoundariesForView()
  }

  async initializeMap(statefp, geoid) {
    console.log("Initializing map")
    // Get latitude and longitude from geoid using the api
    const response = await fetch(`/map/lat_long?statefp=${statefp}&geoid=${geoid}`)
    const data = await response.json()
    const lat = data.lat
    const long = data.long
    this.map = L.map('map').setView([lat, long], 13)
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(this.map);

    // Create a layer group to hold the boundaries
    this.boundariesLayer = L.layerGroup().addTo(this.map);

    // Event listeners
    this.map.on('click', this.handleMapOutOfBoundariesClick.bind(this))
    this.map.on('moveend', this.handleMapMoveEnd.bind(this)) // << Add listener for map movement

    // Keep marker logic if needed for specific clicked points
    if (lat && long) {
      const initialLat = parseFloat(lat);
      const initialLong = parseFloat(long);
      this.setMapPosition(initialLat, initialLong);
      this.setMarker(initialLat, initialLong);
    }
  }

  handleMapOutOfBoundariesClick(event) {
    const lat = event.latlng.lat
    const long = event.latlng.lng
    this.statefpValue = null
    this.geoidValue = null

    this.setMarker(lat, long)
    this.updateRepresentativesList(null, null)
  }

  // Debounced handler for when the map stops moving
  handleMapMoveEnd() {
    clearTimeout(this.debounceTimeout); // Clear previous timeout
    this.debounceTimeout = setTimeout(() => { // Set new timeout
      this.loadBoundariesForView();
    }, 500); // Wait 500ms after map stops moving before fetching
  }

  updateRepresentativesList(statefp, geoid, pushHistory = true) {
    console.log("Updating representatives list")
    const query = new URLSearchParams({ statefp, geoid }).toString()
    const newUrl = `${window.location.pathname}?${query}`
    const frame = document.getElementById("representatives-list")

    frame.src = `/map/details?${query}`

    if (pushHistory) {
      history.pushState({}, '', newUrl)
    }
  }

  setMapPosition(lat, long) {
    // Adjust to your map implementation
    const position = [lat, long]
    this.map.setView(position, this.map.getZoom())
    // You might want to add a marker here as well
  }

  // --- Style Function ---
  getBoundaryStyle(feature) {
    const color = this.colorPalette[this.colorIndex % this.colorPalette.length];
    this.colorIndex++;

    // Return the style object
    return {
      color: color,
      weight: 1,      // Base weight
      opacity: 0.8,
      fillColor: color,
      fillOpacity: 0.5 // Base fill opacity
    };
  }
  // ---------------------

  // Fetches and displays boundaries for the current map view
  async loadBoundariesForView() {
    if (!this.map) {
      return
    }

    this.colorIndex = 0; // Reset color index

    const bounds = this.map.getBounds();
    const sw = bounds.getSouthWest();
    const ne = bounds.getNorthEast();

    const query = new URLSearchParams({
      sw_lat: sw.lat,
      sw_lng: sw.lng,
      ne_lat: ne.lat,
      ne_lng: ne.lng
    }).toString();
    const url = `/map/municipality_boundaries?${query}`;

    console.log("Fetching boundaries for view:", url);

    try {
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const geojsonData = await response.json();

      console.log(`Received ${geojsonData.features.length} boundaries for view.`);

      this.boundariesLayer.clearLayers();

      if (geojsonData && geojsonData.features && geojsonData.features.length > 0) {
        const newLayer = L.geoJSON(geojsonData, {
          style: this.getBoundaryStyle.bind(this), // Use the style function

          onEachFeature: (feature, layer) => {
            const originalStyle = {
              weight: layer.options.weight,
              opacity: layer.options.opacity,
              fillOpacity: layer.options.fillOpacity,
              color: layer.options.color,
              fillColor: layer.options.fillColor
            };

            layer.on({
              mouseover: (e) => {
                const hoverStyle = {
                  ...originalStyle,
                  fillColor: '#FACC15',
                  weight: 3,
                  fillOpacity: 0.6
                };
                e.target.setStyle(hoverStyle);

              },
              mouseout: (e) => {
                newLayer.resetStyle(e.target);
              },
              click: (e) => {
                L.DomEvent.stopPropagation(e)
                this.setMarker(e.latlng.lat, e.latlng.lng)

                const geoid = e.target.feature.properties.geoid;
                const statefp = e.target.feature.properties.statefp;
                this.updateRepresentativesList(statefp, geoid);
              }
            });
          }
        });
        this.boundariesLayer.addLayer(newLayer);
      }
    } catch (error) {
      console.error("Error loading boundaries for view:", error);
    }
  }

  disconnect() {
    clearTimeout(this.debounceTimeout); // Clear timeout on disconnect
    if (this.map) {
      // Remove specific listeners before removing map
      this.map.off('click', this.handleMapOutOfBoundariesClick.bind(this));
      this.map.off('moveend', this.handleMapMoveEnd.bind(this));
      this.map.remove();
    }
    window.removeEventListener('popstate', this.handlePopState.bind(this));
  }
}
