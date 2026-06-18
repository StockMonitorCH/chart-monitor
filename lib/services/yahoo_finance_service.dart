import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/company_info.dart';
import '../models/news_item.dart';
import '../models/stock_data.dart';

class YahooFinanceService {
  static const _ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static const _baseHeaders = {
    'User-Agent': _ua,
    'Accept': 'application/json',
    'Accept-Language': 'en-US,en;q=0.9',
    'Origin': 'https://finance.yahoo.com',
    'Referer': 'https://finance.yahoo.com/',
  };

  // Session cache: cookie + crumb for authenticated endpoints
  String? _sessionCookie;
  String? _crumb;

  Map<String, String> get _headers => {
        ..._baseHeaders,
        // ignore: use_null_aware_elements
        if (_sessionCookie != null) 'Cookie': _sessionCookie!,
      };

  /// Gets A3 cookie from Yahoo and a crumb from the getcrumb endpoint.
  /// Uses dart:io HttpClient directly so cookies with HttpOnly/Secure flags
  /// are properly parsed from all Set-Cookie headers.
  Future<void> _ensureSession() async {
    if (_crumb != null && _sessionCookie != null) return;

    final ioClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);

    try {
      // Try multiple cookie sources; fc.yahoo.com returns 404 but always sets A3
      for (final source in [
        'https://fc.yahoo.com',
        'https://finance.yahoo.com',
      ]) {
        if (_sessionCookie != null) break;
        try {
          final req = await ioClient.getUrl(Uri.parse(source));
          req.headers.set(HttpHeaders.userAgentHeader, _ua);
          req.headers.set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9');

          final resp =
              await req.close().timeout(const Duration(seconds: 15));
          await resp.drain<void>();

          for (final cookie in resp.cookies) {
            if (cookie.name == 'A3') {
              _sessionCookie = 'A3=${cookie.value}';
              debugPrint('[YF] A3 cookie from $source');
              break;
            }
          }
        } catch (e) {
          debugPrint('[YF] Cookie source $source failed: $e');
        }
      }

      if (_sessionCookie == null) {
        debugPrint('[YF] No A3 cookie obtained – quoteSummary will fail');
        return;
      }

      // Get crumb using the A3 cookie
      final crumbReq = await ioClient.getUrl(
        Uri.parse('https://query1.finance.yahoo.com/v1/test/getcrumb'),
      );
      crumbReq.headers.set(HttpHeaders.userAgentHeader, _ua);
      crumbReq.headers.set(HttpHeaders.acceptLanguageHeader, 'en-US,en;q=0.9');
      crumbReq.headers.set(HttpHeaders.cookieHeader, _sessionCookie!);

      final crumbResp =
          await crumbReq.close().timeout(const Duration(seconds: 10));
      final body =
          await crumbResp.transform(const Utf8Decoder(allowMalformed: true)).join();

      debugPrint('[YF] crumb status=${crumbResp.statusCode} body=$body');

      if (crumbResp.statusCode == 200 && !body.contains('Unauthorized')) {
        _crumb = body.trim();
        debugPrint('[YF] Session ready');
      }
    } catch (e) {
      debugPrint('[YF] Session init error: $e');
    } finally {
      ioClient.close();
    }
  }

  void _invalidateSession() {
    _crumb = null;
    _sessionCookie = null;
  }

  // Rohstoff-Kürzel → Yahoo Finance Futures-Symbol (=X Spot-Symbole funktionieren nicht)
  static const _commodityMap = {
    'XAU':      ('GC=F', 'Gold Futures',            'FUTURE'),
    'GOLD':     ('GC=F', 'Gold Futures',            'FUTURE'),
    'XAG':      ('SI=F', 'Silber Futures',          'FUTURE'),
    'SILVER':   ('SI=F', 'Silber Futures',          'FUTURE'),
    'XPT':      ('PL=F', 'Platin Futures',          'FUTURE'),
    'PLATINUM': ('PL=F', 'Platin Futures',          'FUTURE'),
    'XPD':      ('PA=F', 'Palladium Futures',       'FUTURE'),
    'XCU':      ('HG=F', 'Kupfer Futures',          'FUTURE'),
    'COPPER':   ('HG=F', 'Kupfer Futures',          'FUTURE'),
    'OIL':      ('CL=F', 'Rohöl WTI Futures',      'FUTURE'),
    'WTI':      ('CL=F', 'Rohöl WTI Futures',      'FUTURE'),
    'BRENT':    ('BZ=F', 'Rohöl Brent Futures',    'FUTURE'),
    'NATGAS':   ('NG=F', 'Erdgas Futures',          'FUTURE'),
  };

  Future<List<StockSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final encoded = Uri.encodeComponent(query.trim());
    final uri = Uri.parse(
      'https://query1.finance.yahoo.com/v1/finance/search'
      '?q=$encoded&quotesCount=10&newsCount=0&listsCount=0',
    );
    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 10));

    var results = <StockSearchResult>[];
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final quotes = data['quotes'] as List<dynamic>? ?? [];
      results = quotes
          .map((q) => StockSearchResult.fromJson(q as Map<String, dynamic>))
          .where((r) => r.symbol.isNotEmpty && r.quoteType != 'OPTION')
          .toList();
    }

    // Rohstoff-Fallback: bekannte Kürzel direkt eintragen
    final key = query.trim().toUpperCase();
    final commodity = _commodityMap[key];
    if (commodity != null) {
      final (sym, name, type) = commodity;
      if (!results.any((r) => r.symbol == sym)) {
        results.insert(0, StockSearchResult(
          symbol: sym,
          shortName: name,
          exchange: 'Yahoo Finance',
          quoteType: type,
        ));
      }
    }

    return results;
  }

  Future<List<ChartDataPoint>> fetchChartData(
    String symbol,
    TimeRange range, {
    DateTime? customStart,
    DateTime? customEnd,
    String? forceInterval,
    bool includePrePost = false,
  }) async {
    final Map<String, String> params;
    if (range == TimeRange.custom && customStart != null && customEnd != null) {
      final p1 = customStart.millisecondsSinceEpoch ~/ 1000;
      final p2 = customEnd.millisecondsSinceEpoch ~/ 1000;
      final days = customEnd.difference(customStart).inDays;
      params = {
        'period1': '$p1',
        'period2': '$p2',
        'interval': forceInterval ?? range.intervalFor(days),
        'includePrePost': 'false',
      };
    } else {
      params = {
        'range': range.range,
        'interval': forceInterval ?? range.interval,
        'includePrePost': includePrePost ? 'true' : 'false',
      };
    }
    final response = await _chartGet(symbol, params);
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

    final data = jsonDecode(response.body);
    final result = data['chart']['result'] as List<dynamic>?;
    if (result == null || result.isEmpty) throw Exception('No data');

    final timestamps = (result[0]['timestamp'] as List<dynamic>?)
        ?.map((t) => DateTime.fromMillisecondsSinceEpoch((t as int) * 1000))
        .toList();

    List<double> parseList(String key) =>
        (result[0]['indicators']['quote'][0][key] as List<dynamic>?)
            ?.map((v) => v == null ? double.nan : (v as num).toDouble())
            .toList() ?? [];

    final closes = parseList('close');
    final opens  = parseList('open');
    final highs  = parseList('high');
    final lows   = parseList('low');

    if (timestamps == null || closes.isEmpty ||
        timestamps.length != closes.length) {
      throw Exception('Malformed data');
    }

    // Determine regular-session boundaries from tradingPeriods for extended hours marking
    DateTime? regularStart, regularEnd;
    if (includePrePost) {
      final tp = (result[0]['meta'] as Map<String, dynamic>?)?['tradingPeriods']
          ?? result[0]['tradingPeriods'];
      if (tp is Map) {
        final reg = (tp['regular'] as List?)?.firstOrNull;
        final regPeriod = (reg is List) ? reg.firstOrNull : reg;
        if (regPeriod is Map) {
          final s = regPeriod['start'];
          final e = regPeriod['end'];
          if (s is int && e is int) {
            regularStart = DateTime.fromMillisecondsSinceEpoch(s * 1000);
            regularEnd   = DateTime.fromMillisecondsSinceEpoch(e * 1000);
          }
        }
      }
    }

    final points = <ChartDataPoint>[];
    for (var i = 0; i < timestamps.length; i++) {
      if (!closes[i].isNaN) {
        final isExt = includePrePost &&
            regularStart != null &&
            regularEnd != null &&
            (timestamps[i].isBefore(regularStart) ||
                timestamps[i].isAfter(regularEnd));
        points.add(ChartDataPoint(
          time: timestamps[i],
          close: closes[i],
          open:  (i < opens.length  && !opens[i].isNaN)  ? opens[i]  : null,
          high:  (i < highs.length  && !highs[i].isNaN)  ? highs[i]  : null,
          low:   (i < lows.length   && !lows[i].isNaN)   ? lows[i]   : null,
          isExtendedHours: isExt,
        ));
      }
    }
    return points;
  }

  Future<http.Response> _chartGet(String symbol, Map<String, String> params) async {
    String buildQuery(String? crumb) {
      final q = Map<String, String>.of(params);
      if (crumb != null) q['crumb'] = crumb;
      return q.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    }
    // Symbol literal im Pfad – kein encodeComponent, da = in Pfaden gültig ist
    final base = 'https://query1.finance.yahoo.com/v8/finance/chart/$symbol';

    var resp = await http.get(
      Uri.parse('$base?${buildQuery(null)}'),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));

    if (resp.statusCode == 401 || resp.statusCode == 403) {
      await _ensureSession();
      resp = await http.get(
        Uri.parse('$base?${buildQuery(_crumb)}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
    }
    return resp;
  }

  Future<StockInfo> fetchStockInfo(String symbol) async {
    final response = await _chartGet(symbol, {'range': '1d', 'interval': '1d'});
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

    final data = jsonDecode(response.body);
    final result = data['chart']['result'] as List<dynamic>?;
    if (result == null || result.isEmpty) throw Exception('No data');

    final meta = result[0]['meta'] as Map<String, dynamic>;
    final currentPrice = (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0.0;
    final prevClose =
        (meta['chartPreviousClose'] as num?)?.toDouble() ?? currentPrice;
    final changePercent =
        prevClose != 0 ? ((currentPrice - prevClose) / prevClose) * 100 : 0.0;

    final preMarketPrice = (meta['preMarketPrice'] as num?)?.toDouble();
    final postMarketPrice = (meta['postMarketPrice'] as num?)?.toDouble();

    final preMarketChangePct = (preMarketPrice != null && prevClose != 0)
        ? (preMarketPrice - prevClose) / prevClose * 100
        : null;
    final postMarketChangePct = (postMarketPrice != null && currentPrice != 0)
        ? (postMarketPrice - currentPrice) / currentPrice * 100
        : null;

    return StockInfo(
      symbol: symbol,
      name: meta['instrumentType'] == 'EQUITY'
          ? (meta['longName'] ?? meta['shortName'] ?? symbol)
          : (meta['shortName'] ?? symbol),
      currentPrice: currentPrice,
      changePercent: changePercent,
      currency: meta['currency'] ?? '',
      preMarketPrice: preMarketPrice,
      preMarketChangePct: preMarketChangePct,
      postMarketPrice: postMarketPrice,
      postMarketChangePct: postMarketChangePct,
    );
  }

  Future<String?> fetchSector(String symbol) async {
    String? extract(dynamic body) {
      final result = (body as Map<String, dynamic>?)?['quoteSummary']
          ?['result'] as List?;
      if (result == null || result.isEmpty) return null;
      return result[0]['assetProfile']?['sector'] as String?;
    }

    const mod = '?modules=assetProfile';
    const base1 = 'https://query1.finance.yahoo.com/v10/finance/quoteSummary/';
    const base2 = 'https://query2.finance.yahoo.com/v10/finance/quoteSummary/';

    Future<String?> tryGet(String url, Map<String, String> headers) async {
      try {
        final resp = await http.get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) return extract(jsonDecode(resp.body));
      } catch (_) {}
      return null;
    }

    var result = await tryGet('$base1$symbol$mod', _baseHeaders);
    result ??= await tryGet('$base2$symbol$mod', _baseHeaders);
    if (result != null) return result;

    await _ensureSession();
    final crumb = _crumb != null ? '&crumb=${Uri.encodeComponent(_crumb!)}' : '';
    return await tryGet('$base1$symbol$mod$crumb', _headers);
  }

  Future<double?> fetchPeriodPerformance(String symbol, TimeRange range) async {
    try {
      final data = await fetchChartData(symbol, range);
      if (data.length < 2) return null;
      final first = data.first.close;
      if (first == 0) return null;
      return (data.last.close - first) / first * 100;
    } catch (_) {
      return null;
    }
  }

  Future<double?> fetchAnalystTarget(String symbol) async {
    double? parseTarget(dynamic body) {
      final result = body['quoteSummary']?['result'] as List?;
      if (result == null || result.isEmpty) return null;
      final fd = result[0]['financialData'] as Map<String, dynamic>?;
      if (fd == null) return null;
      final target = fd['targetMeanPrice'];
      if (target is Map) return (target['raw'] as num?)?.toDouble();
      if (target is num) return target.toDouble();
      return null;
    }

    Future<double?> tryUrl(String url, Map<String, String> headers) async {
      final resp = await http.get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      return parseTarget(jsonDecode(resp.body));
    }

    try {
      const base1 = 'https://query1.finance.yahoo.com/v10/finance/quoteSummary/';
      const base2 = 'https://query2.finance.yahoo.com/v10/finance/quoteSummary/';
      const mod = '?modules=financialData';

      var result = await tryUrl('$base1$symbol$mod', _baseHeaders);
      result ??= await tryUrl('$base2$symbol$mod', _baseHeaders);
      if (result != null) return result;

      // Fallback: with cookie + crumb
      await _ensureSession();
      final crumb = _crumb != null ? '&crumb=${Uri.encodeComponent(_crumb!)}' : '';
      result = await tryUrl('$base1$symbol$mod$crumb', _headers);
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<AnalystData?> fetchAnalystRatings(String symbol) async {
    AnalystData? parse(dynamic body) {
      final result = body['quoteSummary']?['result'] as List?;
      if (result == null || result.isEmpty) return null;
      final modules = result[0] as Map<String, dynamic>;

      final fd = modules['financialData'] as Map<String, dynamic>?;
      final key = (fd?['recommendationKey'] as String? ?? '').toLowerCase();
      int numAnalysts = 0;
      final nOp = fd?['numberOfAnalystOpinions'];
      if (nOp is Map) numAnalysts = (nOp['raw'] as num?)?.toInt() ?? 0;
      if (nOp is num) numAnalysts = nOp.toInt();

      final rt = modules['recommendationTrend'] as Map<String, dynamic>?;
      final trends = rt?['trend'] as List?;
      Map<String, dynamic>? current;
      if (trends != null) {
        for (final t in trends) {
          if ((t as Map<String, dynamic>)['period'] == '0m') {
            current = t;
            break;
          }
        }
        current ??= trends.isNotEmpty ? trends[0] as Map<String, dynamic> : null;
      }

      int n(String k) => (current?[k] as num?)?.toInt() ?? 0;
      return AnalystData(
        recommendationKey: key.isEmpty ? 'none' : key,
        numberOfAnalysts: numAnalysts,
        strongBuy:  n('strongBuy'),
        buy:        n('buy'),
        hold:       n('hold'),
        sell:       n('sell'),
        strongSell: n('strongSell'),
      );
    }

    Future<AnalystData?> tryUrl(String url, Map<String, String> headers) async {
      try {
        final resp = await http.get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 10));
        if (resp.statusCode != 200) return null;
        return parse(jsonDecode(resp.body));
      } catch (_) { return null; }
    }

    try {
      const base1 = 'https://query1.finance.yahoo.com/v10/finance/quoteSummary/';
      const base2 = 'https://query2.finance.yahoo.com/v10/finance/quoteSummary/';
      const mod = '?modules=recommendationTrend,financialData';

      var result = await tryUrl('$base1$symbol$mod', _baseHeaders);
      result ??= await tryUrl('$base2$symbol$mod', _baseHeaders);
      if (result != null) return result;

      await _ensureSession();
      final crumb = _crumb != null ? '&crumb=${Uri.encodeComponent(_crumb!)}' : '';
      return await tryUrl('$base1$symbol$mod$crumb', _headers);
    } catch (_) {
      return null;
    }
  }

  static const _modules =
      'assetProfile,summaryDetail,defaultKeyStatistics,calendarEvents,topHoldings,price';

  Future<CompanyInfo> fetchCompanyInfo(String symbol) async {
    final divFuture = _fetchDividendHistory(symbol);

    Map<String, dynamic> profile = {};
    Map<String, dynamic> detail = {};
    Map<String, dynamic> keyStats = {};
    Map<String, dynamic> priceData = {};
    final topHoldings = <EtfHolding>[];
    final sectorWeightings = <EtfSectorWeight>[];
    String? exDivDate;
    String? nextEarnings;
    String? currency;
    final log = StringBuffer();

    bool parsed = false;

    void tryParse(Map<String, dynamic> body) {
      _parseSummary(body,
          profile: profile, detail: detail, keyStats: keyStats,
          priceData: priceData, topHoldings: topHoldings,
          sectorWeightings: sectorWeightings,
          exDivDate: (d) => exDivDate = d,
          nextEarnings: (d) => nextEarnings = d,
          currency: (c) => currency = c);
      parsed = profile.isNotEmpty || topHoldings.isNotEmpty || priceData.isNotEmpty;
    }

    // ── Strategy 1: no auth ──────────────────────────────────────────────────
    try {
      final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v10/finance/quoteSummary/$symbol'
        '?modules=$_modules',
      );
      final resp = await http.get(uri, headers: _baseHeaders)
          .timeout(const Duration(seconds: 15));
      log.write('q1-noauth:${resp.statusCode} ');
      if (resp.statusCode == 200) tryParse(jsonDecode(resp.body));
    } catch (e) { log.write('q1-noauth-ex:$e '); }

    // ── Strategy 2: query2 no auth ───────────────────────────────────────────
    if (!parsed) {
      try {
        final uri = Uri.parse(
          'https://query2.finance.yahoo.com/v10/finance/quoteSummary/$symbol'
          '?modules=$_modules',
        );
        final resp = await http.get(uri, headers: _baseHeaders)
            .timeout(const Duration(seconds: 15));
        log.write('q2-noauth:${resp.statusCode} ');
        if (resp.statusCode == 200) tryParse(jsonDecode(resp.body));
      } catch (e) { log.write('q2-noauth-ex:$e '); }
    }

    // ── Strategy 3: cookie + crumb ───────────────────────────────────────────
    if (!parsed) {
      await _ensureSession();
      log.write('cookie:${_sessionCookie != null ? "ok" : "null"} '
          'crumb:${_crumb ?? "null"} ');
      Future<void> tryAuth(String base) async {
        final crumb = _crumb != null ? '&crumb=${Uri.encodeComponent(_crumb!)}' : '';
        final uri = Uri.parse('$base?modules=$_modules$crumb');
        final resp = await http.get(uri, headers: _headers)
            .timeout(const Duration(seconds: 15));
        log.write('auth:${resp.statusCode} ');
        if (resp.statusCode == 200) {
          tryParse(jsonDecode(resp.body));
        } else if (resp.statusCode == 401) {
          _invalidateSession();
          await _ensureSession();
          final crumb2 = _crumb != null ? '&crumb=${Uri.encodeComponent(_crumb!)}' : '';
          final uri2 = Uri.parse('$base?modules=$_modules$crumb2');
          final resp2 = await http.get(uri2, headers: _headers)
              .timeout(const Duration(seconds: 15));
          log.write('retry:${resp2.statusCode} ');
          if (resp2.statusCode == 200) tryParse(jsonDecode(resp2.body));
        }
      }
      try {
        await tryAuth(
          'https://query1.finance.yahoo.com/v10/finance/quoteSummary/$symbol');
      } catch (e) { log.write('auth-ex:$e '); }
    }

    debugPrint('[YF] fetchCompanyInfo $symbol: $log');

    final dividendHistory = await divFuture;

    String? ceo;
    final officers = profile['companyOfficers'] as List<dynamic>?;
    if (officers != null) {
      for (final o in officers) {
        final title = (o['title'] as String? ?? '').toLowerCase();
        if (title.contains('ceo') || title.contains('chief executive')) {
          ceo = o['name'] as String?;
          break;
        }
      }
    }

    double? raw(Map<String, dynamic> m, String key) {
      final v = m[key];
      if (v is Map) return (v['raw'] as num?)?.toDouble();
      if (v is num) return v.toDouble();
      return null;
    }

    final quoteType = priceData['quoteType'] as String?;

    // Name: prefer assetProfile, fall back to price module (needed for ETFs)
    final name = (profile['longName'] as String?)
        ?? (priceData['longName'] as String?)
        ?? (priceData['shortName'] as String?)
        ?? symbol;

    // Market cap: prefer summaryDetail, fall back to price module
    final marketCap = raw(detail, 'marketCap') ?? raw(priceData, 'marketCap');

    // Website: ETFs sometimes have it in profile, sometimes not
    final website = profile['website'] as String?;

    return CompanyInfo(
      symbol: symbol,
      name: name,
      currency: currency ?? (detail['currency'] as String?) ?? (priceData['currency'] as String?) ?? '',
      sector: profile['sector'] as String?,
      industry: profile['industry'] as String?,
      country: profile['country'] as String?,
      website: website,
      ceo: ceo,
      employees: profile['fullTimeEmployees'] as int?,
      description: profile['longBusinessSummary'] as String?,
      marketCap: marketCap,
      peRatio: raw(detail, 'trailingPE'),
      eps: raw(keyStats, 'trailingEps'),
      dividendYield: raw(detail, 'dividendYield'),
      dividendRate: raw(detail, 'dividendRate'),
      exDividendDate: exDivDate,
      nextEarningsDate: nextEarnings,
      beta: raw(keyStats, 'beta') ?? raw(priceData, 'beta'),
      fiftyTwoWeekHigh: raw(detail, 'fiftyTwoWeekHigh'),
      fiftyTwoWeekLow: raw(detail, 'fiftyTwoWeekLow'),
      dividendHistory: dividendHistory,
      quoteType: quoteType,
      topHoldings: topHoldings,
      sectorWeightings: sectorWeightings,
      debugInfo: parsed ? null : log.toString(),
    );
  }

  void _parseSummary(
    Map<String, dynamic> data, {
    required Map<String, dynamic> profile,
    required Map<String, dynamic> detail,
    required Map<String, dynamic> keyStats,
    required Map<String, dynamic> priceData,
    required List<EtfHolding> topHoldings,
    required List<EtfSectorWeight> sectorWeightings,
    required void Function(String?) exDivDate,
    required void Function(String?) nextEarnings,
    required void Function(String?) currency,
  }) {
    final result = data['quoteSummary']?['result'] as List<dynamic>?;
    if (result == null || result.isEmpty) return;
    final modules = result[0] as Map<String, dynamic>;

    profile.addAll((modules['assetProfile'] as Map<String, dynamic>?) ?? {});
    detail.addAll((modules['summaryDetail'] as Map<String, dynamic>?) ?? {});
    keyStats.addAll((modules['defaultKeyStatistics'] as Map<String, dynamic>?) ?? {});
    priceData.addAll((modules['price'] as Map<String, dynamic>?) ?? {});

    final detailCurrency = detail['currency'] ?? priceData['currency'];
    if (detailCurrency is String) currency(detailCurrency);

    final exDivRaw = detail['exDividendDate'];
    if (exDivRaw is Map && exDivRaw['fmt'] != null) {
      exDivDate(exDivRaw['fmt'] as String);
    }

    final calEvents = modules['calendarEvents'] as Map<String, dynamic>?;
    final earnings = calEvents?['earnings'] as Map<String, dynamic>?;
    final earningsDates = earnings?['earningsDate'] as List<dynamic>?;
    if (earningsDates != null && earningsDates.isNotEmpty) {
      final fmt = (earningsDates[0] as Map<String, dynamic>)['fmt'];
      if (fmt != null) nextEarnings(fmt as String);
    }

    // ── ETF / Fund: topHoldings ──────────────────────────────────────────────
    if (topHoldings.isEmpty) {
      final th = modules['topHoldings'] as Map<String, dynamic>?;
      if (th != null) {
        // Helper: Yahoo Finance returns either a plain num or {"raw": num, "fmt": "..."}
        double? yNum(dynamic v) {
          if (v is num) return v.toDouble();
          if (v is Map) return (v['raw'] as num?)?.toDouble();
          return null;
        }

        final holdings = th['holdings'] as List<dynamic>? ?? [];
        for (final h in holdings) {
          final pct = yNum(h['holdingPercent']);
          if (pct != null) {
            topHoldings.add(EtfHolding(
              symbol: h['symbol'] as String? ?? '',
              name: h['holdingName'] as String? ?? '',
              percent: pct,
            ));
          }
        }

        final sectors = th['sectorWeightings'] as List<dynamic>? ?? [];
        for (final s in sectors) {
          if (s is Map<String, dynamic>) {
            for (final entry in s.entries) {
              final pct = yNum(entry.value);
              if (pct != null && pct > 0.001) {
                sectorWeightings.add(EtfSectorWeight(
                  sector: entry.key,
                  percent: pct,
                ));
              }
            }
          }
        }
        sectorWeightings.sort((a, b) => b.percent.compareTo(a.percent));
      }
    }
  }

  Future<List<DividendEntry>> _fetchDividendHistory(String symbol) async {
    try {
      final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/$symbol'
        '?range=10y&interval=3mo&events=div&includePrePost=false',
      );
      final resp = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return [];

      final data = jsonDecode(resp.body);
      final chartResult = data['chart']['result'] as List<dynamic>?;
      if (chartResult == null || chartResult.isEmpty) return [];

      final events =
          chartResult[0]['events'] as Map<String, dynamic>?;
      final divEvents =
          events?['dividends'] as Map<String, dynamic>?;
      if (divEvents == null) return [];

      final history = <DividendEntry>[];
      for (final entry in divEvents.entries) {
        final ts = (entry.value['date'] as int?) ?? 0;
        final amount =
            (entry.value['amount'] as num?)?.toDouble() ?? 0.0;
        if (ts > 0 && amount > 0) {
          history.add(DividendEntry(
            date: DateTime.fromMillisecondsSinceEpoch(ts * 1000),
            amount: amount,
          ));
        }
      }
      history.sort((a, b) => a.date.compareTo(b.date));
      return history;
    } catch (_) {
      return [];
    }
  }

  Future<List<NewsItem>> fetchNews(String symbol) async {
    try {
      final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v1/finance/search'
        '?q=${Uri.encodeComponent(symbol)}&newsCount=10&quotesCount=0'
        '&enableFuzzyQuery=false&enableEnhancedTrivialQuery=true',
      );
      final resp = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final raw = (json['news'] as List?) ?? [];
      final cutoff = DateTime.now().subtract(const Duration(hours: 48));
      return raw.map((item) {
        final ts = (item['providerPublishTime'] as num?)?.toInt() ?? 0;
        return NewsItem(
          title: item['title'] as String? ?? '',
          publisher: item['publisher'] as String? ?? '',
          link: item['link'] as String? ?? '',
          publishedAt: ts > 0
              ? DateTime.fromMillisecondsSinceEpoch(ts * 1000)
              : DateTime.now(),
        );
      }).where((n) => n.title.isNotEmpty && n.link.isNotEmpty && n.publishedAt.isAfter(cutoff)).toList();
    } catch (_) {
      return [];
    }
  }
}
