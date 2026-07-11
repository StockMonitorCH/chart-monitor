import 'dart:math' as math;
import '../models/company_info.dart';
import '../models/stock_data.dart';
import 'yahoo_finance_service.dart';

class StockRatingResult {
  final double overall;
  final double performance;
  final double risk;
  final double fundamental;
  final double technical;
  final double tradability;
  final double analyst;

  const StockRatingResult({
    required this.overall,
    required this.performance,
    required this.risk,
    required this.fundamental,
    required this.technical,
    required this.tradability,
    required this.analyst,
  });

  static const neutral = StockRatingResult(
    overall: 3.0,
    performance: 3.0,
    risk: 3.0,
    fundamental: 3.0,
    technical: 3.0,
    tradability: 3.0,
    analyst: 3.0,
  );
}

class StockRatingService {
  final _yf = YahooFinanceService();

  static const _riskFree = 0.045; // approx. current risk-free rate

  Future<StockRatingResult> computeRating(
    String symbol,
    double currentPrice,
  ) async {
    // Parallel fetch of all required data
    final futures = await Future.wait([
      _yf
          .fetchChartData(symbol, TimeRange.oneYear, forceInterval: '1d')
          .catchError((_) => <ChartDataPoint>[]),
      _yf
          .fetchChartData('^GSPC', TimeRange.oneYear, forceInterval: '1d')
          .catchError((_) => <ChartDataPoint>[]),
      _yf.fetchAnalystRatings(symbol).catchError((_) => null),
      _yf.fetchAnalystTarget(symbol).catchError((_) => null),
      _yf.fetchRatingMetrics(symbol).catchError(
            (_) => (beta: null, dividendYield: null),
          ),
    ]);

    final prices = futures[0] as List<ChartDataPoint>;
    final spxPrices = futures[1] as List<ChartDataPoint>;
    final analystData = futures[2] as AnalystData?;
    final targetPrice = futures[3] as double?;
    final metrics = futures[4] as ({double? beta, double? dividendYield});

    if (prices.length < 10) return StockRatingResult.neutral;

    final closes = prices.map((p) => p.close).toList();

    // Annualized return
    final totalReturn = closes.first != 0
        ? (closes.last - closes.first) / closes.first
        : 0.0;

    // Daily log returns for volatility / Sharpe
    final dailyReturns = <double>[];
    for (var i = 1; i < closes.length; i++) {
      if (closes[i - 1] > 0 && closes[i] > 0) {
        dailyReturns.add(math.log(closes[i] / closes[i - 1]));
      }
    }

    final annVol = _annualizedVol(dailyReturns);
    final annReturn = dailyReturns.isEmpty
        ? totalReturn
        : dailyReturns.reduce((a, b) => a + b) / dailyReturns.length * 252;

    final sharpe = annVol > 0 ? (annReturn - _riskFree) / annVol : 0.0;

    // Alpha vs S&P 500
    double? alpha;
    final beta = metrics.beta;
    if (spxPrices.length >= 2 && beta != null && beta != 0) {
      final mktReturn = spxPrices.first.close != 0
          ? (spxPrices.last.close - spxPrices.first.close) /
              spxPrices.first.close
          : 0.0;
      alpha = annReturn - (_riskFree + beta * (mktReturn - _riskFree));
    }

    // Technical indicators (all from 1Y daily data)
    final lastPrice = closes.last;
    final ma20 = _maLast(closes, 20);
    final ma38 = _maLast(closes, 38);
    final ma50 = _maLast(closes, 50);
    final ma200 = _maLast(closes, 200);
    final rsi = _rsi(closes, 14);
    final bollPos = _bollingerPosition(closes, 20);
    final trendR2 = _signedTrendR2(closes);

    // Target upside
    final targetUpside = targetPrice != null && currentPrice > 0
        ? (targetPrice - currentPrice) / currentPrice
        : null;

    // Score each category
    final perf =
        _scorePerformance(totalReturn, lastPrice, ma50, ma200);
    final risk = _scoreRisk(annVol, beta);
    final fund =
        _scoreFundamental(targetUpside, metrics.dividendYield);
    final tech =
        _scoreTechnical(lastPrice, ma20, ma38, ma50, ma200, rsi, bollPos, trendR2);
    final trade = _scoreTradability(sharpe, alpha, trendR2);
    final ana = _scoreAnalyst(analystData, targetUpside);

    final overall = _clamp(
      perf * 0.20 +
          risk * 0.15 +
          fund * 0.15 +
          tech * 0.25 +
          trade * 0.10 +
          ana * 0.15,
    );

    return StockRatingResult(
      overall: _half(overall),
      performance: _half(perf),
      risk: _half(risk),
      fundamental: _half(fund),
      technical: _half(tech),
      tradability: _half(trade),
      analyst: _half(ana),
    );
  }

