// S&P 500 constituents (approximate, as of mid-2025)
const List<String> kSp500Symbols = [
  'MMM',  'AOS',  'ABT',  'ABBV', 'ACN',  'ADBE', 'AMD',  'AES',  'AFL',  'A',
  'APD',  'ABNB', 'AKAM', 'ALB',  'ARE',  'ALGN', 'ALLE', 'LNT',  'ALL',  'GOOGL',
  'GOOG', 'MO',   'AMZN', 'AMCR', 'AEE',  'AEP',  'AXP',  'AIG',  'AMT',  'AWK',
  'AMP',  'AME',  'AMGN', 'APH',  'ADI',  'ANSS', 'AON',  'APA',  'AAPL', 'AMAT',
  'APTV', 'ACGL', 'ADM',  'ANET', 'AJG',  'AIZ',  'T',    'ATO',  'ADSK', 'ADP',
  'AZO',  'AVB',  'AVY',  'AXON', 'BKR',  'BALL', 'BAC',  'BAX',  'BDX',  'WRB',
  'BBY',  'BIIB', 'BLK',  'BX',   'BK',   'BA',   'BKNG', 'BWA',  'BSX',  'BMY',
  'AVGO', 'BR',   'BRO',  'BLDR', 'BG',   'CDNS', 'CZR',  'CPT',  'CPB',  'COF',
  'CAH',  'KMX',  'CCL',  'CARR', 'CAT',  'CBOE', 'CBRE', 'CDW',  'CE',   'COR',
  'CNC',  'CDAY', 'CF',   'CRL',  'SCHW', 'CHTR', 'CVX',  'CMG',  'CB',   'CHD',
  'CI',   'CINF', 'CTAS', 'CSCO', 'C',    'CFG',  'CLX',  'CME',  'CMS',  'KO',
  'CTSH', 'CL',   'CMCSA','CAG',  'COP',  'ED',   'STZ',  'CEG',  'COO',  'CPRT',
  'GLW',  'CPAY', 'COST', 'CTRA', 'CRWD', 'CCI',  'CSX',  'CMI',  'CVS',  'DHR',
  'DRI',  'DVA',  'DE',   'DELL', 'DAL',  'DVN',  'DXCM', 'FANG', 'DLR',  'DFS',
  'DG',   'DLTR', 'D',    'DPZ',  'DOV',  'DTE',  'DUK',  'DD',   'EMN',  'ETN',
  'EBAY', 'ECL',  'EIX',  'EW',   'EA',   'ELV',  'EMR',  'ENPH', 'ETR',  'EOG',
  'EPAM', 'EQT',  'EFX',  'EQIX', 'EQR',  'ESS',  'EL',   'ETSY', 'EG',   'EXAS',
  'EXPE', 'EXPD', 'EXR',  'XOM',  'FFIV', 'FDS',  'FICO', 'FAST', 'FRT',  'FDX',
  'FIS',  'FITB', 'FSLR', 'FE',   'FI',   'F',    'FTNT', 'FTV',  'FOXA', 'FOX',
  'BEN',  'FCX',  'GRMN', 'IT',   'GE',   'GEHC', 'GEV',  'GEN',  'GNRC', 'GD',
  'GIS',  'GM',   'GPC',  'GILD', 'GS',   'HAL',  'HIG',  'HAS',  'HCA',  'DOC',
  'HSIC', 'HSY',  'HES',  'HPE',  'HLT',  'HOLX', 'HD',   'HON',  'HRL',  'HST',
  'HWM',  'HPQ',  'HUBB', 'HUM',  'HBAN', 'HII',  'IBM',  'IEX',  'IDXX', 'ITW',
  'INCY', 'IR',   'ICE',  'IP',   'IPG',  'ISRG', 'IVZ',  'INVH', 'IQV',  'IRM',
  'JBHT', 'JBL',  'JKHY', 'J',    'JNJ',  'JCI',  'JPM',  'JNPR', 'K',    'KVUE',
  'KDP',  'KEY',  'KEYS', 'KMB',  'KIM',  'KMI',  'KLAC', 'KHC',  'KR',   'LHX',
  'LH',   'LRCX', 'LW',   'LVS',  'LDOS', 'LEN',  'LLY',  'LIN',  'LYV',  'LKQ',
  'LMT',  'L',    'LOW',  'LULU', 'LYB',  'MTB',  'MRO',  'MPC',  'MKTX', 'MAR',
  'MMC',  'MLM',  'MAS',  'MA',   'MTCH', 'MKC',  'MCD',  'MCK',  'MDT',  'MRK',
  'META', 'MET',  'MTD',  'MGM',  'MCHP', 'MU',   'MSFT', 'MAA',  'MRNA', 'MHK',
  'MOH',  'TAP',  'MDLZ', 'MPWR', 'MNST', 'MCO',  'MS',   'MOS',  'MSI',  'MSCI',
  'NDAQ', 'NTAP', 'NFLX', 'NEM',  'NWSA', 'NWS',  'NEE',  'NKE',  'NI',   'NDSN',
  'NSC',  'NTRS', 'NOC',  'NCLH', 'NRG',  'NUE',  'NVDA', 'NVR',  'NXPI', 'ORLY',
  'OXY',  'ODFL', 'OMC',  'ON',   'OKE',  'ORCL', 'OTIS', 'PCAR', 'PKG',  'PLTR',
  'PANW', 'PH',   'PAYX', 'PAYC', 'PYPL', 'PNR',  'PEP',  'PFE',  'PCG',  'PM',
  'PSX',  'PNW',  'PNC',  'POOL', 'PPG',  'PPL',  'PFG',  'PG',   'PGR',  'PLD',
  'PRU',  'PEG',  'PTC',  'PSA',  'PHM',  'PWR',  'QCOM', 'DGX',  'RL',   'RJF',
  'RTX',  'O',    'REG',  'REGN', 'RF',   'RSG',  'RMD',  'RVTY', 'ROK',  'ROL',
  'ROP',  'ROST', 'RCL',  'SPGI', 'CRM',  'SBAC', 'SLB',  'STX',  'SRE',  'NOW',
  'SHW',  'SPG',  'SWKS', 'SJM',  'SW',   'SNA',  'SOLV', 'SO',   'LUV',  'SWK',
  'SBUX', 'STT',  'STLD', 'STE',  'SYK',  'SYF',  'SNPS', 'SYY',  'TMUS', 'TROW',
  'TTWO', 'TPR',  'TRGP', 'TGT',  'TEL',  'TDY',  'TFX',  'TER',  'TSLA', 'TXN',
  'TXT',  'TMO',  'TJX',  'TSCO', 'TT',   'TDG',  'TRV',  'TRMB', 'TFC',  'TYL',
  'TSN',  'USB',  'UBER', 'UDR',  'UHS',  'UNP',  'UAL',  'UPS',  'URI',  'UNH',
  'VLO',  'VTR',  'VLTO', 'VRSN', 'VRSK', 'VZ',   'VRTX', 'V',    'VST',  'VNO',
  'VTRS', 'VICI', 'VMC',  'WAB',  'WBA',  'WMT',  'DIS',  'WBD',  'WM',   'WAT',
  'WEC',  'WFC',  'WELL', 'WST',  'WDC',  'WY',   'WHR',  'WMB',  'WTW',  'GWW',
  'WYNN', 'XEL',  'XYL',  'YUM',  'ZBRA', 'ZBH',  'ZTS',  'APO',  'SMCI', 'DAY',
  'CTLT', 'TECH', 'BF.B', 'CNX',  'CMA',  'VNT',  'VIAV', 'NWS',
];

