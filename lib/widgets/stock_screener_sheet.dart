import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/sp500_symbols.dart';
import '../l10n/app_localizations.dart';
import '../models/chart_state.dart';
import '../services/yahoo_finance_service.dart';

enum _Logic { and, or_ }

class _ScreenerResult {
  final String symbol;
  final String name;
  final double price;
  final double performancePct;
  const _ScreenerResult({
    required this.symbol,
    required this.name,
    required this.price,
    required this.performancePct,
  });
}

const _kPerfSteps  = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
const _kConcurrent = 20;

// In-memory singleton — survives sheet close/reopen within the same app session
class _ScreenerMemory {
  static final _ScreenerMemory _i = _ScreenerMemory._();
  _ScreenerMemory._();

  int?             selectedPerf;
  String           kgvText      = '';
  _Logic?          logic;
  int              universeMode = 0; // 0=S&P500, 1=+NASDAQ100, 2=+Erweitert
  bool             searched     = false;
  List<_ScreenerResult> results = const [];
}

class StockScreenerSheet extends StatefulWidget {
  const StockScreenerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ChartState>(),
        child: const StockScreenerSheet(),
      ),
    );
  }

  @override
  State<StockScreenerSheet> createState() => _StockScreenerSheetState();
}

class _StockScreenerSheetState extends State<StockScreenerSheet> {
  final _service       = YahooFinanceService();
  final _kgvController = TextEditingController();
  final _mem           = _ScreenerMemory._i;

  int?    _selectedPerf;
  _Logic? _logic;
  int     _universeMode  = 0;

  bool    _loading      = false;
  bool    _searched     = false;
  String? _error;
  List<_ScreenerResult> _results = [];
  double  _progress     = 0.0;
  String  _progressText = '';

  @override
  void initState() {
    super.initState();
    _selectedPerf        = _mem.selectedPerf;
    _kgvController.text  = _mem.kgvText;
    _logic               = _mem.logic;
    _universeMode        = _mem.universeMode;
    _searched            = _mem.searched;
    _results             = List.from(_mem.results);
  }

  @override
  void dispose() {
    _kgvController.dispose();
    super.dispose();
  }

  void _saveToMemory() {
    _mem
      ..selectedPerf = _selectedPerf
      ..kgvText      = _kgvController.text
      ..logic        = _logic
      ..universeMode = _universeMode
      ..searched     = _searched
      ..results      = List.from(_results);
  }

  String _perfLabel(int step) =>
      step == 100 ? '100+%' : '$step – ${step + 9}%';

