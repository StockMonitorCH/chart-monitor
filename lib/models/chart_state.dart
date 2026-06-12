import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'stock_data.dart';
import '../services/yahoo_finance_service.dart';
import '../services/alarm_service.dart';

class ChartState extends ChangeNotifier {
  final _service = YahooFinanceService();

  static const _kSym1 = 'stock1_symbol';
  static const _kSym2 = 'stock2_symbol';
  static const _kWatchlist = 'cm_watchlist';
  static const _kWlRange = 'wl_range';
  static const _kWlSort = 'wl_sort';
  static const _kRange = 'chart_range';
  static const _kCandlestick = 'chart_candlestick';
  static const _kMa20 = 'chart_ma20';
  static const _kMa50 = 'chart_ma50';
  static const _kMa200 = 'chart_ma200';
  static const _kTrend = 'chart_trend';
  static const _kTarget = 'chart_target';

  TimeRange selectedRange = TimeRange.oneMonth;

  DateTime? customStart;
  DateTime? customEnd;

  StockInfo? stock1Info;
  StockInfo? stock2Info;
  List<ChartDataPoint> stock1Data = [];
  List<ChartDataPoint> stock2Data = [];

  bool loadingStock1 = false;
  bool loadingStock2 = false;
  String? errorStock1;
  String? errorStock2;

  double? stock1PeriodChangePercent;
  double? stock1PeriodChangeAbsolute;
  double? stock2PeriodChangePercent;
  double? stock2PeriodChangeAbsolute;

  double? analystTargetPrice;
  List<ChartDataPoint> stock1MaData = [];

  bool _candlestick = false;
  bool get candlestick => _candlestick;

  bool _showMa20 = false;
  bool _showMa50 = false;
  bool _showMa200 = false;
  bool _showTrendLine = false;
  bool _showTargetLine = false;

  bool get showMa20 => _showMa20;
  bool get showMa50 => _showMa50;
  bool get showMa200 => _showMa200;
  bool get showTrendLine => _showTrendLine;
  bool get showTargetLine => _showTargetLine;

  void toggleMa20() { _showMa20 = !_showMa20; notifyListeners(); _savePrefs(); }
  void toggleMa50() { _showMa50 = !_showMa50; notifyListeners(); _savePrefs(); }
  void toggleMa200() { _showMa200 = !_showMa200; notifyListeners(); _savePrefs(); }
  void toggleTrendLine() { _showTrendLine = !_showTrendLine; notifyListeners(); _savePrefs(); }
  void toggleTargetLine() { _showTargetLine = !_showTargetLine; notifyListeners(); _savePrefs(); }

  ChartIndicators get indicators => ChartIndicators(
    showMa20: _showMa20,
    showMa50: _showMa50,
    showMa200: _showMa200,
    showTrendLine: _showTrendLine,
    showTargetLine: _showTargetLine,
    analystTarget: analystTargetPrice,
  );

  List<WatchlistEntry> _watchlist = [];
  List<WatchlistEntry> get watchlist => List.unmodifiable(_watchlist);

  WatchlistRange _watchlistRange = WatchlistRange.oneDay;
  WatchlistRange get watchlistRange => _watchlistRange;

  WatchlistSortMode _watchlistSortMode = WatchlistSortMode.manual;
  WatchlistSortMode get watchlistSortMode => _watchlistSortMode;

  bool isInWatchlist(String symbol) =>
      _watchlist.any((e) => e.symbol == symbol);

  void setWatchlistRange(WatchlistRange range) {
    _watchlistRange = range;
    notifyListeners();
    _savePrefs();
  }

  void setWatchlistSortMode(WatchlistSortMode mode) {
    _watchlistSortMode = mode;
    notifyListeners();
    _savePrefs();
  }

  Future<void> toggleWatchlist(String symbol, String name) async {
    if (isInWatchlist(symbol)) {
      _watchlist.removeWhere((e) => e.symbol == symbol);
    } else {
      _watchlist.add(WatchlistEntry(symbol: symbol, name: name));
      // ignore: unawaited_futures
      _fetchAndCacheSector(symbol);
    }
    notifyListeners();
    await _saveWatchlist();
    // ignore: unawaited_futures
    AlarmService.updateSchedule(_watchlist.any((e) => e.hasAlarm));
  }

  Future<void> updateAlarm(String symbol, double? stopLoss, double? targetPrice) async {
    final idx = _watchlist.indexWhere((e) => e.symbol == symbol);
    if (idx < 0) return;
    _watchlist[idx] = _watchlist[idx].copyWith(stopLoss: stopLoss, targetPrice: targetPrice);
    notifyListeners();
    await _saveWatchlist();
    // ignore: unawaited_futures
    AlarmService.updateSchedule(_watchlist.any((e) => e.hasAlarm));
  }

