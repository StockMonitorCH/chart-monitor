import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/stock_data.dart';
import '../services/yahoo_finance_service.dart';
import 'index_data.dart';

// ── Shared index list (used by IndexSheet too) ────────────────────────────────

class _PerfEntry {
  final String symbol;
  final String name;
  final double perf;
  const _PerfEntry(this.symbol, this.name, this.perf);
}

// ── Sheet ─────────────────────────────────────────────────────────────────────

class IndexComparisonSheet extends StatefulWidget {
  final List<WatchlistEntry> watchlist;

  const IndexComparisonSheet({super.key, required this.watchlist});

  static Future<void> show(BuildContext context,
      {required List<WatchlistEntry> watchlist}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => IndexComparisonSheet(watchlist: watchlist),
    );
  }

  @override
  State<IndexComparisonSheet> createState() => _IndexComparisonSheetState();
}

class _IndexComparisonSheetState extends State<IndexComparisonSheet> {
  static const _kRange = 'idx_cmp_range';
  static const _kShowWl = 'idx_cmp_watchlist';
  static const _kDeselected = 'idx_cmp_deselected';

  // Available ranges for index comparison (no custom, no intraday)
  static const _ranges = [
    TimeRange.oneWeek,
    TimeRange.oneMonth,
    TimeRange.threeMonths,
    TimeRange.sixMonths,
    TimeRange.ytd,
    TimeRange.oneYear,
    TimeRange.twoYears,
    TimeRange.fiveYears,
  ];

  TimeRange _range = TimeRange.oneYear;
  bool _showWatchlist = false;
  Set<String> _deselected = {}; // symbols to HIDE (empty = show all)

  List<_PerfEntry> _entries = [];
  bool _loading = false;

  final _service = YahooFinanceService();

