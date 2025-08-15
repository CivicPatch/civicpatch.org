const https = require('https');
const fs = require('fs');
const path = require('path');

async function fetchJSON(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (error) {
          reject(error);
        }
      });
    }).on('error', reject);
  });
}

async function processProgressData() {
  try {
    console.log('Fetching progress data from GitHub...');
    
    // Fetch data from civic path open-data repository
    const statesData = await fetchJSON("https://raw.githubusercontent.com/CivicPatch/open-data/refs/heads/main/progress.json");
    
    console.log('Progress data fetched successfully');
    console.log('States with data:', statesData.length);
    
    statesData.forEach((stateData) => {
      const stateCode = stateData.state;
      const percentage = stateData.civicpatch_scraped_percentage || 0;
      const scraped = stateData.civicpatch_scraped || 0;
      const total = stateData.civicpatch_scrapeable || 0;
      
      console.log(`${stateCode.toUpperCase()}: ${percentage.toFixed(1)}% complete (${scraped}/${total} municipalities)`);
    });
    
    // Save processed data to a local JSON file although may not be necessary
    const outputPath = path.join(__dirname, '../../tmp/progress_data.json');
    fs.writeFileSync(outputPath, JSON.stringify(statesData, null, 2));
    console.log(`Progress data saved to: ${outputPath}`);
    
    return statesData;
    
  } catch (error) {
    console.error('Error processing progress data:', error);
    throw error;
  }
}


processProgressData()
  .then(() => {
    console.log('Data processing completed successfully');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Data processing failed:', error);
    process.exit(1);
  });