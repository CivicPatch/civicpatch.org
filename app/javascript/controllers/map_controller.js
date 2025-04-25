import { Controller } from "@hotwired/stimulus"
import L from 'leaflet'
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = {
    lat: Number,
    long: Number,
  }

  latValue = 47.6061
  longValue = -122.3328

  marker = null

  markerIcon = L.icon({
    iconUrl: 'map-marker.png',

    iconSize: [51, 51], // size of the icon
    iconAnchor: [25, 51], // point of the icon which will correspond to marker's location
    popupAnchor: [-3, -76] // point from which the popup should open relative to the iconAnchor
  });

  setMarker(lat, long) {
    if (this.marker) {
      this.marker.remove()
    }
    this.marker = L.marker([lat, long], { icon: this.markerIcon }).addTo(this.map)
  }

  connect() {
    // Get URL parameters if available
    const url = new URL(window.location.href)
    const lat = url.searchParams.get('lat') || this.latValue
    const long = url.searchParams.get('long') || this.longValue

    // Initialize the map
    this.initializeMap(lat, long)

    // If lat/long parameters exist, set the map to that position
    if (lat && long) {
      this.setMapPosition(parseFloat(lat), parseFloat(long))
      this.setMarker(parseFloat(lat), parseFloat(long))
      this.updateRepresentativesList(lat, long)
    }
  }

  initializeMap(lat, long) {
    this.map = L.map('map').setView([lat, long], 13)
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(this.map);

    this.map.on('click', this.handleMapClick.bind(this))
    window.addEventListener('popstate', this.handlePopState.bind(this))
  }

  handleMapClick(event) {
    const lat = event.latlng.lat
    const long = event.latlng.lng
    this.setMarker(lat, long)
    this.updateRepresentativesList(lat, long)
  }

  handlePopState() {
    this.loadFromUrl()
  }

  loadFromUrl() {
    const params = new URLSearchParams(window.location.search)
    const lat = params.get('lat')
    const long = params.get('long')

    if (lat && long) {
      this.updateFrameAndUrl(lat, long, false); // false = don't push history again
      this.setMarker(lat, long)
    }
  }

  updateRepresentativesList(lat, long, pushHistory = true) {
    console.log("Updating representatives list")
    const query = new URLSearchParams({ lat, long }).toString()
    const newUrl = `${window.location.pathname}?${query}`
    const frame = document.getElementById("representatives-list")

    frame.src = `/map/details?${query}`

    if (pushHistory) {
      history.pushState({}, '', newUrl)
    }
  }

  // Set map position to specific coordinates
  setMapPosition(lat, long) {
    // Adjust to your map implementation
    const position = [lat, long]
    this.map.setView(position, this.map.getZoom())
    // You might want to add a marker here as well
  }

  disconnect() {
    this.map.remove()
  }
}
