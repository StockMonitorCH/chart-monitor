import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;

const _kTaskName = 'stockAlarmCheck';
const _kUniqueTag = 'cmAlarmPeriodic';
const _kLastNotif = 'cm_last_notif_';
const _kCooldownSecs = 3600; // 1 h between repeated notifications per symbol

// ── Background entry point ────────────────────────────────────────────────────

@pragma('vm:entry-point')
void alarmCallbackDispatcher() {
  Workmanager().executeTask((taskName, _) async {
    if (taskName != _kTaskName) return true;

    // Only run during trading hours Mon–Fri 13:00–22:30 UTC
    final now = DateTime.now().toUtc();
    if (now.weekday >= 6) return true;
    if (now.hour < 13 || now.hour >= 22) return true;

    try {
      await _runCheck();
    } catch (e) {
      debugPrint('[AlarmBG] $e');
    }
    return true;
  });
}

Future<void> _runCheck() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList('cm_watchlist') ?? [];

  final entries = raw.map(_parseRaw).where((e) => e.hasAlarm).toList();
  if (entries.isEmpty) return;

  final notif = FlutterLocalNotificationsPlugin();
  const init = AndroidInitializationSettings('@mipmap/ic_launcher');
  await notif.initialize(const InitializationSettings(android: init));

  final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  for (final e in entries) {
    final price = await _fetchPrice(e.symbol);
    if (price == null) continue;

    final lastTs = prefs.getInt('$_kLastNotif${e.symbol}') ?? 0;
    if (nowSec - lastTs < _kCooldownSecs) continue;

    var fired = false;
    if (e.stopLoss != null && price <= e.stopLoss!) {
      await _notify(notif, '${e.symbol}_sl',
          'Stop-Loss: ${e.symbol}',
          'Kurs ${price.toStringAsFixed(2)} ≤ SL ${e.stopLoss!.toStringAsFixed(2)}');
      fired = true;
    }
    if (e.targetPrice != null && price >= e.targetPrice!) {
      await _notify(notif, '${e.symbol}_tp',
          'Zielkurs: ${e.symbol}',
          'Kurs ${price.toStringAsFixed(2)} ≥ Ziel ${e.targetPrice!.toStringAsFixed(2)}');
      fired = true;
    }
    if (fired) await prefs.setInt('$_kLastNotif${e.symbol}', nowSec);
  }
}

Future<double?> _fetchPrice(String symbol) async {
  try {
    final resp = await http.get(
      Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$symbol'
          '?range=1d&interval=1d'),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final meta = data['chart']?['result']?[0]?['meta'] as Map<String, dynamic>?;
    return (meta?['regularMarketPrice'] as num?)?.toDouble();
  } catch (_) {
    return null;
  }
}

Future<void> _notify(FlutterLocalNotificationsPlugin notif,
    String tag, String title, String body) async {
  await notif.show(
    tag.hashCode.abs() % 100000,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'stock_alarms',
        'Kursalarme',
        channelDescription: 'Stop-Loss und Zielkurs Benachrichtigungen',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}

// Parses "symbol|name|sector|stopLoss|targetPrice" — backward-compatible with "symbol|name"
({String symbol, String name, double? stopLoss, double? targetPrice, bool hasAlarm})
    _parseRaw(String s) {
  final p = s.split('|');
  final sl = p.length > 3 && p[3] != '-' ? double.tryParse(p[3]) : null;
  final tp = p.length > 4 && p[4] != '-' ? double.tryParse(p[4]) : null;
  return (
    symbol: p[0],
    name: p.length > 1 ? p[1] : p[0],
    stopLoss: sl,
    targetPrice: tp,
    hasAlarm: sl != null || tp != null,
  );
}

// ── AlarmService (main isolate) ───────────────────────────────────────────────

class AlarmService {
  static final _notif = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await Workmanager().initialize(alarmCallbackDispatcher);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notif.initialize(const InitializationSettings(android: androidInit));

    await _notif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'stock_alarms',
          'Kursalarme',
          description: 'Stop-Loss und Zielkurs Benachrichtigungen',
          importance: Importance.high,
        ));
  }

  static Future<bool> requestPermission() async {
    final r = await _notif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return r ?? false;
  }

  /// Schedules or cancels the periodic background check.
  static Future<void> updateSchedule(bool hasAlarms) async {
    if (hasAlarms) {
      await Workmanager().registerPeriodicTask(
        _kUniqueTag,
        _kTaskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } else {
      await Workmanager().cancelByUniqueName(_kUniqueTag);
    }
  }

  /// Checks alarms immediately (foreground) against already-fetched prices.
  static Future<void> checkNow(
    List<({String symbol, double? stopLoss, double? targetPrice})> entries,
    Map<String, double?> prices,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    for (final e in entries) {
      if (e.stopLoss == null && e.targetPrice == null) continue;
      final price = prices[e.symbol];
      if (price == null) continue;

      final lastTs = prefs.getInt('$_kLastNotif${e.symbol}') ?? 0;
      if (nowSec - lastTs < _kCooldownSecs) continue;

      var fired = false;
      if (e.stopLoss != null && price <= e.stopLoss!) {
        await _notify(_notif, '${e.symbol}_sl',
            'Stop-Loss: ${e.symbol}',
            'Kurs ${price.toStringAsFixed(2)} ≤ SL ${e.stopLoss!.toStringAsFixed(2)}');
        fired = true;
      }
      if (e.targetPrice != null && price >= e.targetPrice!) {
        await _notify(_notif, '${e.symbol}_tp',
            'Zielkurs: ${e.symbol}',
            'Kurs ${price.toStringAsFixed(2)} ≥ Ziel ${e.targetPrice!.toStringAsFixed(2)}');
        fired = true;
      }
      if (fired) await prefs.setInt('$_kLastNotif${e.symbol}', nowSec);
    }
  }
}
