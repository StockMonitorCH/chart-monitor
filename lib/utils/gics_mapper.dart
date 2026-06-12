/// Maps Yahoo Finance sector/industry names to official GICS terminology.
class GicsMapper {
  static String sector(String? raw) {
    if (raw == null || raw.isEmpty) return raw ?? '';
    return _sectors[raw] ?? raw;
  }

  static String industry(String? raw) {
    if (raw == null || raw.isEmpty) return raw ?? '';
    return _industries[raw] ?? raw;
  }

  /// Converts ETF sector keys (lowercase, underscored) to GICS sector names.
  static String etfSector(String key) {
    return _etfSectorKeys[key.toLowerCase()] ??
        key.split('_').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  static const _etfSectorKeys = <String, String>{
    'technology': 'Information Technology',
    'consumer_cyclical': 'Consumer Discretionary',
    'financial_services': 'Financials',
    'consumer_defensive': 'Consumer Staples',
    'healthcare': 'Health Care',
    'industrials': 'Industrials',
    'communication_services': 'Communication Services',
    'energy': 'Energy',
    'basic_materials': 'Materials',
    'real_estate': 'Real Estate',
    'realestate': 'Real Estate',
    'utilities': 'Utilities',
  };

  // ── Sector mapping ───────────────────────────────────────────────────────
  static const _sectors = <String, String>{
    'Technology': 'Information Technology',
    'Consumer Cyclical': 'Consumer Discretionary',
    'Consumer Defensive': 'Consumer Staples',
    'Healthcare': 'Health Care',
    'Financial Services': 'Financials',
    'Basic Materials': 'Materials',
    // The following are already GICS-conformant:
    // 'Communication Services', 'Energy', 'Industrials', 'Real Estate', 'Utilities'
  };

  // ── Industry mapping ─────────────────────────────────────────────────────
  static const _industries = <String, String>{
    // Information Technology
    'Semiconductors': 'Semiconductors & Semiconductor Equipment',
    'Semiconductor Equipment & Materials': 'Semiconductors & Semiconductor Equipment',
    'Software—Application': 'Software',
    'Software—Infrastructure': 'Software',
    'Software - Application': 'Software',
    'Software - Infrastructure': 'Software',
    'Information Technology Services': 'IT Services',
    'Consumer Electronics': 'Technology Hardware, Storage & Peripherals',
    'Computer Hardware': 'Technology Hardware, Storage & Peripherals',
    'Electronic Components': 'Electronic Equipment, Instruments & Components',
    'Electronics & Computer Distribution': 'Technology Distributors',
    'Scientific & Technical Instruments': 'Electronic Equipment, Instruments & Components',

    // Health Care
    'Drug Manufacturers—General': 'Pharmaceuticals',
    'Drug Manufacturers—Specialty & Generic': 'Pharmaceuticals',
    'Drug Manufacturers - General': 'Pharmaceuticals',
    'Drug Manufacturers - Specialty & Generic': 'Pharmaceuticals',
    'Biotechnology': 'Biotechnology',
    'Medical Devices': 'Health Care Equipment & Supplies',
    'Medical Instruments & Supplies': 'Health Care Equipment & Supplies',
    'Health Care Plans': 'Health Care Providers & Services',
    'Hospitals': 'Health Care Providers & Services',
    'Medical Care Facilities': 'Health Care Providers & Services',
    'Diagnostics & Research': 'Life Sciences Tools & Services',
    'Health Information Services': 'Health Care Technology',
    'Medical Distribution': 'Health Care Distributors',
    'Pharmaceutical Retailers': 'Health Care Distributors',

    // Financials
    'Banks—Regional': 'Regional Banks',
    'Banks—Diversified': 'Diversified Banks',
    'Banks - Regional': 'Regional Banks',
    'Banks - Diversified': 'Diversified Banks',
    'Insurance—Diversified': 'Multi-line Insurance',
    'Insurance—Life': 'Life & Health Insurance',
    'Insurance—Property & Casualty': 'Property & Casualty Insurance',
    'Insurance—Specialty': 'Specialty Insurance',
    'Insurance—Reinsurance': 'Reinsurance',
    'Insurance - Diversified': 'Multi-line Insurance',
    'Insurance - Life': 'Life & Health Insurance',
    'Insurance - Property & Casualty': 'Property & Casualty Insurance',
    'Asset Management': 'Asset Management & Custody Banks',
    'Asset Management—Leveraged': 'Asset Management & Custody Banks',
    'Financial Data & Stock Exchanges': 'Financial Exchanges & Data',
    'Credit Services': 'Consumer Finance',
    'Capital Markets': 'Capital Markets',
    'Mortgage Finance': 'Thrifts & Mortgage Finance',
    'Financial Conglomerates': 'Diversified Financial Services',
    'Shell Companies': 'Diversified Financial Services',

    // Consumer Discretionary
    'Auto Manufacturers': 'Automobile Manufacturers',
    'Auto Parts': 'Auto Components',
    'Auto & Truck Dealerships': 'Automotive Retail',
    'Apparel Retail': 'Apparel Retail',
    'Apparel Manufacturing': 'Apparel, Accessories & Luxury Goods',
    'Luxury Goods': 'Apparel, Accessories & Luxury Goods',
    'Internet Retail': 'Internet & Direct Marketing Retail',
    'Specialty Retail': 'Specialty Stores',
    'Department Stores': 'Department Stores',
    'Home Improvement Retail': 'Home Improvement Retail',
    'Furniture, Fixtures & Appliances': 'Housewares & Specialties',
    'Restaurants': 'Restaurants',
    'Resorts & Casinos': 'Casinos & Gaming',
    'Gambling': 'Casinos & Gaming',
    'Hotels': 'Hotels, Resorts & Cruise Lines',
    'Travel Services': 'Hotels, Resorts & Cruise Lines',
    'Leisure': 'Leisure Products',
    'Recreational Vehicles': 'Leisure Products',
    'Personal Services': 'Personal Services',
    'Publishing': 'Publishing',
    'Broadcasting': 'Broadcasting',
    'Entertainment': 'Entertainment',
    'Media - Diversified': 'Movies & Entertainment',

    // Consumer Staples
    'Beverages—Non-Alcoholic': 'Soft Drinks & Non-alcoholic Beverages',
    'Beverages—Alcoholic': 'Beverages',
    'Beverages—Brewers': 'Brewers',
    'Beverages - Non-Alcoholic': 'Soft Drinks & Non-alcoholic Beverages',
    'Beverages - Alcoholic': 'Beverages',
    'Food Distribution': 'Food Distributors',
    'Grocery Stores': 'Food Retail',
    'Household & Personal Products': 'Personal Products',
    'Household Products': 'Household Products',
    'Personal Products': 'Personal Products',
    'Tobacco': 'Tobacco',
    'Packaged Foods': 'Packaged Foods & Meats',
    'Confectioners': 'Packaged Foods & Meats',
    'Farm Products': 'Agricultural Products & Services',
    'Agricultural Inputs': 'Agricultural Products & Services',
    'Discount Stores': 'General Merchandise Stores',

    // Energy
    'Oil & Gas E&P': 'Oil, Gas & Consumable Fuels',
    'Oil & Gas Integrated': 'Integrated Oil & Gas',
    'Oil & Gas Midstream': 'Oil, Gas & Consumable Fuels',
    'Oil & Gas Refining & Marketing': 'Oil, Gas & Consumable Fuels',
    'Oil & Gas Equipment & Services': 'Oil & Gas Equipment & Services',
    'Coal': 'Oil, Gas & Consumable Fuels',
    'Uranium': 'Oil, Gas & Consumable Fuels',
    'Oil & Gas Drilling': 'Oil & Gas Equipment & Services',

    // Industrials
    'Aerospace & Defense': 'Aerospace & Defense',
    'Airlines': 'Airlines',
    'Airports & Air Services': 'Transportation Infrastructure',
    'Trucking': 'Trucking',
    'Railroads': 'Railroads',
    'Marine Shipping': 'Marine Transportation',
    'Integrated Freight & Logistics': 'Air Freight & Logistics',
    'Air Delivery & Freight Services': 'Air Freight & Logistics',
    'Waste Management': 'Environmental & Facilities Services',
    'Pollution & Treatment Controls': 'Environmental & Facilities Services',
    'Staffing & Employment Services': 'Human Resource & Employment Services',
    'Security & Protection Services': 'Security & Alarm Services',
    'Industrial Distribution': 'Trading Companies & Distributors',
    'Building Products & Equipment': 'Building Products',
    'Engineering & Construction': 'Construction & Engineering',
    'Farm & Heavy Construction Machinery': 'Construction Machinery & Heavy Equipment',
    'Industrial Machinery': 'Industrial Machinery & Supplies & Components',
    'Specialty Industrial Machinery': 'Industrial Machinery & Supplies & Components',
    'Conglomerates': 'Industrial Conglomerates',
    'Electrical Equipment & Parts': 'Electrical Equipment',
    'Business Equipment & Supplies': 'Office Services & Supplies',
    'Consulting Services': 'Research & Consulting Services',
    'Rental & Leasing Services': 'Commercial Services & Supplies',
    'Printing Services': 'Commercial Printing',

    // Communication Services
    'Telecom Services': 'Diversified Telecommunication Services',
    'Telephone Companies': 'Diversified Telecommunication Services',
    'Wireless Communications': 'Wireless Telecommunication Services',
    'Internet Content & Information': 'Interactive Media & Services',
    'Electronic Gaming & Multimedia': 'Interactive Home Entertainment',
    'Advertising Agencies': 'Advertising',

    // Materials
    'Steel': 'Steel',
    'Chemicals': 'Commodity Chemicals',
    'Specialty Chemicals': 'Specialty Chemicals',
    'Gold': 'Gold',
    'Silver': 'Precious Metals & Minerals',
    'Copper': 'Metals & Mining',
    'Aluminum': 'Aluminum',
    'Other Precious Metals & Mining': 'Precious Metals & Minerals',
    'Other Industrial Metals & Mining': 'Metals & Mining',
    'Paper & Paper Products': 'Paper & Forest Products',
    'Packaging & Containers': 'Metal & Glass Containers',
    'Lumber & Wood Production': 'Paper & Forest Products',
    'Building Materials': 'Construction Materials',
    'Agricultural Chemicals': 'Specialty Chemicals',
    'Coking Coal': 'Metals & Mining',

    // Real Estate
    'REIT—Office': 'Office REITs',
    'REIT—Retail': 'Retail REITs',
    'REIT—Residential': 'Residential REITs',
    'REIT—Industrial': 'Industrial REITs',
    'REIT—Healthcare Facilities': 'Health Care REITs',
    'REIT—Hotel & Motel': 'Hotel & Resort REITs',
    'REIT—Diversified': 'Diversified REITs',
    'REIT—Specialty': 'Specialized REITs',
    'REIT—Mortgage': 'Mortgage REITs',
    'REIT - Office': 'Office REITs',
    'REIT - Retail': 'Retail REITs',
    'REIT - Residential': 'Residential REITs',
    'REIT - Industrial': 'Industrial REITs',
    'REIT - Healthcare Facilities': 'Health Care REITs',
    'REIT - Diversified': 'Diversified REITs',
    'REIT - Specialty': 'Specialized REITs',
    'REIT - Mortgage': 'Mortgage REITs',
    'Real Estate Services': 'Real Estate Services',
    'Real Estate—Development': 'Real Estate Operating Companies',
    'Real Estate - Development': 'Real Estate Operating Companies',
    'Real Estate—Diversified': 'Diversified Real Estate Activities',

    // Utilities
    'Utilities—Regulated Electric': 'Electric Utilities',
    'Utilities—Regulated Gas': 'Gas Utilities',
    'Utilities—Regulated Water': 'Water Utilities',
    'Utilities—Diversified': 'Multi-Utilities',
    'Utilities—Independent Power Producers': 'Independent Power Producers & Energy Traders',
    'Utilities—Renewable': 'Independent Power Producers & Energy Traders',
    'Utilities - Regulated Electric': 'Electric Utilities',
    'Utilities - Regulated Gas': 'Gas Utilities',
    'Utilities - Regulated Water': 'Water Utilities',
    'Utilities - Diversified': 'Multi-Utilities',
    'Utilities - Independent Power Producers': 'Independent Power Producers & Energy Traders',
    'Utilities - Renewable': 'Independent Power Producers & Energy Traders',
  };
}