// NASDAQ 100 constituents (approximate, as of mid-2025)
// Many symbols overlap with S&P 500 — use screenerUniverse() to get a deduped list.
const List<String> kNasdaq100Symbols = [
  'MSFT', 'AAPL', 'NVDA', 'AMZN', 'META', 'TSLA', 'GOOGL', 'GOOG', 'AVGO', 'COST',
  'NFLX', 'AMD',  'CSCO', 'ADBE', 'QCOM', 'INTU', 'PEP',  'TMUS', 'TXN',  'AMAT',
  'HON',  'ISRG', 'AMGN', 'BKNG', 'VRTX', 'REGN', 'SBUX', 'ADI',  'MU',   'KLAC',
  'MDLZ', 'LRCX', 'PANW', 'GILD', 'SNPS', 'CDNS', 'CTAS', 'ASML', 'MRVL', 'INTC',
  'MELI', 'PYPL', 'ORLY', 'MNST', 'FTNT', 'NXPI', 'CHTR', 'WDAY', 'ABNB', 'DXCM',
  'ADSK', 'MCHP', 'PAYX', 'AEP',  'FAST', 'VRSK', 'CSX',  'EXC',  'ODFL', 'KDP',
  'IDXX', 'CPRT', 'ROP',  'ROST', 'EA',   'BIIB', 'CEG',  'KHC',  'GEHC', 'ON',
  'FANG', 'CTSH', 'DLTR', 'BKR',  'ANSS', 'NDAQ', 'DDOG', 'ZS',   'TTWO', 'XEL',
  'ILMN', 'MRNA', 'WBD',  'ALGN', 'ARM',  'DASH', 'TEAM', 'TTD',  'SMCI', 'CSGP',
  'SIRI', 'CCEP', 'CDW',  'PCAR', 'CRWD', 'SBAC', 'SPLK', 'GFS',  'LULU', 'RIVN',
];

