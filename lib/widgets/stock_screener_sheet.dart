import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/chart_state.dart';
import '../services/screener_data_service.dart';

enum _Logic { and, or_ }

// Approximate stock counts per index (for UI display before data loads)
const _kIndexCounts = {0: 486, 1: 100, 2: 80, 3: 513, 4: 155, 5: 39, 6: 21, 7: 85};
const _kIndexLabels = {
  0: 'S&P 500',
  1: 'Nasdaq 100',
  2: 'Nasdaq Interessant',
  3: 'Russell 2000',
  4: 'NYSE 200',
  5: 'DAX 40',
  6: 'SMI 20',
  7: 'FTSE 100',
};

const _kPerfSteps = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

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

// In-memory singleton — survives sheet close/reopen within one app session
class _ScreenerMemory {
  static final _ScreenerMemory _i = _ScreenerMemory._();
  _ScreenerMemory._();

  int?          selectedPerf;
  String        kgvText         = '';
  _Logic?       logic;
  Set<int>      selectedIndices = {0};
  bool          searched        = false;
  String        generatedAt     = '';
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
  final _screenerService = ScreenerDataService();
  final _kgvController   = TextEditingController();
  final _mem             = _ScreenerMemory._i;

  int?     _selectedPerf;
  _Logic?  _logic;
  Set<int> _selectedIndices = {0};

  bool    _loading     = false;
  bool    _searched    = false;
  String? _error;
  String  _generatedAt = '';
  List<_ScreenerResult> _results = [];

  @override
  void initState() {
    super.initState();
    _selectedPerf    = _mem.selectedPerf;
    _kgvController.text = _mem.kgvText;
    _logic           = _mem.logic;
    _selectedIndices = Set.from(_mem.selectedIndices);
    _searched        = _mem.searched;
    _results         = List.from(_mem.results);
    _generatedAt     = _mem.generatedAt;
  }

  @override
  void dispose() {
    _kgvController.dispose();
    super.dispose();
  }

  void _saveToMemory() {
    _mem
      ..selectedPerf    = _selectedPerf
      ..kgvText         = _kgvController.text
      ..logic           = _logic
      ..selectedIndices = Set.from(_selectedIndices)
      ..searched        = _searched
      ..generatedAt     = _generatedAt
      ..results         = List.from(_results);
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
      _loading  = true;
      _error    = null;
      _results  = [];
      _searched = true;
    });

    try {
      // Download JSON once, then reuse from cache — typically instant after first load
      final data    = await _screenerService.load();
      final entries = _screenerService.entriesForIndices(_selectedIndices, data);

      final perfMin = _selectedPerf!.toDouble();
      final perfMax = _selectedPerf! < 100 ? (_selectedPerf! + 10).toDouble() : null;

      bool perfOk(double p) {
        if (perfMax == null) return p >= perfMin;
        return p >= perfMin && p < perfMax;
      }

      bool kgvOk(ScreenerEntry e) {
        if (maxKgv == null) return true;
        final pe = e.pe;
        return pe != null && pe > 0 && pe <= maxKgv;
      }

      // Local filter — runs instantly on the in-memory data
      final List<ScreenerEntry> candidates;
      if (maxKgv == null || (!useAnd && !useOr)) {
        candidates = entries.where((e) => perfOk(e.perf1y)).toList();
      } else {
        candidates = entries.where((e) {
          final pm = perfOk(e.perf1y);
          final km = kgvOk(e);
          return useAnd ? (pm && km) : (pm || km);
        }).toList();
      }

      candidates.sort((a, b) => b.perf1y.compareTo(a.perf1y));

      final results = candidates.take(50).map((e) => _ScreenerResult(
            symbol:         e.symbol,
            name:           e.name,
            price:          e.price,
            performancePct: e.perf1y,
          )).toList();

      if (mounted) {
        setState(() {
          _results     = results;
          _loading     = false;
          _generatedAt = data.generatedAt;
        });
        _saveToMemory();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
      }
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

          Expanded(
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: _buildFilters(l10n, colorScheme),
                ),
                const SliverToBoxAdapter(child: Divider(height: 1)),

                if (_loading)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off, size: 48),
                            const SizedBox(height: 12),
                            Text(l10n.errorLoading,
                                style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
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

          // Footer: disclaimer + data freshness
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.screenerDisclaimer,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant.withAlpha(150),
                  ),
                ),
                if (_generatedAt.isNotEmpty)
                  Text(
                    _formatGeneratedAt(_generatedAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant.withAlpha(120),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatGeneratedAt(String iso) {
    try {
      final dt  = DateTime.parse(iso).toLocal();
      final fmt = DateFormat('dd.MM.yyyy HH:mm');
      return 'Daten vom ${fmt.format(dt)}';
    } catch (_) {
      return '';
    }
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
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                      fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(l10n.screenerUniverseLabel,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final id in _kIndexLabels.keys)
                _buildIndexChip(id, _kIndexLabels[id]!),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _selectedIndices.isEmpty
                ? l10n.screenerUniverseNone
                : l10n.screenerUniverseCount(_totalCount()),
            style: TextStyle(
                fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.search),
              label: Text(l10n.screenerSearch),
              onPressed: _selectedPerf != null &&
                      !_loading &&
                      _selectedIndices.isNotEmpty
                  ? _search
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  int _totalCount() => _selectedIndices.fold(
      0, (sum, id) => sum + (_kIndexCounts[id] ?? 0));

  String _logicHint(AppLocalizations l10n) {
    if (_kgvController.text.trim().isEmpty) return l10n.screenerLogicHintNoKgv;
    if (_logic == null) return l10n.screenerLogicHintNone;
    if (_logic == _Logic.and) return l10n.screenerLogicHintAnd;
    return l10n.screenerLogicHintOr;
  }

  Widget _buildIndexChip(int id, String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedIndices.contains(id),
      onSelected: _loading
          ? null
          : (v) {
              setState(() {
                if (v) {
                  _selectedIndices.add(id);
                } else {
                  _selectedIndices.remove(id);
                }
              });
              _saveToMemory();
            },
    );
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
                color: result.performancePct >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
      title: Text(
        result.price > 0 ? fmt.format(result.price) : '—',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
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
            icon: Icon(inWl ? Icons.bookmark : Icons.bookmark_border),
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
