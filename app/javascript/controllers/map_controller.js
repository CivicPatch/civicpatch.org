import { Controller } from "@hotwired/stimulus"
import L from 'leaflet'
export default class extends Controller {
  static values = {
    lat: Number,
    long: Number,
  }

  latValue = 47.6061
  longValue = -122.3328

  greet() {
    console.log("hello??", this.element)
  }

  connect() {
    this.map = L.map('map').setView([this.latValue, this.longValue], 13)
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(this.map);
  }
  disconnect() {
    this.map.remove()
  }
}