// Popular US stocks beyond S&P 500 and NASDAQ 100 — innovative / high-growth
const List<String> kExtendedSymbols = [
  // Cloud / SaaS
  'NET',  'SNOW', 'MDB',  'OKTA', 'DOCN', 'BILL', 'FOUR', 'GTLB', 'PD',   'ZI',
  'DOMO', 'APPN', 'SMAR', 'VERX', 'FROG', 'S',    'AEHR', 'BASE', 'PCVX', 'PCOR',
  // AI / Quantum Computing
  'IONQ', 'QUBT', 'RGTI', 'QBTS', 'ARQQ', 'SOUN', 'BBAI', 'AI',  'PATH', 'BTAI',
  'URGN', 'MSAI', 'INTA', 'QLYS', 'KALI', 'BFLY', 'GFAI', 'SIFY','CXAI', 'AIXI',
  // EV / Clean Energy
  'RIVN', 'LCID', 'NIO',  'LI',   'XPEV', 'BLNK', 'CHPT', 'EVGO', 'BE',  'PLUG',
  'FCEL', 'ARRY', 'NOVA', 'RUN',  'STEM', 'MAXN', 'SPWR', 'QS',   'NKLA','ZEV',
  'AMPS', 'PTRA', 'AEVA', 'LAZR', 'MVIS', 'LIDR', 'INVZ', 'OUST', 'VLDR','AEYE',
  // Space / Aviation / Defense Tech
  'RKLB', 'ASTS', 'LUNR', 'ACHR', 'JOBY', 'SPCE', 'IRDM', 'SATL', 'MNTS','RCAT',
  'KTOS', 'AVAV', 'BWXT', 'CACI', 'LDOS', 'HII',  'CW',   'TDY',  'AXON','SWBI',
  // Crypto / Blockchain / Fintech
  'COIN', 'MSTR', 'MARA', 'RIOT', 'CLSK', 'HUT',  'BTBT', 'BITF', 'IREN','WULF',
  'HOOD', 'SOFI', 'AFRM', 'UPST', 'NRDS', 'DAVE', 'MQ',   'RELY', 'SEZL','LMND',
  // Biotech / Gene Editing
  'NVAX', 'BNTX', 'BEAM', 'EDIT', 'CRSP', 'NTLA', 'VERV', 'FATE', 'NKTX','KYMR',
  'RCKT', 'FOLD', 'IOVA', 'CYTK', 'SRPT', 'ALEC', 'SAGE', 'AGEN', 'IMVT','ZNTL',
  'HALO', 'ACAD', 'DNLI', 'ARCT', 'TBPH', 'PTGX', 'TGTX', 'ARDX', 'ADMA','IMNM',
  // Gaming / Social / Media / Consumer
  'RBLX', 'SPOT', 'RDDT', 'SNAP', 'PINS', 'DUOL', 'BMBL', 'MTTR', 'DKNG','PENN',
  'CVNA', 'RVLV', 'W',    'PRTS', 'BARK', 'SONO', 'LMND', 'ROOT', 'HCI', 'PSFE',
  // Semiconductors / Hardware (mid-cap)
  'WOLF', 'SITM', 'AEIS', 'FORM', 'ACLS', 'ONTO', 'AZTA', 'CRUS', 'DIOD','AMBA',
  'POWI', 'ALGM', 'MPWR', 'SKYW', 'RMBS', 'SLAB', 'SMTC', 'VICR', 'POWI','IXYS',
];

/// Returns the deduplicated screener universe for the given mode:
///   0 = S&P 500 only
///   1 = S&P 500 + NASDAQ 100
///   2 = S&P 500 + NASDAQ 100 + Popular US stocks (extended)
List<String> screenerUniverse({int mode = 0}) {
  if (mode == 0) return kSp500Symbols;
  final seen = <String>{};
  final base = [...kSp500Symbols, ...kNasdaq100Symbols];
  if (mode == 2) base.addAll(kExtendedSymbols);
  return base.where(seen.add).toList();
}