  // ── Moving averages ──────────────────────────────────────────────────────────

  double? _maLast(List<double> closes, int period) {
    if (closes.length < period) return null;
    var sum = 0.0;
    for (var i = closes.length - period; i < closes.length; i++) {
      sum += closes[i];
    }
    return sum / period;
  }

  // ── Volatility ───────────────────────────────────────────────────────────────

  double _annualizedVol(List<double> logReturns) {
    if (logReturns.length < 2) return 0.30;
    final mean = logReturns.reduce((a, b) => a + b) / logReturns.length;
    final variance = logReturns
            .map((r) => (r - mean) * (r - mean))
            .reduce((a, b) => a + b) /
        logReturns.length;
    return math.sqrt(variance) * math.sqrt(252);
  }

  // ── RSI (Wilder smoothing) ───────────────────────────────────────────────────

  double _rsi(List<double> closes, int period) {
    if (closes.length <= period) return 50.0;
    final changes =
        List.generate(closes.length - 1, (i) => closes[i + 1] - closes[i]);

    double avgGain = 0, avgLoss = 0;
    for (var i = 0; i < period; i++) {
      final c = changes[i];
      if (c > 0) avgGain += c;
      else avgLoss += -c;
    }
    avgGain /= period;
    avgLoss /= period;

    for (var i = period; i < changes.length; i++) {
      final c = changes[i];
      avgGain = (avgGain * (period - 1) + (c > 0 ? c : 0.0)) / period;
      avgLoss = (avgLoss * (period - 1) + (c < 0 ? -c : 0.0)) / period;
    }

    if (avgLoss == 0) return 100.0;
    return 100 - 100 / (1 + avgGain / avgLoss);
  }

  // ── Bollinger position (0 = lower band, 1 = upper band) ─────────────────────

  double? _bollingerPosition(List<double> closes, int period) {
    if (closes.length < period) return null;
    final slice = closes.sublist(closes.length - period);
    final sma = slice.reduce((a, b) => a + b) / period;
    final variance =
        slice.map((v) => (v - sma) * (v - sma)).reduce((a, b) => a + b) /
            period;
    final std = math.sqrt(variance);
    if (std == 0) return 0.5;
    final upper = sma + 2 * std;
    final lower = sma - 2 * std;
    return ((closes.last - lower) / (upper - lower)).clamp(0.0, 1.0);
  }

  // ── Linear trend R² (positive = uptrend, negative = downtrend) ──────────────

  double _signedTrendR2(List<double> closes) {
    if (closes.length < 5) return 0;
    final n = closes.length;
    final meanX = (n - 1) / 2.0;
    final meanY = closes.reduce((a, b) => a + b) / n;
    double sXY = 0, sXX = 0, ssTot = 0;
    for (var i = 0; i < n; i++) {
      sXY += (i - meanX) * (closes[i] - meanY);
      sXX += (i - meanX) * (i - meanX);
      ssTot += (closes[i] - meanY) * (closes[i] - meanY);
    }
    if (sXX == 0 || ssTot == 0) return 0;
    final slope = sXY / sXX;
    final intercept = meanY - slope * meanX;
    double ssRes = 0;
    for (var i = 0; i < n; i++) {
      final pred = intercept + slope * i;
      ssRes += (closes[i] - pred) * (closes[i] - pred);
    }
    final r2 = 1 - ssRes / ssTot;
    return r2.clamp(0.0, 1.0) * (slope >= 0 ? 1 : -1);
  }

  // ── Scoring ──────────────────────────────────────────────────────────────────

  double _scorePerformance(
      double totalReturn, double price, double? ma50, double? ma200) {
    final pct = totalReturn * 100;
    double s;
    if (pct >= 50)       s = 5.0;
    else if (pct >= 30)  s = 4.0 + (pct - 30) / 20;
    else if (pct >= 15)  s = 3.0 + (pct - 15) / 15;
    else if (pct >= 0)   s = 2.5 + pct / 15 * 0.5;
    else if (pct >= -15) s = 1.5 + (pct + 15) / 15;
    else if (pct >= -30) s = 0.5 + (pct + 30) / 15;
    else                 s = 0.5;

    if (ma50 != null && price > ma50) s += 0.25;
    if (ma200 != null && price > ma200) s += 0.25;
    return _clamp(s);
  }