  Future<void> fetchMissingSectors() async {
    final missing = _watchlist.where((e) => e.sector == null).toList();
    if (missing.isEmpty) return;
    await Future.wait(missing.map((e) => _fetchAndCacheSector(e.symbol)));
  }

  Future<void> _fetchAndCacheSector(String symbol) async {
    try {
      final sector = await _service.fetchSector(symbol);
      if (sector == null) return;
      final idx = _watchlist.indexWhere((e) => e.symbol == symbol);
      if (idx < 0) return;
      _watchlist[idx] = _watchlist[idx].copyWith(sector: sector);
      await _saveWatchlist();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kWatchlist) ?? [];
    _watchlist = raw.map(_parseWatchlistEntry).toList();
  }

  static WatchlistEntry _parseWatchlistEntry(String s) {
    final parts = s.split('|');
    return WatchlistEntry(
      symbol: parts[0],
      name: parts.length > 1 ? parts[1] : parts[0],
      sector: parts.length > 2 && parts[2] != '-' ? parts[2] : null,
      stopLoss: parts.length > 3 && parts[3] != '-' ? double.tryParse(parts[3]) : null,
      targetPrice: parts.length > 4 && parts[4] != '-' ? double.tryParse(parts[4]) : null,
    );
  }

  Future<void> _saveWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kWatchlist, _watchlist.map((e) {
      final sl = e.stopLoss?.toString() ?? '-';
      final tp = e.targetPrice?.toString() ?? '-';
      return '${e.symbol}|${e.name}|${e.sector ?? '-'}|$sl|$tp';
    }).toList());
  }

  // Candlestick: all ranges except 1D (1W with 30min candles is valid)
  bool get canUseCandlestick =>
      stock2Info == null &&
      selectedRange != TimeRange.oneDay &&
      stock1Data.any((p) => p.hasOhlc);

  void toggleCandlestick() {
    _candlestick = !_candlestick;
    notifyListeners();
    _savePrefs();
  }

  void _clampCandlestick() {
    if (_candlestick && !canUseCandlestick) {
      _candlestick = false;
    }
  }

  ChartState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreFromPrefs());
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (stock1Info != null) {
      await prefs.setString(_kSym1, stock1Info!.symbol);
    } else {
      await prefs.remove(_kSym1);
    }
    if (stock2Info != null) {
      await prefs.setString(_kSym2, stock2Info!.symbol);
    } else {
      await prefs.remove(_kSym2);
    }
    await prefs.setInt(_kWlRange, _watchlistRange.index);
    await prefs.setInt(_kWlSort, _watchlistSortMode.index);
    await prefs.setInt(_kRange, selectedRange.index);
    await prefs.setBool(_kCandlestick, _candlestick);
    await prefs.setBool(_kMa20, _showMa20);
    await prefs.setBool(_kMa50, _showMa50);
    await prefs.setBool(_kMa200, _showMa200);
    await prefs.setBool(_kTrend, _showTrendLine);
    await prefs.setBool(_kTarget, _showTargetLine);
  }

  Future<void> _restoreFromPrefs() async {
    await _loadWatchlist();
    final prefs = await SharedPreferences.getInstance();
    final rangeIdx = prefs.getInt(_kWlRange) ?? 0;
    _watchlistRange = WatchlistRange.values[rangeIdx.clamp(0, WatchlistRange.values.length - 1)];
    final sortIdx = prefs.getInt(_kWlSort) ?? 0;
    _watchlistSortMode = WatchlistSortMode.values[sortIdx.clamp(0, WatchlistSortMode.values.length - 1)];
    // Restore chart settings (range first – loadStock1 uses selectedRange)
    final chartRangeIdx = prefs.getInt(_kRange) ?? TimeRange.oneMonth.index;
    selectedRange = TimeRange.values[chartRangeIdx.clamp(0, TimeRange.values.length - 1)];
    _candlestick = prefs.getBool(_kCandlestick) ?? false;
    _showMa20 = prefs.getBool(_kMa20) ?? false;
    _showMa50 = prefs.getBool(_kMa50) ?? false;
    _showMa200 = prefs.getBool(_kMa200) ?? false;
    _showTrendLine = prefs.getBool(_kTrend) ?? false;
    _showTargetLine = prefs.getBool(_kTarget) ?? false;
    final sym1 = prefs.getString(_kSym1);
    final sym2 = prefs.getString(_kSym2);
    if (sym1 != null) {
      await loadStock1(sym1);
      if (sym2 != null) await loadStock2(sym2);
    }
  }

  void _calcPeriodPerformance() {
    stock1PeriodChangePercent = _calcPct(stock1Data);
    stock1PeriodChangeAbsolute = _calcAbs(stock1Data);
    stock2PeriodChangePercent = _calcPct(stock2Data);
    stock2PeriodChangeAbsolute = _calcAbs(stock2Data);
  }

  double? _calcPct(List<ChartDataPoint> data) {
    if (data.length < 2) return null;
    final first = data.first.close;
    final last = data.last.close;
    if (first == 0) return null;
    return (last - first) / first * 100;
  }

  double? _calcAbs(List<ChartDataPoint> data) {
    if (data.length < 2) return null;
    return data.last.close - data.first.close;
  }

  Future<void> loadStock1(String symbol) async {
    loadingStock1 = true;
    errorStock1 = null;
    notifyListeners();
    try {
      stock1Info = await _service.fetchStockInfo(symbol);
      stock1Data = await _service.fetchChartData(
        symbol, selectedRange,
        customStart: customStart, customEnd: customEnd,
      );
      _calcPeriodPerformance();
      analystTargetPrice = null;
      stock1MaData = [];
      // ignore: unawaited_futures
      _fetchAnalystTarget(symbol);
      // ignore: unawaited_futures
      _fetchMaWarmupData(symbol);
      _savePrefs();
    } catch (e) {
      errorStock1 = e.toString();
      stock1Data = [];
      stock1Info = null;
    }
    loadingStock1 = false;
    _clampCandlestick();
    notifyListeners();
  }

  Future<void> _fetchMaWarmupData(String symbol) async {
    try {
      // Fetch 1Y of daily data for MA warmup (always daily regardless of chart range)
      final data = await _service.fetchChartData(
        symbol, TimeRange.twoYears,
        forceInterval: '1d',
      );
      stock1MaData = data;
      notifyListeners();
    } catch (_) {
      stock1MaData = [];
    }
  }

  Future<void> _fetchAnalystTarget(String symbol) async {
    final target = await _service.fetchAnalystTarget(symbol);
    if (target != null) {
      analystTargetPrice = target;
      notifyListeners();
    }
  }

  Future<void> loadStock2(String symbol) async {
    loadingStock2 = true;
    errorStock2 = null;
    notifyListeners();
    try {
      stock2Info = await _service.fetchStockInfo(symbol);
      stock2Data = await _service.fetchChartData(
        symbol, selectedRange,
        customStart: customStart, customEnd: customEnd,
      );
      _calcPeriodPerformance();
      _savePrefs();
    } catch (e) {
      errorStock2 = e.toString();
      stock2Data = [];
      stock2Info = null;
    }
    loadingStock2 = false;
    _clampCandlestick();
    notifyListeners();
  }

  void removeStock2() {
    stock2Info = null;
    stock2Data = [];
    errorStock2 = null;
    stock2PeriodChangePercent = null;
    stock2PeriodChangeAbsolute = null;
    notifyListeners();
    _savePrefs();
  }

  Future<void> changeRange(TimeRange range, {DateTime? start, DateTime? end}) async {
    selectedRange = range;
    if (range == TimeRange.custom) {
      customStart = start;
      customEnd = end;
    } else {
      customStart = null;
      customEnd = null;
    }
    notifyListeners();
    final futures = <Future>[];
    if (stock1Info != null) futures.add(loadStock1(stock1Info!.symbol));
    if (stock2Info != null) futures.add(loadStock2(stock2Info!.symbol));
    await Future.wait(futures);
  }

  void clearStock1() {
    if (stock2Info != null) {
      stock1Info = stock2Info;
      stock1Data = stock2Data;
      stock1PeriodChangePercent = stock2PeriodChangePercent;
      stock1PeriodChangeAbsolute = stock2PeriodChangeAbsolute;
      stock2Info = null;
      stock2Data = [];
      errorStock2 = null;
      stock2PeriodChangePercent = null;
      stock2PeriodChangeAbsolute = null;
    } else {
      stock1Info = null;
      stock1Data = [];
      stock1PeriodChangePercent = null;
      stock1PeriodChangeAbsolute = null;
    }
    errorStock1 = null;
    analystTargetPrice = null;
    stock1MaData = [];
    _showMa20 = false;
    _showMa50 = false;
    _showMa200 = false;
    _showTrendLine = false;
    _showTargetLine = false;
    notifyListeners();
    _savePrefs();
  }

  bool get hasStock1 => stock1Info != null;
  bool get hasStock2 => stock2Info != null;

  // Combined data length for MA availability check
  int get maDataLength {
    if (stock1Data.isEmpty) return 0;
    if (stock1MaData.isEmpty) return stock1Data.length;
    final chartStart = stock1Data.first.time;
    final warmupCount = stock1MaData.where((p) => p.time.isBefore(chartStart)).length;
    return warmupCount + stock1Data.length;
  }

  String customRangeLabel(String locale) {
    if (customStart == null || customEnd == null) return '';
    String fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.'
        '${(d.year % 100).toString().padLeft(2, '0')}';
    if (locale.startsWith('de')) {
      return '${fmtDate(customStart!)}–${fmtDate(customEnd!)}';
    }
    return '${customStart!.month}/${customStart!.day}–${customEnd!.month}/${customEnd!.day}';
  }
}
