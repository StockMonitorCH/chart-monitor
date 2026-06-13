class IndexEntry {
  final String symbol;
  final String name;
  final String region;
  const IndexEntry(this.symbol, this.name, this.region);

  // Short label for bar chart axis (strips ^, max 7 chars)
  String get shortLabel =>
      symbol.replaceAll('^', '').substring(0, symbol.replaceAll('^', '').length.clamp(0, 7));
}

const kIndices = [
  IndexEntry('^SSMI',     'SMI',           'CH'),
  IndexEntry('^GDAXI',    'DAX',           'DE'),
  IndexEntry('^STOXX50E', 'Euro Stoxx 50', 'EU'),
  IndexEntry('^FCHI',     'CAC 40',        'EU'),
  IndexEntry('^IBEX',     'IBEX 35',       'EU'),
  IndexEntry('^FTSE',     'FTSE 100',      'UK'),
  IndexEntry('^GSPC',     'S&P 500',       'US'),
  IndexEntry('^NDX',      'NASDAQ 100',    'US'),
  IndexEntry('^DJI',      'Dow Jones',     'US'),
  IndexEntry('^RUT',      'Russell 2000',  'US'),
  IndexEntry('^N225',     'Nikkei 225',    'JP'),
  IndexEntry('^HSI',      'Hang Seng',     'HK'),
  IndexEntry('^AXJO',     'ASX 200',       'AU'),
  IndexEntry('^BSESN',    'BSE SENSEX',    'IN'),
  IndexEntry('^KS11',     'KOSPI',         'KR'),
];
