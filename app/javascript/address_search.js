// Address Search functionality

// Helper functions
const $ = id => document.getElementById(id);
const valOrDash = v => (v && v !== '') ? v : '-';
const extractContact = (details, type) => Array.isArray(details) ? (details.find(c => c.type === type)?.value || null) : null;
const getInitials = name => {
  if (!name?.trim()) return '??';
  const parts = name.trim().split(/\s+/);
  return parts.length >= 2 ? (parts[0][0] + parts[parts.length-1][0]).toUpperCase() : parts[0][0].toUpperCase().repeat(2);
};

function handleImageError(img) {
  img.style.display = 'none';
  const fallback = img.nextElementSibling;
  if (fallback) fallback.style.display = 'flex';
}

// Export immediately after definition
window.handleImageError = handleImageError;

// Address suggestions functionality
let debounceTimer;
let suggestionsCache = {};

async function fetchAddressSuggestions(query) {
  if (suggestionsCache[query]) {
    return suggestionsCache[query];
  }

  try {
    // Using a geocoding service for address suggestions
    const response = await fetch(`https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&limit=5&countrycodes=us&q=${encodeURIComponent(query)}`);
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    const data = await response.json();
    
    const suggestions = data.map(item => ({
      display_name: item.display_name,
      formatted: `${item.display_name}`
    }));
    
    suggestionsCache[query] = suggestions;
    return suggestions;
  } catch (error) {
    console.error('Error fetching address suggestions:', error);
    return [];
  }
}

function showAddressSuggestions(suggestions) {
  const suggestionsDiv = $('address-suggestions');
  
  if (!suggestionsDiv) {
    console.error('Suggestions div not found!');
    return;
  }

  if (suggestions.length === 0) {
    suggestionsDiv.classList.add('hidden');
    return;
  }

  suggestionsDiv.innerHTML = suggestions.map((suggestion, index) => 
    `<div class="px-4 py-2 hover:bg-gray-100 cursor-pointer border-b border-gray-100 last:border-b-0" 
          data-address="${suggestion.display_name.replace(/"/g, '&quot;')}" data-index="${index}">
      ${suggestion.display_name}
    </div>`
  ).join('');
  
  // Add click event listeners to each suggestion
  const suggestionElements = suggestionsDiv.querySelectorAll('[data-address]');
  
  suggestionElements.forEach((element, index) => {
    element.addEventListener('click', () => {
      const address = element.getAttribute('data-address');
      selectAddress(address);
    });
  });
  
  suggestionsDiv.classList.remove('hidden');
}

function selectAddress(address) {
  const addressInput = $('address-input');
  const suggestionsDiv = $('address-suggestions');
  
  if (addressInput) {
    addressInput.value = address;
  }
  if (suggestionsDiv) {
    suggestionsDiv.classList.add('hidden');
  }
}

// Export immediately after definition
window.selectAddress = selectAddress;

function hideAddressSuggestions() {
  const suggestionsDiv = $('address-suggestions');
  if (suggestionsDiv) {
    setTimeout(() => suggestionsDiv.classList.add('hidden'), 150); // Small delay to allow click events
  }
}

async function handleAddressInput(event) {
  const query = event.target.value.trim();
  
  clearTimeout(debounceTimer);
  
  if (query.length < 3) {
    hideAddressSuggestions();
    return;
  }
  
  debounceTimer = setTimeout(async () => {
    const suggestions = await fetchAddressSuggestions(query);
    showAddressSuggestions(suggestions);
  }, 300);
}

// Main search function
async function performSearch() {
  try {
    const addressInput = $('address-input');
    const address = addressInput?.value.trim();
    
    if (!address) return alert('Please enter an address');

    // UI state management
    const elements = ['search-button', 'search-text', 'search-loading', 'search-results', 'loading-message', 'error-message'].map($);
    const [searchButton, searchText, searchLoading, searchResults, loadingMessage, errorMessage] = elements;

    // Show loading
    if (searchButton) searchButton.disabled = true;
    if (searchText) searchText.classList.add('hidden');
    if (searchLoading) searchLoading.classList.remove('hidden');
    if (searchResults) searchResults.classList.remove('hidden');
    if (loadingMessage) loadingMessage.classList.remove('hidden');
    if (errorMessage) errorMessage.classList.add('hidden');

    try {
      const response = await fetch('/api/representatives/search', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || ''
        },
        body: JSON.stringify({ address })
      });

      const data = await response.json();
      
      if (response.ok && data.representatives?.length > 0) {
        displayRepresentatives(data.representatives);
        const count = data.representatives.length;
        if (loadingMessage) loadingMessage.innerHTML = `<span class="px-4 py-3 font-medium">${count} representative${count !== 1 ? 's' : ''} found</span>`;
      } else {
        showError(data.error || 'No representatives found for this address');
      }
    } catch (error) {
      showError('Error: ' + error.message);
    } finally {
      // Reset UI
      if (searchButton) searchButton.disabled = false;
      if (searchText) searchText.classList.remove('hidden');
      if (searchLoading) searchLoading.classList.add('hidden');
    }
  } catch (extensionError) {
    // Handle browser extension interference
    console.warn('Browser extension interference detected:', extensionError);
    alert('Search completed, but there may be browser extension interference. Try disabling extensions if you see issues.');
  }
}

