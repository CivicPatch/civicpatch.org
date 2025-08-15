javascript/progress_map.js
// Progress map functionality
async function loadProgressMap() {
  try {
    console.log('Loading progress map...');
    
    // Check if D3 is available first
    if (typeof d3 === 'undefined') {
      console.error('D3.js not loaded');
      return;
    }
    
    // Load data from local JSON file or fetch if not available
    const statesData = tmp/progress_data.json;
    if (!statesData || statesData.length === 0) {
      const response = await fetch("https://raw.githubusercontent.com/CivicPatch/open-data/refs/heads/main/progress.json");
      console.log('Data fetched from external source');
      const statesData = await response.json();
    
    console.log('States data loaded:', statesData.length, 'states');
    
    const svg = d3.select("#progress-map");
    
    // Clear any existing content
    svg.selectAll("*").remove();
    
    // Create a simple visualization for now
    svg.append("text")
       .attr("x", 50)
       .attr("y", 50)
       .text(`Progress Map - ${statesData.length} states loaded`)
       .style("font-size", "16px")
       .style("fill", "black");
       
    // Add state progress bars
    statesData.forEach((stateData, index) => {
      const y = 80 + (index * 25);
      const stateCode = stateData.state;
      const progress = stateData.civicpatch_scraped_percentage || 0;
      const scraped = stateData.civicpatch_scraped || 0;
      const total = stateData.civicpatch_scrapeable || 0;
      
      // State label
      svg.append("text")
         .attr("x", 50)
         .attr("y", y)
         .text(`${stateCode.toUpperCase()}: ${progress.toFixed(1)}% (${scraped}/${total})`)
         .style("font-size", "12px")
         .style("fill", "black");
         
      // Progress bar background
      svg.append("rect")
         .attr("x", 250)
         .attr("y", y - 12)
         .attr("width", 200)
         .attr("height", 15)
         .style("fill", "#e5e7eb")
         .style("stroke", "#d1d5db");
         
      // Progress bar fill
      svg.append("rect")
         .attr("x", 250)
         .attr("y", y - 12)
         .attr("width", (progress / 100) * 200)
         .attr("height", 15)
         .style("fill", progress > 50 ? "#22c55e" : progress > 25 ? "#f59e0b" : "#ef4444");
    });
    
  } catch (error) {
    console.error('Error loading progress map:', error);
    
    // Show error in the SVG
    const svg = d3.select("#progress-map");
    svg.selectAll("*").remove();
    svg.append("text")
       .attr("x", 50)
       .attr("y", 50)
       .text("Error loading progress data")
       .style("font-size", "16px")
       .style("fill", "red");
  }
}

window.loadProgressMap = loadProgressMap;