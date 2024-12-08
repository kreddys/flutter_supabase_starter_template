const fs = require('fs');
const csv = require('csv-parser');
const path = require('path');

// Path to the input CSV file
const inputCSVPath = 'test-small.csv'; // Your input CSV file path
const outputCSVPath = 'small-updated_businesses.csv'; // Path for the updated CSV file

// Array to store updated data
let updatedData = [];

// Function to process the CSV file
function processCSV() {
  fs.createReadStream(inputCSVPath)
    .pipe(csv())
    .on('data', (row) => {
      // Simplify the category name
      let categoryName = row.CompanyIndustrialClassification || '';
      let simplifiedName = categoryName.toLowerCase().replace(/[^a-z0-9 ]/g, '').replace(/ /g, '_');

      // Add the new column with the simplified category name
      row.simplified_category = simplifiedName;

      // Push the updated row to the array
      updatedData.push(row);
    })
    .on('end', () => {
      // Write the updated data to a new CSV file
      writeCSV(outputCSVPath, updatedData);
      console.log('Updated CSV file created successfully.');
    });
}

// Helper function to write data to a CSV file
function writeCSV(filePath, data) {
  // Get column headers from the first row
  const headers = Object.keys(data[0]);

  // Create the CSV content
  const headerRow = headers.join(',');
  const rows = data.map(row => headers.map(header => JSON.stringify(row[header] || '')).join(',')).join('\n');
  const csvContent = headerRow + '\n' + rows;

  // Write the content to the new CSV file
  fs.writeFileSync(filePath, csvContent);
}

// Start processing
processCSV();
