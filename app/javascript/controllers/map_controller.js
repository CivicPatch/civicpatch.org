import { Controller } from "@hotwired/stimulus"
import L from 'leaflet'
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = {
    state: String,
    geoid: String,
  }

  // This is Seattle, WA
  stateValue = "wa"
  geoidValue = "5363000"

  marker = null
  lastRequestTime = 0
  lastRequestBounds = null
  boundariesCache = new Map() // Cache for boundaries data
  minRequestInterval = 1000 // Minimum time between requests in ms
  minDistanceThreshold = 0.01 // Minimum distance change to trigger new request

  markerIcon = L.icon({
    iconUrl: 'map-marker.png',
    iconSize: [51, 51],
    iconAnchor: [25, 51],
    popupAnchor: [-3, -76]
  });

  boundariesLayer = null
  debounceTimeout = null

  // --- Theme Setup ---
  colorPalette = [
    '#3182ce', // blue
    '#805ad5', // purple
    '#d53f8c', // pink
    '#dd6b20', // orange
    '#38a169', // green
    '#e53e3e', // red
    '#319795', // teal
    '#b83280'  // magenta
  ];
  colorIndex = 0;
  // ------------------

  setMarker(lat, long) {
    if (this.marker) {
      this.marker.remove()
    }
    const position = [lat, long];
    this.marker = L.marker(position, { icon: this.markerIcon }).addTo(this.map);
  }

  connect() {
    const url = new URL(window.location.href)
    const state = url.searchParams.get('state') || this.stateValue
    const geoid = url.searchParams.get('geoid') || this.geoidValue

    this.initializeMap(state, geoid)
    this.updateRepresentativesList(state, geoid, false)
  }

  async initializeMap(state, geoid) {
    console.log("Initializing map")
    try {
      // Get latitude and longitude from geoid using the api
      const response = await fetch(`/map/lat_long?state=${state}&geoid=${geoid}`)
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      const data = await response.json()
      const lat = data.lat
      const long = data.long

      this.map = L.map('map', {
        zoomControl: true,
        dragging: true,
        doubleClickZoom: false,
        scrollWheelZoom: true,
        boxZoom: false,
        keyboard: true,
        tap: false,
        touchZoom: true,
        inertia: false,
        bounceAtZoomLimits: false,
        worldCopyJump: false,
        maxBoundsViscosity: 1.0,
        wheelDebounceTime: 40,
        wheelPxPerZoomLevel: 60
      }).setView([lat, long], 13)

      L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19,
        attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
      }).addTo(this.map)

      // Create a layer group to hold the boundaries
      this.boundariesLayer = L.layerGroup().addTo(this.map)

      // Load initial boundaries
      await this.loadBoundariesForView()

      // Event listeners
      this.map.on('click', (event) => {
        // Check if the click is within any of the GeoJSON boundaries
        let clickedBoundary = null;
        let clickedGeoid = null;
        this.boundariesLayer.eachLayer((layer) => {
          if (layer instanceof L.Polygon && layer.getBounds().contains(event.latlng)) {
            clickedBoundary = layer;
            clickedGeoid = layer.feature.properties.geoid;
          }
        });

        // Always set the marker at the clicked location
        const lat = event.latlng.lat;
        const long = event.latlng.lng;
        this.setMarker(lat, long);

        if (!clickedBoundary) {
          // Click is outside boundaries, clear representatives
          const frame = document.getElementById("representatives-list");
          if (frame) {
            frame.innerHTML = `
              <div class="flex flex-col items-center justify-center min-h-[200px]">
                <div class="text-lg font-medium text-gray-700">No representatives found for this location</div>
              </div>
            `;
          }
        } else {
          // Click is within boundaries, center map on the boundary and update representatives list
          this.map.fitBounds(clickedBoundary.getBounds(), {
            padding: [50, 50], // Add some padding around the boundary
            maxZoom: 15 // Don't zoom in too far
          });
          // Update representatives list with the clicked boundary's GEOID
          this.updateRepresentativesList(state, clickedGeoid, true);
        }
      });

      this.map.on('moveend', this.handleMapMoveEnd.bind(this))

      // Set initial marker without moving the map
      if (lat && long) {
        const initialLat = parseFloat(lat)
        const initialLong = parseFloat(long)
        this.setMarker(initialLat, initialLong)
      }
    } catch (error) {
      console.error('Error initializing map:', error)
    }
  }

  handleMapOutOfBoundariesClick(event) {
    // Prevent any default map behavior
    L.DomEvent.stopPropagation(event);
    L.DomEvent.preventDefault(event);

    // Get the clicked coordinates
    const lat = event.latlng.lat;
    const long = event.latlng.lng;

    // Set the marker without moving the map
    this.setMarker(lat, long);

    // Update the form fields
    this.latTarget.value = lat;
    this.longTarget.value = long;

    // Clear the representatives list
    const frame = document.getElementById("representatives-list");
    if (frame) {
      frame.innerHTML = `
        <div class="flex flex-col items-center justify-center min-h-[200px]">
          <div class="text-lg font-medium text-gray-700">No representatives found for this location</div>
        </div>
      `;
    }
  }

  // Debounced handler for when the map stops moving
  handleMapMoveEnd() {
    clearTimeout(this.debounceTimeout);
    this.debounceTimeout = setTimeout(() => {
      this.loadBoundariesForView();
    }, 1000); // Increased from 500ms to 1000ms
  }

  updateRepresentativesList(state, geoid, pushHistory = true) {
    console.log("Updating representatives list")
    const query = new URLSearchParams({ state, geoid }).toString()
    const newUrl = `${window.location.pathname}?${query}`
    const frame = document.getElementById("representatives-list")

    if (!frame) {
      console.error("Representatives list frame not found");
      return;
    }

    // Show loading state
    frame.innerHTML = `
      <div class="flex flex-col items-center justify-center min-h-[200px]">
        <div class="animate-spin rounded-full h-16 w-16 border-4 border-blue-500 border-t-transparent"></div>
        <div class="mt-4 text-lg font-medium text-gray-700">Loading representatives...</div>
      </div>
    `;

    // Update the frame source after a small delay to ensure loading state is visible
    setTimeout(() => {
      frame.src = `/map/details?${query}`;

      if (pushHistory) {
        history.pushState({}, '', newUrl);
      }
    }, 50);
  }

  setMapPosition(lat, long) {
    // Remove this method as we don't want automatic map movements
  }

  // --- Style Function ---
  getBoundaryStyle(feature) {
    // Use the feature's properties to generate a consistent color
    const featureId = feature.properties.geoid || feature.id;
    const colorIndex = Math.abs(this.hashCode(featureId)) % this.colorPalette.length;
    const color = this.colorPalette[colorIndex];

    // Return the style object
    return {
      color: color,
      weight: 2,
      opacity: 0.8,
      fillColor: color,
      fillOpacity: 0.2
    };
  }

  // Helper function to generate a hash code for a string
  hashCode(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32bit integer
    }
    return hash;
  }
  // ---------------------

  // Helper to check if bounds have changed significantly
  hasSignificantChange(newBounds) {
    if (!this.lastRequestBounds) return true;

    const oldCenter = this.lastRequestBounds.getCenter();
    const newCenter = newBounds.getCenter();

    const latDiff = Math.abs(oldCenter.lat - newCenter.lat);
    const lngDiff = Math.abs(oldCenter.lng - newCenter.lng);

    return latDiff > this.minDistanceThreshold || lngDiff > this.minDistanceThreshold;
  }

  // Helper to generate cache key from bounds
  getCacheKey(bounds) {
    const sw = bounds.getSouthWest();
    const ne = bounds.getNorthEast();
    return `${sw.lat.toFixed(2)},${sw.lng.toFixed(2)}-${ne.lat.toFixed(2)},${ne.lng.toFixed(2)}`;
  }

  // Fetches and displays boundaries for the current map view
  async loadBoundariesForView() {
    if (!this.map) return;

    const currentBounds = this.map.getBounds();
    const currentCacheKey = this.getCacheKey(currentBounds);

    // Check if we have cached data
    if (this.boundariesCache.has(currentCacheKey)) {
      const cachedData = this.boundariesCache.get(currentCacheKey);
      this.boundariesLayer.clearLayers();
      L.geoJSON(cachedData, {
        style: this.getBoundaryStyle.bind(this),
        onEachFeature: (feature, layer) => {
          // Store the original style for reset
          layer.originalStyle = this.getBoundaryStyle(feature);

          layer.on({
            mouseover: (e) => {
              const layer = e.target;
              layer.setStyle({
                weight: 3,
                fillOpacity: 0.7
              });
              layer.bringToFront();
            },
            mouseout: (e) => {
              const layer = e.target;
              layer.setStyle(layer.originalStyle);
            },
            click: (e) => {
              const layer = e.target;
              const geoid = feature.properties.geoid;
              const state = feature.properties.state;

              // Center map on the clicked boundary
              this.map.fitBounds(layer.getBounds(), {
                padding: [50, 50],
                maxZoom: 15
              });

              // Show loading state immediately
              const frame = document.getElementById("representatives-list");
              if (frame) {
                // Clear the frame content first
                frame.removeAttribute('src');
                frame.innerHTML = `
                  <div class="flex flex-col items-center justify-center min-h-[200px]">
                    <div class="animate-spin rounded-full h-16 w-16 border-4 border-blue-500 border-t-transparent"></div>
                    <div class="mt-4 text-lg font-medium text-gray-700">Loading representatives...</div>
                  </div>
                `;
              }

              // Update representatives list after a small delay
              setTimeout(() => {
                this.updateRepresentativesList(state, geoid, true);
              }, 50);
            }
          });
        }
      }).addTo(this.boundariesLayer);
      return;
    }

    const now = Date.now();
    const bounds = this.map.getBounds();
    const cacheKey = this.getCacheKey(bounds);

    // Check if we should make a new request
    if (
      now - this.lastRequestTime < this.minRequestInterval ||
      !this.hasSignificantChange(bounds) ||
      this.boundariesCache.has(cacheKey)
    ) {
      return;
    }

    this.lastRequestTime = now;
    this.lastRequestBounds = bounds;
    this.colorIndex = 0;

    const sw = bounds.getSouthWest();
    const ne = bounds.getNorthEast();

    const query = new URLSearchParams({
      sw_lat: sw.lat,
      sw_lng: sw.lng,
      ne_lat: ne.lat,
      ne_lng: ne.lng
    }).toString();

    try {
      console.log('Fetching boundaries with query:', query);
      const response = await fetch(`/map/municipality_boundaries?${query}`);
      if (!response.ok) {
        console.error('Error response:', response.status, response.statusText);
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const geojsonData = await response.json();
      console.log('Received GeoJSON data:', geojsonData);

      // Cache the result
      this.boundariesCache.set(cacheKey, geojsonData);

      // Limit cache size
      if (this.boundariesCache.size > 20) {
        const firstKey = this.boundariesCache.keys().next().value;
        this.boundariesCache.delete(firstKey);
      }

      // Clear existing layers
      this.boundariesLayer.clearLayers();

      if (geojsonData?.features?.length > 0) {
        console.log('Adding GeoJSON layer with', geojsonData.features.length, 'features');
        L.geoJSON(geojsonData, {
          style: this.getBoundaryStyle.bind(this),
          onEachFeature: (feature, layer) => {
            // Store the original style for reset
            layer.originalStyle = this.getBoundaryStyle(feature);

            layer.on({
              mouseover: (e) => {
                const layer = e.target;
                layer.setStyle({
                  weight: 3,
                  fillOpacity: 0.7
                });
                layer.bringToFront();
              },
              mouseout: (e) => {
                const layer = e.target;
                layer.setStyle(layer.originalStyle);
              },
              click: (e) => {
                const layer = e.target;
                const geoid = feature.properties.geoid;
                const state = feature.properties.state;

                // Center map on the clicked boundary
                this.map.fitBounds(layer.getBounds(), {
                  padding: [50, 50],
                  maxZoom: 15
                });

                // Show loading state immediately
                const frame = document.getElementById("representatives-list");
                if (frame) {
                  // Clear the frame content first
                  frame.removeAttribute('src');
                  frame.innerHTML = `
                    <div class="flex flex-col items-center justify-center min-h-[200px]">
                      <div class="animate-spin rounded-full h-16 w-16 border-4 border-blue-500 border-t-transparent"></div>
                      <div class="mt-4 text-lg font-medium text-gray-700">Loading representatives...</div>
                    </div>
                  `;
                }

                // Update representatives list after a small delay
                setTimeout(() => {
                  this.updateRepresentativesList(state, geoid, true);
                }, 50);
              }
            });
          }
        }).addTo(this.boundariesLayer);
      } else {
        console.log('No features found in GeoJSON data');
      }
    } catch (error) {
      console.error('Error loading boundaries:', error);
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