  Future<void> _search() async {
    if (_selectedPerf == null) return;
    final kgvText = _kgvController.text.trim();
    final maxKgv  = kgvText.isEmpty ? null : double.tryParse(kgvText);
    final useAnd  = _logic == _Logic.and;
    final useOr   = _logic == _Logic.or_;

    setState(() {
      _loading = true; _error = null; _results = [];
      _searched = true; _progress = 0.0; _progressText = '';
    });

    try {
      // Mode 0: try live Yahoo fetch (with hardcoded fallback).
      // Modes 1/2: always use the static lists (NASDAQ/Extended have no live source).
      final allSymbols = _universeMode == 0
          ? await _service.fetchSp500Symbols(kSp500Symbols)
          : screenerUniverse(mode: _universeMode);

      // ── Phase 1: fetch performance + price for every symbol ─────────────────
      final dataMap = <String, ScreenerStockData>{};

      for (var i = 0; i < allSymbols.length; i += _kConcurrent) {
        if (!mounted) return;
        final batch = allSymbols.sublist(
            i, math.min(i + _kConcurrent, allSymbols.length));
        final results =
            await Future.wait(batch.map(_service.fetchScreenerStock));
        for (var j = 0; j < batch.length; j++) {
          final d = results[j];
          if (d != null) dataMap[batch[j]] = d;
        }
        if (mounted) {
          setState(() {
            _progress =
                math.min(1.0, (i + _kConcurrent) / allSymbols.length);
            _progressText =
                '${math.min(i + _kConcurrent, allSymbols.length)} / ${allSymbols.length}';
          });
        }
      }

      // ── Performance bounds ──────────────────────────────────────────────────
      final perfMin = _selectedPerf!.toDouble();
      final perfMax =
          _selectedPerf! < 100 ? (_selectedPerf! + 10).toDouble() : null;

      bool perfOk(double p) {
        if (perfMax == null) return p >= perfMin;
        return p >= perfMin && p < perfMax;
      }

      // ── Phase 2: apply filters ──────────────────────────────────────────────
      List<_ScreenerResult> candidates;

      if (maxKgv == null || (!useAnd && !useOr)) {
        // Performance-only
        candidates = dataMap.values
            .where((d) => perfOk(d.performancePct))
            .map((d) => _ScreenerResult(
                  symbol: d.symbol,
                  name: d.name,
                  price: d.price,
                  performancePct: d.performancePct,
                ))
            .toList();
      } else {
        // Need PE data
        final needPe = useAnd
            ? dataMap.values
                .where((d) => perfOk(d.performancePct))
                .map((d) => d.symbol)
                .toList()
            : dataMap.keys.toList(); // OR needs PE for everyone

        if (mounted) {
          setState(() {
            _progress     = 0.0;
            _progressText = 'KGV: 0 / ${needPe.length}';
          });
        }

        final peMap = <String, double?>{};
        for (var i = 0; i < needPe.length; i += _kConcurrent) {
          if (!mounted) return;
          final batch = needPe.sublist(
              i, math.min(i + _kConcurrent, needPe.length));
          final peResults =
              await Future.wait(batch.map(_service.fetchTrailingPE));
          for (var j = 0; j < batch.length; j++) {
            peMap[batch[j]] = peResults[j];
          }
          if (mounted) {
            final done = math.min(i + _kConcurrent, needPe.length);
            setState(() {
              _progress     = done / needPe.length;
              _progressText = 'KGV: $done / ${needPe.length}';
            });
          }
        }

        bool kgvOk(String sym) {
          final pe = peMap[sym];
          return pe != null && pe > 0 && pe <= maxKgv;
        }

        candidates = dataMap.values.where((d) {
          final pm = perfOk(d.performancePct);
          final km = kgvOk(d.symbol);
          return useAnd ? (pm && km) : (pm || km);
        }).map((d) => _ScreenerResult(
              symbol: d.symbol,
              name: d.name,
              price: d.price,
              performancePct: d.performancePct,
            )).toList();
      }

      candidates
          .sort((a, b) => b.performancePct.compareTo(a.performancePct));

      if (mounted) {
        setState(() {
          _results  = candidates.take(50).toList();
          _loading  = false;
          _progress = 1.0;
        });
        _saveToMemory();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.screenerInfoTitle),
        content: SingleChildScrollView(
          child: Text(l10n.screenerInfoBody,
              style: const TextStyle(height: 1.5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n        = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final fmt         = NumberFormat('#,##0.00');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (ctx, scrollController) => Column(
        children: [
          // ── Fixed: drag handle ──────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // ── Fixed: title bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.manage_search),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.screenerTitle,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: l10n.screenerInfoTitle,
                  onPressed: () => _showInfo(context),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Scrollable: filters + results share ONE scroll view ─────────────
          Expanded(
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                // Filter controls — scroll up out of view when reading results
                SliverToBoxAdapter(
                  child: _buildFilters(l10n, colorScheme),
                ),
                const SliverToBoxAdapter(
                    child: Divider(height: 1)),

                // Results / loading / hint
                if (_loading)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LinearProgressIndicator(
                                value: _progress == 0 ? null : _progress),
                            const SizedBox(height: 12),
                            Text(l10n.screenerLoading),
                            if (_progressText.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(_progressText,
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                else if (_error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(l10n.errorLoading,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  )
                else if (!_searched)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(l10n.screenerHint,
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant)),
                    ),
                  )
                else if (_results.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text(l10n.screenerNoResults)),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (c, i) => _ResultTile(result: _results[i], fmt: fmt),
                      childCount: _results.length,
                    ),
                  ),
              ],
            ),
          ),
          // ── Fixed: disclaimer ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              l10n.screenerDisclaimer,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant.withAlpha(150),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(AppLocalizations l10n, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.screenerPerfLabel,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedPerf,
                isExpanded: true,
                hint: Text(l10n.screenerPerfHint),
                items: _kPerfSteps
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(_perfLabel(s)),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedPerf = v);
                  _saveToMemory();
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.screenerKgvLabel,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _kgvController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              hintText: l10n.screenerKgvHint,
            ),
            onChanged: (_) {
              setState(() {});
              _saveToMemory();
            },
          ),
          const SizedBox(height: 12),
          Text(l10n.screenerLogicLabel,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              FilterChip(
                label: const Text('AND'),
                selected: _logic == _Logic.and,
                onSelected: (v) {
                  setState(() => _logic = v ? _Logic.and : null);
                  _saveToMemory();
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('OR'),
                selected: _logic == _Logic.or_,
                onSelected: (v) {
                  setState(() => _logic = v ? _Logic.or_ : null);
                  _saveToMemory();
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _logicHint(l10n),
                  style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(l10n.screenerUniverseLabel,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('S&P 500')),
              ButtonSegment(value: 1, label: Text('+NASDAQ 100')),
              ButtonSegment(value: 2, label: Text('+Erweitert')),
            ],
            selected: {_universeMode},
            onSelectionChanged: _loading
                ? null
                : (s) {
                    setState(() => _universeMode = s.first);
                    _saveToMemory();
                  },
            style: ButtonStyle(
              textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 12)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _universeHint(l10n),
            style: TextStyle(
                fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.search),
              label: Text(l10n.screenerSearch),
              onPressed:
                  _selectedPerf != null && !_loading ? _search : null,
            ),
          ),
        ],
      ),
    );
  }

  String _logicHint(AppLocalizations l10n) {
    if (_kgvController.text.trim().isEmpty) return l10n.screenerLogicHintNoKgv;
    if (_logic == null) return l10n.screenerLogicHintNone;
    if (_logic == _Logic.and) return l10n.screenerLogicHintAnd;
    return l10n.screenerLogicHintOr;
  }

  String _universeHint(AppLocalizations l10n) {
    switch (_universeMode) {
      case 1:  return l10n.screenerUniverseNasdaq;
      case 2:  return l10n.screenerUniverseExtended;
      default: return l10n.screenerUniverseSp;
    }
  }

}

class _ResultTile extends StatelessWidget {
  final _ScreenerResult result;
  final NumberFormat fmt;
  const _ResultTile({required this.result, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ChartState>();
    final inWl  = state.isInWatchlist(result.symbol);
    final cs    = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      leading: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.symbol,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            Text(
              '${result.performancePct >= 0 ? '+' : ''}${result.performancePct.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11,
                color: result.performancePct >= 0
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ],
        ),
      ),
      title: Text(fmt.format(result.price),
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        result.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'Chart',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ChartState>().loadStock1(result.symbol);
            },
          ),
          IconButton(
            icon: Icon(
                inWl ? Icons.bookmark : Icons.bookmark_border),
            tooltip: 'Watchlist',
            visualDensity: VisualDensity.compact,
            onPressed: () => context
                .read<ChartState>()
                .toggleWatchlist(result.symbol, result.name),
          ),
        ],
      ),
    );
  }
}
