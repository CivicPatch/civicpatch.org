import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "suggestions", "loader"];
  static debounceDefault = 1000; // Nominiatim guidelines
  static minLengthValue = 3;

  connect() {
    this._debounceTimer = null;
    this._abortController = null; // Track current request
    this._onInput = this.handleAddressInput.bind(this);
    this._suggestionsCache = {};

    if (this.hasInputTarget) {
      this.inputTarget.addEventListener("input", this._onInput);
    }
  }

  disconnect() {
    if (this.hasInputTarget) {
      this.inputTarget.removeEventListener("input", this._onInput);
    }
    // Cancel any pending request
    if (this._abortController) {
      this._abortController.abort();
    }
  }

  onInput(e) {
    const q = (e.target.value || "").trim();
    clearTimeout(this._debounceTimer);
    if (q.length < this.minLengthValue) {
      this.hideAddressSuggestions();
      return;
    }
    this._debounceTimer = setTimeout(
      () => this._fetchAndShow(q),
      this.debounceDefault,
    );
  }

  async fetchAddressSuggestions(query) {
    if (this._suggestionsCache[query]) {
      return this._suggestionsCache[query];
    }

    // Cancel previous request if it's still pending
    if (this._abortController) {
      this._abortController.abort();
    }

    // Create new AbortController for this request
    this._abortController = new AbortController();

    try {
      const response = await fetch(
        `https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&limit=5&countrycodes=us&q=${encodeURIComponent(query)}`,
        { signal: this._abortController.signal }, // Pass the signal
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();

      const suggestions = data.map((item) => ({
        display_name: item.display_name,
        lat: item.lat,
        lon: item.lon,
        formatted: `${item.display_name}`,
      }));

      this._suggestionsCache[query] = suggestions;
      this._abortController = null; // Request completed successfully
      return suggestions;
    } catch (error) {
      if (error.name === "AbortError") {
        console.log("Request was cancelled");
        return []; // Return empty array for cancelled requests
      }
      console.error("Error fetching address suggestions:", error);
      this._abortController = null; // Reset on error
      return [];
    }
  }

  async showAddressSuggestions(suggestions) {
    const list = this.suggestionsTarget;
    if (!list) return;

    // Clear previous suggestions
    list.innerHTML = "";

    if (!suggestions || suggestions.length === 0) {
      list.classList.add("hidden");
      return;
    }

    // Create suggestion items
    const fragment = document.createDocumentFragment();
    suggestions.forEach((suggestion, index) => {
      const item = document.createElement("div");
      item.className =
        "px-4 py-2 hover:bg-gray-100 cursor-pointer border-b border-gray-100 last:border-b-0";
      item.setAttribute("role", "option");
      item.dataset.index = index;
      item.dataset.lat = suggestion.lat;
      item.dataset.lon = suggestion.lon;
      item.textContent = suggestion.display_name;

      // Add click handler
      item.addEventListener("click", () => this.selectAddress(suggestion));

      fragment.appendChild(item);
    });

    list.appendChild(fragment);
    list.classList.remove("hidden");
  }

  selectAddress(suggestion) {
    // Update input with selected address
    if (this.hasInputTarget) {
      this.inputTarget.value = suggestion.display_name;
    }

    // Hide suggestions
    this.suggestionsTarget.classList.add("hidden");

    // TODO: maybe refactor into another controller?
    console.log("selection suggestioned", suggestion);
    if (typeof window.performSearch === "function") {
      window.performSearch(suggestion.lat, suggestion.lon);
    }

    // Dispatch custom event with coordinates for other components to listen to
    // TODO: Nothing is listening to this
    //this.element.dispatchEvent(new CustomEvent('address:selected', {
    //  detail: {
    //    address: suggestion.display_name,
    //    lat: suggestion.lat,
    //    lon: suggestion.lon
    //  },
    //  bubbles: true
    //}));
  }

  hideAddressSuggestions() {
    const suggestionsDiv = this.suggestionsTarget;
    if (suggestionsDiv) {
      setTimeout(() => suggestionsDiv.classList.add("hidden"), 150); // Small delay to allow click events
    }
  }

  async handleAddressInput(event) {
    const query = event.target.value.trim();

    clearTimeout(this._debounceTimer);

    // Cancel any pending request immediately when input changes
    if (this._abortController) {
      this._abortController.abort();
      this._abortController = null;
    }

    this._debounceTimer = setTimeout(async () => {
      const suggestions = await this.fetchAddressSuggestions(query);
      this.showAddressSuggestions(suggestions);
    }, this.debounceDefault);
  }
}