// Export immediately after definition
window.performSearch = performSearch;

function displayRepresentatives(representatives) {
  const list = $('representatives-list');
  const errorMessage = $('error-message');

  if (errorMessage) errorMessage.classList.add('hidden');
  if (!list) return;

  list.innerHTML = '';

  if (representatives.length === 0) {
    list.innerHTML = '<p class="text-gray-500 text-center py-4">No representatives found.</p>';
    list.classList.remove('hidden');
    return;
  }

  // Create table
  const columns = [
    { key: 'image', label: 'Image', width: 'w-30' },
    { key: 'name', label: 'Name', width: 'w-40' },
    { key: 'office', label: 'Office', width: 'w-40' },
    { key: 'contact_email', label: 'Contact Email', width: 'w-48' },
    { key: 'contact_phone', label: 'Contact Phone', width: 'w-36' },
    { key: 'links', label: 'Links', width: 'w-32' }
  ];

  const table = document.createElement('table');
  table.className = 'w-full';

  // Header
  const thead = document.createElement('thead');
  const headerRow = document.createElement('tr');
  headerRow.className = 'bg-gray-50 border-b border-gray-200';
  columns.forEach(col => {
    const th = document.createElement('th');
    th.className = `${col.width} px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider w-40 border-b-2 border-gray-200`;
    th.textContent = col.label;
    headerRow.appendChild(th);
  });
  thead.appendChild(headerRow);
  table.appendChild(thead);

  // Body
  const tbody = document.createElement('tbody');
  tbody.className = 'bg-white';
  representatives.forEach(rep => {
    const row = document.createElement('tr');
    row.className = 'block md:table-row border-b-2 border-gray-200 mb-4 md:mb-0 hover:bg-gray-50';

    columns.forEach(col => {
      const td = document.createElement('td');
      td.className = 'text-center block md:table-cell px-4 py-2 md:px-6 md:py-4 whitespace-nowrap align-center';

      switch (col.key) {
        case 'name':
          td.innerHTML = `<div class="text-center font-medium text-gray-900">${valOrDash(rep.name)}</div>`;
          break;
        case 'image':
          const initials = getInitials(rep.name);
          if (rep.image?.trim()) {
            td.innerHTML = `<div class="flex justify-center p-2">
              <img src="${rep.image}" alt="${rep.name || 'Representative'}" class="h-40 w-40 md:h-24 md:w-24 rounded-lg object-cover" onerror="handleImageError(this)">
              <div class="h-40 w-40 md:h-24 md:w-24 rounded-lg overflow-hidden bg-gray-100 flex items-center justify-center text-white font-semibold text-lg md:text-sm" style="display:none;">${initials}</div>
            </div>`;
          } else {
            td.innerHTML = `<div class="flex justify-center p-2"><div class="h-40 w-40 md:h-24 md:w-24 rounded-lg overflow-hidden bg-gray-100 flex items-center justify-center text-white font-semibold text-lg md:text-sm">${initials}</div></div>`;
          }
          break;
        case 'office':
          // Include other_names in office display
          let officeText = valOrDash(rep.office || rep.title || rep.level || rep.position || rep.role);
          if (rep.other_names && Array.isArray(rep.other_names) && rep.other_names.length > 0) {
            const otherNames = rep.other_names.map(name => {
              if (typeof name === 'string') return name;
              if (typeof name === 'object' && name.name) return name.name;
              return String(name);
            });
            
            if (otherNames.length > 1) {
              // Multiple other names - list them separately with normal font size
              const otherNamesList = otherNames.map(name => `<div class="text-gray-600">${name}</div>`).join('');
              if (officeText !== '-') {
                td.innerHTML = `<div class="text-center">
                  <div class="font-medium">${officeText}</div>
                  ${otherNamesList}
                </div>`;
              } else {
                td.innerHTML = `<div class="text-center">${otherNamesList}</div>`;
              }
            } else {
              // Single other name - show inline
              const otherNamesText = otherNames.join(', ');
              if (officeText !== '-') {
                officeText += ` (${otherNamesText})`;
              } else {
                officeText = otherNamesText;
              }
              td.innerHTML = `<div class="text-center">${officeText}</div>`;
            }
          } else {
            td.innerHTML = `<div class="text-center">${officeText}</div>`;
          }
          break;
        case 'contact_email':
          const email = extractContact(rep.contact_details, 'email') || rep.email || rep.contact_email;
          td.innerHTML = email ? `<div class="text-center"><a href="mailto:${email}" class="break-all">${email}</a></div>` : '<div class="text-center">-</div>';
          break;
        case 'contact_phone':
          const phone = extractContact(rep.contact_details, 'phone') || rep.phone || rep.contact_phone;
          td.innerHTML = phone ? `<div class="text-center"><a href="tel:${phone}" class="">${phone}</a></div>` : '<div class="text-center">-</div>';
          break;
        case 'links':
          const allLinks = [];
          
          // Add website if available
          const website = rep.website || rep.url || rep.official_website;
          if (website) {
            const href = website.match(/^https?:\/\//) ? website : `https://${website}`;
            allLinks.push({ url: href, label: 'Website' });
          }
          
          // Add links from links array
          if (rep.links && Array.isArray(rep.links)) {
            rep.links.forEach(link => {
              if (typeof link === 'string') {
                allLinks.push({ url: link, label: 'Link' });
              } else if (typeof link === 'object' && link.url) {
                allLinks.push({ url: link.url, label: link.note || link.label || 'Link' });
              }
            });
          }
          
          // Add sources to links
          if (rep.sources && Array.isArray(rep.sources)) {
            rep.sources.forEach(source => {
              if (typeof source === 'string') {
                allLinks.push({ url: source, label: 'Source' });
              } else if (typeof source === 'object' && source.url) {
                allLinks.push({ url: source.url, label: source.note || source.label || 'Source' });
              }
            });
          }
          
          if (allLinks.length > 0) {
            // Center all links regardless of quantity
            const linkElements = allLinks.map(link => 
              `<a href="${link.url}" target="_blank" rel="noopener noreferrer" class="block text-blue-600 hover:text-blue-800">${link.label}</a>`
            ).join('');
            td.innerHTML = `<div class="text-center space-y-1">${linkElements}</div>`;
          } else {
            td.innerHTML = '<div class="text-center">-</div>';
          }
          break;
        default:
          td.innerHTML = `<div class="text-center">${valOrDash(rep[col.key])}</div>`;
      }
      row.appendChild(td);
    });
    tbody.appendChild(row);
  });

  table.appendChild(tbody);
  const container = document.createElement('div');
  container.className = 'overflow-x-auto md:overflow-visible border border-gray-200 rounded-lg shadow-sm mb-8';
  container.appendChild(table);
  list.appendChild(container);
  list.classList.remove('hidden');
  
  // Add "Search Again" message after results
  const searchAgainDiv = document.createElement('div');
  searchAgainDiv.className = 'text-center py-4 text-gray-600 text-sm border-t border-gray-200 mt-4';
  searchAgainDiv.innerHTML = '↑ Scroll up to search for a different address';
  list.appendChild(searchAgainDiv);
  
  // Smooth scroll to results
  setTimeout(() => {
    const resultsDiv = $('search-results');
    if (resultsDiv) {
      resultsDiv.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }, 100);
}

// Show error
function showError(message) {
  const errorMessage = $('error-message');
  const list = $('representatives-list');
  const results = $('search-results');

  if (results) results.classList.remove('hidden');
  if (list) list.classList.add('hidden');
  if (!errorMessage) return alert('Error: ' + message);

  const paragraphs = errorMessage.querySelectorAll('p');
  if (paragraphs.length > 1) paragraphs[1].textContent = message;
  else if (paragraphs.length === 1) paragraphs[0].textContent = message;
  else errorMessage.textContent = message;

  errorMessage.classList.remove('hidden');
}

// Tab functionality
function showTab(tabName) {
  document.querySelectorAll('.tab-content').forEach(content => content.classList.add('hidden'));
  document.querySelectorAll('[id$="-tab"]').forEach(tab => {
    tab.classList.remove('border-blue-500', 'text-blue-600', 'bg-white');
    tab.classList.add('border-transparent', 'text-gray-500', 'bg-gray-50');
  });

  const content = $(tabName + '-content');
  const tab = $(tabName + '-tab');
  if (content) content.classList.remove('hidden');
  if (tab) {
    tab.classList.add('border-blue-500', 'text-blue-600', 'bg-white');
    tab.classList.remove('border-transparent', 'text-gray-500', 'bg-gray-50');
  }

  // Control visibility of search button and results based on tab
  const searchButtonContainer = document.querySelector('.py-3.px-6.flex.justify-center');
  const searchResults = $('search-results');
  
  if (tabName === 'address') {
    // Show search button and results for address tab
    if (searchButtonContainer) searchButtonContainer.style.display = 'flex';
    if (searchResults) searchResults.style.display = 'block';
  } else {
    // Hide search button and results for other tabs (browse)
    if (searchButtonContainer) searchButtonContainer.style.display = 'none';
    if (searchResults) searchResults.style.display = 'none';
  }
}

// Export immediately after definition
window.showTab = showTab;

// Export functions to global scope for onclick handlers (backup - already exported above)

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  
  // Initialize the default tab
  if (typeof window.showTab === 'function') {
    window.showTab('address');
  } else {
    console.error('showTab function not available');
  }
  
  // Set up address input event listeners
  const addressInput = $('address-input');
    const DEBUG = false;

    addressInput.addEventListener('input', (e) => {
      if (DEBUG) {
        console.log('Input event triggered with value:', e.target.value);
      }
      handleAddressInput(e);
    });
    });
    addressInput.addEventListener('blur', hideAddressSuggestions);
    addressInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
  } else {
    console.error('Address input element not found!');
  }
});

