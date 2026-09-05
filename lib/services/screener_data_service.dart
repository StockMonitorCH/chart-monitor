import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ScreenerEntry {
  final String symbol;
  final String name;
  final double price;
  final double perf1y;
  final double? pe;

  const ScreenerEntry({
    required this.symbol,
    required this.name,
    required this.price,
    required this.perf1y,
    this.pe,
  });

  factory ScreenerEntry.fromJson(Map<String, dynamic> j) => ScreenerEntry(
        symbol: j['s'] as String,
        name:   (j['n'] as String?) ?? (j['s'] as String),
        price:  (j['p'] as num?)?.toDouble() ?? 0.0,
        perf1y: (j['r'] as num).toDouble(),
        pe:     (j['pe'] as num?)?.toDouble(),
      );
}

class ScreenerData {
  final String generatedAt;
  final Map<String, List<ScreenerEntry>> indices;

  const ScreenerData({required this.generatedAt, required this.indices});
}

class ScreenerDataService {
  static const _url         = 'https://stock-monitor.ch/data/screener-data.json';
  static const _prefKey     = 'screener_data_v1';
  static const _prefTimeKey = 'screener_data_time_v1';
  static const _maxAge      = Duration(hours: 25);

  // Map from chip index (0-7) to JSON key
  static const _keyMap = {
    0: 'sp500',
    1: 'nasdaq100',
    2: 'nasdaq_extra',
    3: 'russell1000',
    4: 'nyse200',
    5: 'dax40',
    6: 'smi20',
    7: 'ftse100',
  };

  ScreenerData? _memCache;
  DateTime?     _memCacheTime;

  Future<ScreenerData> load() async {
    // 1. Memory cache (valid within app session)
    if (_memCache != null &&
        _memCacheTime != null &&
        DateTime.now().difference(_memCacheTime!) < _maxAge) {
      return _memCache!;
    }

    // 2. Disk cache (SharedPreferences)
    final prefs      = await SharedPreferences.getInstance();
    final cachedTime = prefs.getString(_prefTimeKey);
    if (cachedTime != null) {
      final t = DateTime.tryParse(cachedTime);
      if (t != null && DateTime.now().difference(t) < _maxAge) {
        final raw = prefs.getString(_prefKey);
        if (raw != null) {
          final data = _parse(raw);
          _memCache     = data;
          _memCacheTime = t;
          return data;
        }
      }
    }

    // 3. Download from Cyon
    debugPrint('[Screener] Downloading screener-data.json from Cyon...');
    final resp = await http
        .get(Uri.parse(_url))
        .timeout(const Duration(seconds: 30));
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode} from $_url');
    }

    final body = resp.body;
    final data = _parse(body);

    await prefs.setString(_prefKey,     body);
    await prefs.setString(_prefTimeKey, DateTime.now().toIso8601String());

    _memCache     = data;
    _memCacheTime = DateTime.now();
    debugPrint('[Screener] Downloaded. Generated at: ${data.generatedAt}');
    return data;
  }

  List<ScreenerEntry> entriesForIndices(Set<int> ids, ScreenerData data) {
    final seen   = <String>{};
    final result = <ScreenerEntry>[];
    for (final id in [0, 1, 2, 3, 4, 5, 6, 7]) {
      if (!ids.contains(id)) continue;
      final key     = _keyMap[id]!;
      final entries = data.indices[key] ?? [];
      for (final e in entries) {
        if (seen.add(e.symbol)) result.add(e);
      }
    }
    return result;
  }

  ScreenerData _parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final d = j['data'] as Map<String, dynamic>;
    return ScreenerData(
      generatedAt: (j['generated_at'] as String?) ?? '',
      indices: {
        for (final key in d.keys)
          key: (d[key] as List<dynamic>)
              .map((e) => ScreenerEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
      },
    );
  }
}
