class EtfHolding {
  final String symbol;
  final String name;
  final double percent;
  const EtfHolding({required this.symbol, required this.name, required this.percent});
}

class EtfSectorWeight {
  final String sector;
  final double percent;
  const EtfSectorWeight({required this.sector, required this.percent});
}

class CompanyInfo {
  final String symbol;
  final String name;
  final String? sector;
  final String? industry;
  final String? country;
  final String? website;
  final String? ceo;
  final int? employees;
  final String? description;

  // Summary/Valuation
  final double? marketCap;
  final double? peRatio;
  final double? eps;
  final double? dividendYield;
  final double? dividendRate;
  final String? exDividendDate;
  final String? nextEarningsDate;
  final double? beta;
  final double? fiftyTwoWeekHigh;
  final double? fiftyTwoWeekLow;
  final String currency;

  // Dividend history
  final List<DividendEntry> dividendHistory;

  // ETF / Fund
  final String? quoteType;
  final List<EtfHolding> topHoldings;
  final List<EtfSectorWeight> sectorWeightings;

  // Temporary: populated with API debug info to diagnose auth issues
  final String? debugInfo;

  bool get isEtf => quoteType == 'ETF' || quoteType == 'MUTUALFUND';

  const CompanyInfo({
    required this.symbol,
    required this.name,
    required this.currency,
    this.sector,
    this.industry,
    this.country,
    this.website,
    this.ceo,
    this.employees,
    this.description,
    this.marketCap,
    this.peRatio,
    this.eps,
    this.dividendYield,
    this.dividendRate,
    this.exDividendDate,
    this.nextEarningsDate,
    this.beta,
    this.fiftyTwoWeekHigh,
    this.fiftyTwoWeekLow,
    this.dividendHistory = const [],
    this.quoteType,
    this.topHoldings = const [],
    this.sectorWeightings = const [],
    this.debugInfo,
  });
}

class DividendEntry {
  final DateTime date;
  final double amount;

  const DividendEntry({required this.date, required this.amount});
}
