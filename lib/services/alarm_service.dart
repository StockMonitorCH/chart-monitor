import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;

const _kTaskName = 'stockAlarmCheck';
const _kUniqueTag = 'cmAlarmPeriodic';
const _kLastNotif = 'cm_last_notif_';
const _kCooldownSecs = 3600; // 1 h between repeated notifications per symbol

// Runs without a BuildContext (also in the background isolate), so the
// device locale is used instead of AppLocalizations.
String _t(String de, String en) =>
    Platform.localeName.startsWith('de') ? de : en;

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
  await notif.initialize(_initSettings);

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
          '${_t('Kurs', 'Price')} ${price.toStringAsFixed(2)} ≤ SL ${e.stopLoss!.toStringAsFixed(2)}');
      fired = true;
    }
    if (e.targetPrice != null && price >= e.targetPrice!) {
      await _notify(notif, '${e.symbol}_tp',
          '${_t('Zielkurs', 'Target price')}: ${e.symbol}',
          '${_t('Kurs', 'Price')} ${price.toStringAsFixed(2)} ≥ ${_t('Ziel', 'Target')} ${e.targetPrice!.toStringAsFixed(2)}');
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
    NotificationDetails(
      android: AndroidNotificationDetails(
        'stock_alarms',
        _t('Kursalarme', 'Price alerts'),
        channelDescription: _t('Stop-Loss und Zielkurs Benachrichtigungen',
            'Stop-loss and target price notifications'),
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    ),
  );
}

const _initSettings = InitializationSettings(
  android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  // Permission is requested explicitly when the first alarm is set.
  iOS: DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  ),
);

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

    // iOS has no periodic background work like Android's WorkManager –
    // alarms are only checked while the app is open (see checkNow).
    if (!Platform.isIOS) {
      await Workmanager().initialize(alarmCallbackDispatcher);
    }

    await _notif.initialize(_initSettings);

    await _notif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(AndroidNotificationChannel(
          'stock_alarms',
          _t('Kursalarme', 'Price alerts'),
          description: _t('Stop-Loss und Zielkurs Benachrichtigungen',
              'Stop-loss and target price notifications'),
          importance: Importance.high,
        ));
  }

  static Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final r = await _notif
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: false, sound: true);
      return r ?? false;
    }
    final r = await _notif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return r ?? false;
  }

  /// Schedules or cancels the periodic background check.
  static Future<void> updateSchedule(bool hasAlarms) async {
    if (Platform.isIOS) return;
    if (hasAlarms) {
      await Workmanager().registerPeriodicTask(
        _kUniqueTag,
        _kTaskName,
        frequency: const Duration(minutes: 15),
        // flexInterval lets WorkManager schedule within a ±5-min window,
        // which helps on Huawei/EMUI where rigid schedules are often skipped.
        flexInterval: const Duration(minutes: 5),
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
            '${_t('Kurs', 'Price')} ${price.toStringAsFixed(2)} ≤ SL ${e.stopLoss!.toStringAsFixed(2)}');
        fired = true;
      }
      if (e.targetPrice != null && price >= e.targetPrice!) {
        await _notify(_notif, '${e.symbol}_tp',
            '${_t('Zielkurs', 'Target price')}: ${e.symbol}',
            '${_t('Kurs', 'Price')} ${price.toStringAsFixed(2)} ≥ ${_t('Ziel', 'Target')} ${e.targetPrice!.toStringAsFixed(2)}');
        fired = true;
      }
      if (fired) await prefs.setInt('$_kLastNotif${e.symbol}', nowSec);
    }
  }
}