  double _scoreRisk(double annVol, double? beta) {
    final vPct = annVol * 100;
    double s;
    if (vPct < 12)       s = 5.0;
    else if (vPct < 20)  s = 4.0 + (20 - vPct) / 8;
    else if (vPct < 30)  s = 3.0 + (30 - vPct) / 10;
    else if (vPct < 45)  s = 2.0 + (45 - vPct) / 15;
    else if (vPct < 60)  s = 1.0 + (60 - vPct) / 15;
    else                 s = 0.5;

    if (beta != null) {
      if (beta < 0.5)       s += 0.5;
      else if (beta < 0.8)  s += 0.25;
      else if (beta < 1.2)  s += 0.0;
      else if (beta < 1.5)  s -= 0.25;
      else                  s -= 0.5;
    }
    return _clamp(s);
  }

  double _scoreFundamental(double? targetUpside, double? dividendYield) {
    double s;
    if (targetUpside != null) {
      final pct = targetUpside * 100;
      if (pct >= 30)       s = 5.0;
      else if (pct >= 20)  s = 4.0 + (pct - 20) / 10;
      else if (pct >= 10)  s = 3.5 + (pct - 10) / 20;
      else if (pct >= 0)   s = 3.0 + pct / 20 * 0.5;
      else if (pct >= -10) s = 2.0 + (pct + 10) / 10;
      else if (pct >= -20) s = 1.0 + (pct + 20) / 10;
      else                 s = 0.5;
    } else {
      s = 3.0; // neutral if no target available
    }

    // Dividend yield bonus
    if (dividendYield != null && dividendYield > 0) {
      if (dividendYield >= 0.04)      s += 0.5;
      else if (dividendYield >= 0.02) s += 0.25;
      else                             s += 0.1;
    }
    return _clamp(s);
  }

  double _scoreTechnical(
    double price,
    double? ma20,
    double? ma38,
    double? ma50,
    double? ma200,
    double rsi,
    double? bollPos,
    double trendR2,
  ) {
    double bull = 0, bear = 0;

    void sig(bool isBull, double w) {
      if (isBull) bull += w;
      else bear += w;
    }

    if (ma20 != null)  sig(price > ma20, 1.0);
    if (ma38 != null)  sig(price > ma38, 0.8);
    if (ma50 != null)  sig(price > ma50, 1.0);
    if (ma200 != null) sig(price > ma200, 1.5);

    // RSI signal
    if (rsi < 30)       bull += 1.5;
    else if (rsi < 40)  bull += 0.75;
    else if (rsi > 70)  bear += 1.5;
    else if (rsi > 60)  bear += 0.75;
    // 40–60: neutral → no contribution

    // Bollinger position
    if (bollPos != null) {
      if (bollPos < 0.2)      bull += 1.0;
      else if (bollPos > 0.8) bear += 1.0;
    }

    // Trend
    if (trendR2.abs() > 0.2) sig(trendR2 > 0, 0.5);

    final total = bull + bear;
    if (total == 0) return 3.0;
    return _clamp(3.0 + (bull - bear) / total * 2.0);
  }

  double _scoreTradability(double sharpe, double? alpha, double trendR2) {
    double s;
    if (sharpe >= 2.0)       s = 5.0;
    else if (sharpe >= 1.5)  s = 4.5;
    else if (sharpe >= 1.0)  s = 4.0;
    else if (sharpe >= 0.5)  s = 3.5;
    else if (sharpe >= 0.0)  s = 2.5;
    else if (sharpe >= -0.5) s = 1.5;
    else                     s = 0.5;

    if (trendR2 > 0.6)       s += 0.5;
    else if (trendR2 > 0.3)  s += 0.25;
    else if (trendR2 < -0.6) s -= 0.5;
    else if (trendR2 < -0.3) s -= 0.25;

    if (alpha != null) {
      if (alpha > 0.1)       s += 0.25;
      else if (alpha < -0.1) s -= 0.25;
    }
    return _clamp(s);
  }

  double _scoreAnalyst(AnalystData? data, double? targetUpside) {
    if (data == null) return 3.0;
    double s;
    switch (data.recommendationKey.toLowerCase()) {
      case 'strongbuy':  s = 5.0;
      case 'buy':        s = 4.0;
      case 'hold':       s = 3.0;
      case 'sell':       s = 2.0;
      case 'strongsell': s = 1.0;
      default:           s = 3.0;
    }
    if (targetUpside != null) {
      if (targetUpside > 0.2)  s += 0.25;
      else if (targetUpside < -0.1) s -= 0.25;
    }
    // Fewer analysts → regress to mean
    if (data.numberOfAnalysts < 3) s = (s + 3.0) / 2;
    return _clamp(s);
  }

  double _clamp(double v) => v.clamp(0.5, 5.0);
  double _half(double v) => (v * 2).round() / 2.0;
}
