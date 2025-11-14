import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "suggestions", "loader"];
  static debounceDefault = 300;
  static minLengthValue = 3;

  connect() {
    this._debounceTimer = null;
    this._onInput = this.handleAddressInput.bind(this);
    this._suggestionsCache = {}

    if (this.hasInputTarget) {
      this.inputTarget.addEventListener("input", this._onInput);
    }
  }

  disconnect() {
    if (this.hasInputTarget) {
      this.inputTarget.removeEventListener("input", this._onInput);
    }
  }

  onInput(e) {
    const q = (e.target.value || "").trim();
    console.log("Input event:", q);
    clearTimeout(this._debounceTimer);
    if (q.length < this.minLengthValue) {
      this._hide(); return;
    }
    this._debounceTimer = setTimeout(() => this._fetchAndShow(q), this.debounceDefault)
  }

  async fetchAddressSuggestions(query) {
    if (this._suggestionsCache[query]) {
      return this._suggestionsCache[query];
    }

    // Nominatim asks us to proxy this request
    // TODO
    try {
      const response = await fetch(`https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&limit=5&countrycodes=us&q=${encodeURIComponent(query)}`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const data = await response.json();

      const suggestions = data.map(item => ({
        display_name: item.display_name,
        lat: item.lat,
        lon: item.lon,
        formatted: `${item.display_name}`
      }));
      this._suggestionsCache[query] = suggestions;
      return suggestions;
    } catch (error) {
      console.error("Error fetching address suggestions:", error);
      return [];
    }
  }

  async showAddressSuggestions(suggestions) {

  }


  async handleAddressInput(event) {
    const query = event.target.value.trim();

    clearTimeout(this._debounceTimer);

    // TODO
    //if (query.length < this.minLengthValue) {
    //  this.hideAddressSuggestions();
    //  return;
    //}

    this._debounceTimer = setTimeout(async () => {
      const suggestions = await fetchAddressSuggestions(query);
      showAddressSuggestions(suggestions);
    }, this.debounceDefault);
  }

  hideAddressSuggestions() {
    const suggestionsDiv = this.suggestionsTarget;
    if (suggestionsDiv) {
      setTimeout(() => suggestionsDiv.classList.add('hidden'), 150); // Small delay to allow click events
    }
  }
}
