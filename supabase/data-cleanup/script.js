const fs = require('fs');
const csv = require('csv-parser');
const uuidv4 = require('uuid').v4;
const path = require('path');

// Read the CSV files
const inputCSVPath = 'updated_businesses.csv'; // Use the updated CSV file with simplified categories
const businessesCSVPath = 'businesses.csv';
const categoriesCSVPath = 'business_categories.csv';
const mappingsCSVPath = 'business_category_mappings.csv';
const errorLogPath = 'category_errors.log'; // Log file for unmatched categories

// Arrays to hold business data, categories, and mappings
let businesses = [];
let categories = new Map();
let businessCategories = [];
let errors = [];

// Simplified categories from your list
const categoryMapping = {
  'business_services': 'Services',
  'construction': 'Construction',
  'real_estate_and_renting': 'RealEstate',
  'trading': 'Trading',
  'manufacturing_textiles': 'Textiles',
  'other_professional_scientific_and_technical_activities': 'Professional',
  'manufacturing_paper__paper_products_publishing_printing_and_reproduction_of_recorded_media': 'Publishing',
  'manufacturing_metals__chemicals_and_products_thereof': 'Chemicals',
  'manufacture_of_basic_metals': 'Metals',
  'agriculture_and_allied_activities': 'Agriculture',
  'manufacturing_machinery__equipments': 'Machinery',
  'manufacture_of_other_transport_equipment': 'Transport',
  'community_personal__social_services': 'Community',
  'manufacture_of_computer_electronicand_optical_products': 'Electronics',
  'education': 'Education',
  'other_personal_service_activities': 'Personal',
  'sports_activities_and_amusement_and_recreation_activities': 'Recreation',
  'activities_of_membership_organizations': 'Organizations',
  'accommodation': 'Accommodation',
  'finance': 'Finance',
  'food_and_beverage_service_activities': 'FoodService',
  'publishing_activities': 'Publishing',
  'transport_storage_and_communications': 'Communications',
  'programming_and_broadcasting_activities': 'Broadcasting',
  'computer_programming_consultancyand_relatedactivities': 'Technology',
  'manufacturing_leather__products_thereof': 'Leather',
  'manufacturing_wood_products': 'Wood',
  'manufacture_of_pharmaceuticals_medicinal_chemical_and_botanical_products': 'Pharmaceuticals',
  'activitiesofheadofficesmanagementconsultancyactivities': 'Management',
  'architecture_and_engineering_activities_technical_testing_and_analysis': 'Engineering',
  'scientific_research_and_development': 'Research',
  'human_health_activities': 'Healthcare',
  'social_work_activities_without_accommodation': 'SocialWork',
  'manufacturing_others': 'Manufacturing',
  'unclassified': 'Unclassified',
  'electricity_gas__water_companies': 'Utilities',
  'mining__quarrying': 'Mining',
  'manufacture_of_food_products': 'FoodProducts',
  'manufacturing_food_stuffs': 'FoodProcessing',
  'wholesaletradeexceptofmotorvehiclesandmotorcycles': 'Wholesale',
  'retail_trade_except_of_motor_vehicles_and_motorcycles': 'Retail',
  'rental_and_leasing_activities': 'Leasing',
  'employment_activities': 'Employment',
  'office_administrative_office_support_and': 'Administration',
  'telecommunications': 'Telecommunications',
  'manufacture_of_coke_and_refined_petroleum_products': 'Petroleum',
  'manufacture_of_beverages': 'Beverages',
  'publicadministrationanddefencecompulsory_social_security': 'Government',
  'electricity_gas_steam_and_aircondition_supply': 'Energy',
  'wholesale_and_retail_trade_and_repair_of_motor_vehicles_and_motorcycles': 'Automotive',
  'construction_of_buildings': 'Buildings',
  'civil_engineering': 'Engineering',
  'motion_picture_video_and_television_programme_production_sound_recording_and_music_publishing_activities': 'Media',
  'information_service_activities': 'Information',
  'warehousing_and_support_activities_for_transportation': 'Logistics',
  'legal_and_accounting_activities': 'Legal',
  'financial_service_activities_except_insurance_and_pension_funding': 'Banking',
  'manufacture_of_wearing_apparel': 'Apparel',
  'repair_and_installation_of_machinery_and_equipment': 'Equipment',
  'insurance': 'Insurance',
  'sewerage': 'Sewerage',
  'waste_collection_treatment_and_disposal_activities_materials_recovery': 'WasteManagement',
  'advertising_and_market_research': 'Advertising',
  'manufacture_of_electrical_equipment': 'Electrical',
  'services_to_buildings_and_landscape_activities': 'Landscaping',
  'manufacture_of_paper_and_paper_products': 'Paper',
  'travel_agency_tour_operator_and_other_reservation_service_activities': 'Tourism',
  'manufacture_of_other_nonmetallic_mineral_products': 'Minerals',
  'undifferentiated_goods_and_servicesproducing_activities_of_private_households_for_own_use': 'Household',
  'forestry_and_logging': 'Forestry',
  'remediationactivitiesandotherwastemanagementservices': 'Environmental',
  'manufacture_of_fabricated_metal_products_except_machinery_and_equipment': 'MetalProducts',
  'postal_and_courier_activities': 'Postal',
  'manufacture_of_rubber_and_plastics_products': 'Plastics',
  'fishing_and_aquaculture': 'Fishing',
  'manufacture_of_tobacco_products': 'Tobacco',
  'security_and_investigation_activities': 'Security',
  'extraction_of_crude_petroleum_and_natural_gas': 'Oil',
  'manufacture_of_motor_vehicles_trailers_and_semitrailers': 'Automotive',
  'manufacture_of_leather_and_related_products': 'Leather',
  'printing_and_reproduction_of_recorded_media_this_division_excludes_publishing_activities_see_section_j_for_publishing_activities': 'Printing',
  'creative_arts_and_entertainment_activities': 'Entertainment',
  'mining_of_coal_and_lignite': 'Coal',
  'mining_support_service_activities': 'Mining',
  'water_transport': 'Maritime',
  'air_transport': 'Aviation',
  'mining_of_metal_ores': 'Mining',
  'residential_care_activities': 'Healthcare',
  'repair_of_computers_and_personal_and_household_goods': 'Repair',
  'manufacture_of_furniture': 'Furniture',
  'manufacture_of_chemicals_and_chemical_products': 'Chemicals'
};