  @override
  void initState() {
    super.initState();
    _loadPrefs().then((_) => _fetchAll());
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final rangeIdx = prefs.getInt(_kRange) ?? TimeRange.oneYear.index;
    final deselList = prefs.getStringList(_kDeselected) ?? [];
    setState(() {
      _range = TimeRange.values[rangeIdx.clamp(0, TimeRange.values.length - 1)];
      _showWatchlist = prefs.getBool(_kShowWl) ?? false;
      _deselected = Set.from(deselList);
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kRange, _range.index);
    await prefs.setBool(_kShowWl, _showWatchlist);
    await prefs.setStringList(_kDeselected, _deselected.toList());
  }

  Future<void> _fetchAll() async {
    if (!mounted) return;
    setState(() { _loading = true; _entries = []; });

    // Symbols to fetch: selected indices only (watchlist handled separately)
    final toFetch = <(String, String)>[]; // (symbol, displayName)
    for (final idx in kIndices) {
      if (!_deselected.contains(idx.symbol)) {
        toFetch.add((idx.symbol, idx.name));
      }
    }
    final results = await Future.wait(
      toFetch.map((t) => _fetchPerf(t.$1, t.$2)),
    );

    final entries = results.whereType<_PerfEntry>().toList();

    // Watchlist → ONE combined portfolio bar (equal-weighted average)
    if (_showWatchlist && widget.watchlist.isNotEmpty) {
      final wlResults = await Future.wait(
        widget.watchlist.map((w) => _fetchPerf(w.symbol, w.name)),
      );
      final validPerfs = wlResults
          .whereType<_PerfEntry>()
          .map((e) => e.perf)
          .toList();
      if (validPerfs.isNotEmpty) {
        final avg = validPerfs.reduce((a, b) => a + b) / validPerfs.length;
        entries.add(_PerfEntry('WATCHLIST', 'Watchlist', avg));
      }
    }

    // Sort descending by performance
    entries.sort((a, b) => b.perf.compareTo(a.perf));

    if (mounted) setState(() { _entries = entries; _loading = false; });
  }

  Future<_PerfEntry?> _fetchPerf(String symbol, String name) async {
    try {
      final data = await _service.fetchChartData(
        symbol, _range,
        forceInterval: '1d',
      );
      if (data.length < 2) return null;
      final perf = (data.last.close - data.first.close) / data.first.close * 100;
      return _PerfEntry(symbol, name, perf);
    } catch (_) {
      return null;
    }
  }

  void _changeRange(TimeRange r) {
    setState(() => _range = r);
    _savePrefs();
    _fetchAll();
  }

  void _toggleWatchlist(bool v) {
    setState(() => _showWatchlist = v);
    _savePrefs();
    _fetchAll();
  }

  Future<void> _openSelectDialog() async {
    final selected = Set<String>.from(kIndices.map((e) => e.symbol))
      ..removeAll(_deselected);

    await showDialog<void>(
      context: context,
      builder: (ctx) => _SelectIndicesDialog(
        initialSelected: selected,
        onConfirm: (newSelected) {
          final newDeselected = kIndices
              .map((e) => e.symbol)
              .where((s) => !newSelected.contains(s))
              .toSet();
          setState(() => _deselected = newDeselected);
          _savePrefs();
          _fetchAll();
        },
      ),
    );
  }

  String _rangeLabel(TimeRange r, AppLocalizations l10n) {
    switch (r) {
      case TimeRange.oneWeek: return l10n.timeRange1W;
      case TimeRange.oneMonth: return l10n.timeRange1M;
      case TimeRange.threeMonths: return l10n.timeRange3M;
      case TimeRange.sixMonths: return l10n.timeRange6M;
      case TimeRange.ytd: return l10n.timeRangeYtd;
      case TimeRange.oneYear: return l10n.timeRange1Y;
      case TimeRange.twoYears: return l10n.timeRange2Y;
      case TimeRange.fiveYears: return l10n.timeRange5Y;
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  Icon(Icons.stacked_bar_chart,
                      color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.indexCompareTitle,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.tune_outlined, size: 20),
                    tooltip: l10n.indexCompareSelectIndices,
                    onPressed: _openSelectDialog,
                  ),
                ],
              ),
            ),
            // ── Time range row ───────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Row(
                children: _ranges.map((r) {
                  final sel = _range == r;
                  final color = Theme.of(context).colorScheme.primary;
                  return GestureDetector(
                    onTap: () => _changeRange(r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        color: sel ? color : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _rangeLabel(r, l10n),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              sel ? FontWeight.bold : FontWeight.normal,
                          color: sel
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(180),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // ── Watchlist toggle ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Row(
                children: [
                  const Icon(Icons.bookmarks_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text(l10n.indexCompareShowWatchlist,
                      style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  Switch(
                    value: _showWatchlist,
                    onChanged: widget.watchlist.isEmpty ? null : _toggleWatchlist,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── Chart area ───────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _entries.isEmpty
                      ? Center(
                          child: Text(l10n.noData,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(120))))
                      : _buildChart(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChart(BuildContext context) {
    if (_entries.isEmpty) return const SizedBox.shrink();

    const barWidth = 28.0;
    const groupSpace = 6.0;
    final count = _entries.length;
    final chartWidth =
        math.max(MediaQuery.of(context).size.width - 72, count * (barWidth + groupSpace + 4));

    final maxAbs = _entries.map((e) => e.perf.abs()).reduce(math.max);
    final minY = (_entries.map((e) => e.perf).reduce(math.min) * 1.15).clamp(-maxAbs * 1.15, 0.0);
    final maxY = (_entries.map((e) => e.perf).reduce(math.max) * 1.15).clamp(0.0, maxAbs * 1.15);
    // Ensure range around zero is always visible
    final chartMinY = math.min(minY, -0.5);
    final chartMaxY = math.max(maxY, 0.5);

    final barGroups = _entries.asMap().entries.map((e) {
      final entry = e.value;
      final isUp = entry.perf >= 0;
      final barColor = isUp ? Colors.green.shade400 : Colors.red.shade400;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: entry.perf,
            fromY: 0,
            color: barColor,
            width: barWidth,
            borderRadius: BorderRadius.vertical(
              top: isUp ? const Radius.circular(3) : Radius.zero,
              bottom: isUp ? Radius.zero : const Radius.circular(3),
            ),
          ),
        ],
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: SizedBox(
        width: chartWidth,
        child: BarChart(
          BarChartData(
            minY: chartMinY,
            maxY: chartMaxY,
            barGroups: barGroups,
            groupsSpace: groupSpace,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) =>
                    Theme.of(context).colorScheme.inverseSurface,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final entry = _entries[groupIndex];
                  final pct = rod.toY;
                  final sign = pct >= 0 ? '+' : '';
                  // For known indices, also show region + raw symbol
                  final idxEntry = kIndices.where(
                      (i) => i.symbol == entry.symbol).firstOrNull;
                  final subtitle = idxEntry != null
                      ? '${idxEntry.region}  ·  ${entry.symbol.replaceAll('^', '')}'
                      : null;
                  final lines = [
                    entry.name,
                    ?subtitle,
                    '$sign${pct.toStringAsFixed(2)}%',
                  ];
                  return BarTooltipItem(
                    lines.join('\n'),
                    TextStyle(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.min || value == meta.max) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(150),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= _entries.length) {
                      return const SizedBox.shrink();
                    }
                    final entry = _entries[idx];
                    // Short label: strip ^, max 6 chars
                    final label =
                        entry.symbol.replaceAll('^', '');
                    return SideTitleWidget(
                      meta: meta,
                      space: 4,
                      angle: label.length > 4 ? -math.pi / 4 : 0,
                      child: Text(
                        label.length > 6 ? label.substring(0, 6) : label,
                        style: TextStyle(
                          fontSize: 9,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(160),
                        ),
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(
                color: v == 0
                    ? Theme.of(context).dividerColor.withAlpha(120)
                    : Theme.of(context).dividerColor.withAlpha(40),
                strokeWidth: v == 0 ? 1.2 : 0.6,
              ),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }
}

// ── Select indices dialog ─────────────────────────────────────────────────────

class _SelectIndicesDialog extends StatefulWidget {
  final Set<String> initialSelected;
  final void Function(Set<String>) onConfirm;

  const _SelectIndicesDialog({
    required this.initialSelected,
    required this.onConfirm,
  });

  @override
  State<_SelectIndicesDialog> createState() => _SelectIndicesDialogState();
}

class _SelectIndicesDialogState extends State<_SelectIndicesDialog> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.indexCompareSelectIndices),
      contentPadding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Select all / none buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => setState(
                        () => _selected = kIndices.map((e) => e.symbol).toSet()),
                    child: Text(l10n.indexCompareAll),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selected = {}),
                    child: Text(l10n.indexCompareNone),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: kIndices.map((entry) {
                  final sel = _selected.contains(entry.symbol);
                  return CheckboxListTile(
                    dense: true,
                    value: sel,
                    title: Text(entry.name, style: const TextStyle(fontSize: 13)),
                    subtitle: Text('${entry.region} · ${entry.symbol}',
                        style: const TextStyle(fontSize: 11)),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected.add(entry.symbol);
                        } else {
                          _selected.remove(entry.symbol);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.wlAlarmCancel),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(_selected);
            Navigator.of(context).pop();
          },
          child: Text(l10n.wlAlarmSave),
        ),
      ],
    );
  }
}
