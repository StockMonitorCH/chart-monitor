class StockSearchResult {
  final String symbol;
  final String shortName;
  final String exchange;
  final String quoteType;

  const StockSearchResult({
    required this.symbol,
    required this.shortName,
    required this.exchange,
    required this.quoteType,
  });

  factory StockSearchResult.fromJson(Map<String, dynamic> j) {
    return StockSearchResult(
      symbol: j['symbol'] ?? '',
      shortName: j['shortname'] ?? j['longname'] ?? j['symbol'] ?? '',
      exchange: j['exchDisp'] ?? j['exchange'] ?? '',
      quoteType: j['quoteType'] ?? '',
    );
  }
}

class ChartDataPoint {
  final DateTime time;
  final double close;
  final double? open;
  final double? high;
  final double? low;

  const ChartDataPoint({
    required this.time,
    required this.close,
    this.open,
    this.high,
    this.low,
  });

  bool get hasOhlc => open != null && high != null && low != null;
}

class WatchlistEntry {
  final String symbol;
  final String name;
  final String? sector;
  final double? stopLoss;
  final double? targetPrice;

  const WatchlistEntry({
    required this.symbol,
    required this.name,
    this.sector,
    this.stopLoss,
    this.targetPrice,
  });

  static const _unset = Object();

  WatchlistEntry copyWith({
    String? sector,
    Object? stopLoss = _unset,
    Object? targetPrice = _unset,
  }) {
    return WatchlistEntry(
      symbol: symbol,
      name: name,
      sector: sector ?? this.sector,
      stopLoss: stopLoss == _unset ? this.stopLoss : stopLoss as double?,
      targetPrice: targetPrice == _unset ? this.targetPrice : targetPrice as double?,
    );
  }

  bool get hasAlarm => stopLoss != null || targetPrice != null;
}

enum WatchlistRange { oneDay, oneWeek, oneMonth, threeMonths, sixMonths, ytd, oneYear }

extension WatchlistRangeX on WatchlistRange {
  TimeRange get asTimeRange {
    switch (this) {
      case WatchlistRange.oneDay:      return TimeRange.oneDay;
      case WatchlistRange.oneWeek:     return TimeRange.oneWeek;
      case WatchlistRange.oneMonth:    return TimeRange.oneMonth;
      case WatchlistRange.threeMonths: return TimeRange.threeMonths;
      case WatchlistRange.sixMonths:   return TimeRange.sixMonths;
      case WatchlistRange.ytd:         return TimeRange.ytd;
      case WatchlistRange.oneYear:     return TimeRange.oneYear;
    }
  }
}

enum WatchlistSortMode { manual, nameAZ, nameZA, perfDesc, perfAsc, gics }

class StockInfo {
  final String symbol;
  final String name;
  final double currentPrice;
  final double changePercent;
  final String currency;
  final double? preMarketPrice;
  final double? preMarketChangePct;
  final double? postMarketPrice;
  final double? postMarketChangePct;

  const StockInfo({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.changePercent,
    required this.currency,
    this.preMarketPrice,
    this.preMarketChangePct,
    this.postMarketPrice,
    this.postMarketChangePct,
  });
}

class ChartIndicators {
  final bool showMa20;
  final bool showMa50;
  final bool showMa200;
  final bool showTrendLine;
  final bool showTargetLine;
  final double? analystTarget;

  const ChartIndicators({
    this.showMa20 = false,
    this.showMa50 = false,
    this.showMa200 = false,
    this.showTrendLine = false,
    this.showTargetLine = false,
    this.analystTarget,
  });

  static const none = ChartIndicators();
}

enum TimeRange {
  oneDay,
  oneWeek,
  oneMonth,
  threeMonths,
  sixMonths,
  ytd,
  oneYear,
  twoYears,
  fiveYears,
  max,
  custom,
}

extension TimeRangeParams on TimeRange {
  String get range {
    switch (this) {
      case TimeRange.oneDay: return '1d';
      case TimeRange.oneWeek: return '5d';
      case TimeRange.oneMonth: return '1mo';
      case TimeRange.threeMonths: return '3mo';
      case TimeRange.sixMonths: return '6mo';
      case TimeRange.ytd: return 'ytd';
      case TimeRange.oneYear: return '1y';
      case TimeRange.twoYears: return '2y';
      case TimeRange.fiveYears: return '5y';
      case TimeRange.max: return 'max';
      case TimeRange.custom: return '1y'; // fallback
    }
  }

  String intervalFor(int dayCount) {
    if (dayCount <= 5) return '5m';
    if (dayCount <= 7) return '30m';
    if (dayCount <= 90) return '1d';
    if (dayCount <= 730) return '1wk';
    return '1mo';
  }

  String get interval {
    switch (this) {
      case TimeRange.oneDay: return '5m';
      case TimeRange.oneWeek: return '30m';
      case TimeRange.oneMonth: return '1d';
      case TimeRange.threeMonths: return '1d';
      case TimeRange.sixMonths: return '1d';
      case TimeRange.ytd: return '1d';
      case TimeRange.oneYear: return '1wk';
      case TimeRange.twoYears: return '1d';
      case TimeRange.fiveYears: return '1wk';
      case TimeRange.max: return '1mo';
      case TimeRange.custom: return '1d';
    }
  }

  bool get isIntraday => this == TimeRange.oneDay || this == TimeRange.oneWeek;
}