// Function to process the updated CSV file and generate the desired output
function processCSV() {
  fs.createReadStream(inputCSVPath)
    .pipe(csv())
    .on('data', (row) => {
      // Only include businesses marked as active (assuming 'CompanyStatus' is the column)
      if (row.CompanyStatus !== 'Active') {
        return; // Skip if the business is not active
      }

      // Create a unique business ID
      const businessId = uuidv4();

      // Add business data to the businesses array
      businesses.push({
        id: businessId,
        name: row.CompanyName,
        description: row.CompanyIndustrialClassification, // Use 'CompanyIndustrialClassification' for description
        address: row.Registered_Office_Address,
        phone: row.Phone || '',
        email: row.Email || '',
        website: row.Website || '',
        rating: 0.0, // Default rating
        is_verified: false, // Default
        is_member: false, // Default
        images: [], // Default empty array
        location: null, // Modify if you have location data
        operating_hours: null, // Modify if you have operating hours data
        is_open: false, // Default
        status: 'pending', // Default
        owner_id: null, // Can be updated later
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      });

      // Get the simplified category name from the mapping
      const simplifiedCategory = categoryMapping[row.simplified_category] || 'TODO';

      // Ensure 'TODO' category exists
      if (simplifiedCategory === 'TODO' && !categories.has('TODO')) {
        const categoryId = uuidv4();
        categories.set(simplifiedCategory, categoryId); 
      }

      // Check if the category is valid and exists in the categories list
      if (simplifiedCategory) {
        if (!categories.has(simplifiedCategory)) {
          // If the category doesn't exist, add it to the categories array
          const categoryId = uuidv4();
          categories.set(simplifiedCategory, categoryId); 
        }

        // Link the business to the category
        businessCategories.push({
          business_id: businessId,
          category_id: categories.get(simplifiedCategory), // Linking to simplified category
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        });
      } else {
        // Log an error if no valid simplified category exists
        errors.push(`Business "${row.CompanyName}" has no matching simplified category.`);
      }
    })
    .on('end', () => {
      // Create a map of categories to their descriptions based on business data
      const categoryDescriptions = {};

      // Loop through businesses and associate each category with a description
      businesses.forEach(business => {
        const categoryName = business.description; // This is where the business category is stored
        const companyIndustrialClassification = business.description; // Assuming description is CompanyIndustrialClassification
        
        // If the category doesn't already have a description, set it
        if (!categoryDescriptions[categoryName]) {
          categoryDescriptions[categoryName] = companyIndustrialClassification;
        }
      });

      // Write the businesses, categories, and mappings CSV files
      writeCSV(businessesCSVPath, businesses, [
        'id', 'name', 'description', 'address', 'phone', 'email', 'website', 'rating', 
        'is_verified', 'is_member', 'images', 'location', 'operating_hours', 'is_open', 
        'status', 'owner_id', 'created_at', 'updated_at'
      ]);

      writeCSV(categoriesCSVPath, Array.from(categories.entries()).map(([name, id]) => ({
        id: id,
        name: name,
        description: name, // You can modify if needed
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })), [
        'id', 'name', 'description', 'created_at', 'updated_at'
      ]);

      writeCSV(mappingsCSVPath, businessCategories, [
        'business_id', 'category_id', 'created_at', 'updated_at'
      ]);
      
      // Log errors if any
      if (errors.length > 0) {
        fs.writeFileSync(errorLogPath, errors.join('\n'));
        console.log(`Errors were logged to ${errorLogPath}`);
      }

      console.log('CSV files generated successfully.');
    });
}

// Helper function to write data to a CSV file
function writeCSV(filePath, data, columns) {
  const header = columns.join(',');
  const rows = data.map(item => columns.map(col => JSON.stringify(item[col] || '')).join(',')).join('\n');
  const csvContent = header + '\n' + rows;

  fs.writeFileSync(filePath, csvContent);
}

// Start processing
processCSV();
