import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/chart_state.dart';
import '../models/stock_data.dart';
import '../services/yahoo_finance_service.dart';
import '../services/alarm_service.dart';
import '../utils/gics_mapper.dart';
import 'search_field.dart';

class WatchlistSheet extends StatefulWidget {
  const WatchlistSheet({super.key});

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
        child: const WatchlistSheet(),
      ),
    );
  }

  @override
  State<WatchlistSheet> createState() => _WatchlistSheetState();
}

class _WatchlistSheetState extends State<WatchlistSheet> {
  final _service = YahooFinanceService();
  final Map<String, StockInfo?> _prices = {};
  final Map<String, double?> _perf = {};
  bool _loadingPrices = false;
  bool _loadingPerf = false;
  bool _showSearch = false;
  String? _infoMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAll());
  }

  Future<void> _fetchAll() async {
    await _fetchPrices();
    if (!mounted) return;
    final state = context.read<ChartState>();
    // Fetch missing sectors in background so GICS sort works
    // ignore: unawaited_futures
    state.fetchMissingSectors();
    final range = state.watchlistRange;
    if (range != WatchlistRange.oneDay) await _fetchPerf(range);
    _checkAlarms();
  }

  Future<void> _fetchPrices() async {
    final state = context.read<ChartState>();
    if (state.watchlist.isEmpty) return;
    setState(() => _loadingPrices = true);
    await Future.wait(state.watchlist.map((e) async {
      try {
        final info = await _service.fetchStockInfo(e.symbol);
        if (mounted) setState(() => _prices[e.symbol] = info);
      } catch (_) {
        if (mounted) setState(() => _prices[e.symbol] = null);
      }
    }));
    if (mounted) setState(() => _loadingPrices = false);
  }

  Future<void> _fetchPerf(WatchlistRange range) async {
    final state = context.read<ChartState>();
    if (state.watchlist.isEmpty) return;
    setState(() => _loadingPerf = true);
    await Future.wait(state.watchlist.map((e) async {
      try {
        final pct = await _service.fetchPeriodPerformance(e.symbol, range.asTimeRange);
        if (mounted) setState(() => _perf[e.symbol] = pct);
      } catch (_) {
        if (mounted) setState(() => _perf[e.symbol] = null);
      }
    }));
    if (mounted) setState(() => _loadingPerf = false);
  }

  void _checkAlarms() {
    final state = context.read<ChartState>();
    final prices = <String, double?>{
      for (final e in state.watchlist) e.symbol: _prices[e.symbol]?.currentPrice,
    };
    AlarmService.checkNow(
      state.watchlist.map((e) => (
        symbol: e.symbol,
        stopLoss: e.stopLoss,
        targetPrice: e.targetPrice,
      )).toList(),
      prices,
    );
  }

  double? _perfFor(String symbol) {
    final range = context.read<ChartState>().watchlistRange;
    if (range == WatchlistRange.oneDay) return _prices[symbol]?.changePercent;
    return _perf[symbol];
  }

  List<WatchlistEntry> _sorted(ChartState state) {
    final list = List<WatchlistEntry>.from(state.watchlist);
    switch (state.watchlistSortMode) {
      case WatchlistSortMode.manual:
        break;
      case WatchlistSortMode.nameAZ:
        list.sort((a, b) => a.symbol.compareTo(b.symbol));
      case WatchlistSortMode.nameZA:
        list.sort((a, b) => b.symbol.compareTo(a.symbol));
      case WatchlistSortMode.perfDesc:
        list.sort((a, b) {
          final pa = _perfFor(a.symbol);
          final pb = _perfFor(b.symbol);
          if (pa == null && pb == null) return 0;
          if (pa == null) return 1;
          if (pb == null) return -1;
          return pb.compareTo(pa);
        });
      case WatchlistSortMode.perfAsc:
        list.sort((a, b) {
          final pa = _perfFor(a.symbol);
          final pb = _perfFor(b.symbol);
          if (pa == null && pb == null) return 0;
          if (pa == null) return 1;
          if (pb == null) return -1;
          return pa.compareTo(pb);
        });
      case WatchlistSortMode.gics:
        list.sort((a, b) {
          final sa = a.sector != null ? GicsMapper.sector(a.sector) : '~';
          final sb = b.sector != null ? GicsMapper.sector(b.sector) : '~';
          final c = sa.compareTo(sb);
          return c != 0 ? c : a.symbol.compareTo(b.symbol);
        });
    }
    return list;
  }

  Future<void> _onRangeChanged(WatchlistRange range) async {
    context.read<ChartState>().setWatchlistRange(range);
    if (range != WatchlistRange.oneDay) {
      setState(() => _perf.clear());
      await _fetchPerf(range);
    }
  }

  void _showAlarmDialog(WatchlistEntry entry) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ChartState>(),
        child: _AlarmDialog(
          entry: entry,
          currentPrice: _prices[entry.symbol]?.currentPrice,
          currency: _prices[entry.symbol]?.currency ?? '',
        ),
      ),
    );
  }

  String _rangeLabel(WatchlistRange range, AppLocalizations l10n) {
    switch (range) {
      case WatchlistRange.oneDay:      return l10n.timeRange1D;
      case WatchlistRange.oneWeek:     return l10n.timeRange1W;
      case WatchlistRange.oneMonth:    return l10n.timeRange1M;
      case WatchlistRange.threeMonths: return l10n.timeRange3M;
      case WatchlistRange.sixMonths:   return l10n.timeRange6M;
      case WatchlistRange.ytd:         return l10n.timeRangeYtd;
      case WatchlistRange.oneYear:     return l10n.timeRange1Y;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<ChartState>();
    final cs = Theme.of(context).colorScheme;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final sorted = _sorted(state);

    return DraggableScrollableSheet(
      initialChildSize: 0.97,
      maxChildSize: 0.97,
      minChildSize: 0.35,
      expand: false,
      builder: (_, sc) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
            child: Row(
              children: [
                Icon(Icons.bookmarks_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(l10n.watchlistTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                // Range picker
                _RangeChip(
                  label: _rangeLabel(state.watchlistRange, l10n),
                  onSelected: _onRangeChanged,
                  current: state.watchlistRange,
                  rangeLabel: (r) => _rangeLabel(r, l10n),
                ),
                const SizedBox(width: 2),
                // Sort menu
                PopupMenuButton<WatchlistSortMode>(
                  initialValue: state.watchlistSortMode,
                  tooltip: '',
                  onSelected: (m) => context.read<ChartState>().setWatchlistSortMode(m),
                  icon: Icon(
                    Icons.sort,
                    size: 20,
                    color: state.watchlistSortMode != WatchlistSortMode.manual
                        ? cs.primary
                        : cs.onSurface.withAlpha(140),
                  ),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: WatchlistSortMode.manual,
                        child: Text(l10n.wlSortManual)),
                    PopupMenuItem(value: WatchlistSortMode.nameAZ,
                        child: Text(l10n.wlSortAZ)),
                    PopupMenuItem(value: WatchlistSortMode.nameZA,
                        child: Text(l10n.wlSortZA)),
                    const PopupMenuDivider(),
                    PopupMenuItem(value: WatchlistSortMode.perfDesc,
                        child: Text(l10n.wlSortPerfDesc)),
                    PopupMenuItem(value: WatchlistSortMode.perfAsc,
                        child: Text(l10n.wlSortPerfAsc)),
                    const PopupMenuDivider(),
                    PopupMenuItem(value: WatchlistSortMode.gics,
                        child: Text(l10n.wlSortGics)),
                  ],
                ),
                // Add / close search
                IconButton(
                  icon: Icon(_showSearch ? Icons.close : Icons.add,
                      size: 22, color: cs.primary),
                  tooltip: _showSearch ? l10n.close : l10n.watchlistAdd,
                  onPressed: () => setState(() => _showSearch = !_showSearch),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Info message
          if (_infoMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.primary.withAlpha(80)),
              ),
              child: Text(_infoMessage!,
                  style: TextStyle(fontSize: 13, color: cs.primary)),
            ),
          // Search field
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SearchField(
                label: l10n.watchlistAdd,
                accentColor: cs.primary,
                onSelected: (r) async {
                  final st = context.read<ChartState>();
                  if (st.isInWatchlist(r.symbol)) {
                    setState(() {
                      _showSearch = false;
                      _infoMessage = '${r.symbol} bereits in der Watchlist';
                    });
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _infoMessage = null);
                    });
                    return;
                  }
                  await st.toggleWatchlist(r.symbol, r.shortName);
                  setState(() => _showSearch = false);
                  _fetchAll();
                },
              ),
            ),
          const Divider(height: 1),
          // List
          Expanded(
            child: sorted.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bookmarks_outlined, size: 48,
                            color: cs.onSurface.withAlpha(60)),
                        const SizedBox(height: 12),
                        Text(l10n.watchlistEmpty,
                            style: TextStyle(color: cs.onSurface.withAlpha(120))),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: sc,
                    padding: EdgeInsets.only(bottom: 16 + bottomPad),
                    itemCount: sorted.length,
                    separatorBuilder: (context2, i) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final entry = sorted[idx];
                      final info = _prices[entry.symbol];
                      final perf = _perfFor(entry.symbol);
                      final perfLoading = _loadingPerf && !_perf.containsKey(entry.symbol)
                          && state.watchlistRange != WatchlistRange.oneDay;
                      final showSector = state.watchlistSortMode == WatchlistSortMode.gics
                          && entry.sector != null;
                      return _WatchlistTile(
                        entry: entry,
                        info: info,
                        perf: perf,
                        loading: _loadingPrices && !_prices.containsKey(entry.symbol),
                        perfLoading: perfLoading,
                        showSector: showSector,
                        onTap: () {
                          Navigator.pop(context);
                          context.read<ChartState>().loadStock1(entry.symbol);
                        },
                        onAlarm: () => _showAlarmDialog(entry),
                        onRemove: () {
                          context.read<ChartState>().toggleWatchlist(entry.symbol, entry.name);
                          _prices.remove(entry.symbol);
                          _perf.remove(entry.symbol);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Range chip ────────────────────────────────────────────────────────────────

class _RangeChip extends StatelessWidget {
  final String label;
  final WatchlistRange current;
  final Future<void> Function(WatchlistRange) onSelected;
  final String Function(WatchlistRange) rangeLabel;

  const _RangeChip({
    required this.label,
    required this.current,
    required this.onSelected,
    required this.rangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<WatchlistRange>(
      initialValue: current,
      tooltip: '',
      onSelected: onSelected,
      itemBuilder: (_) => WatchlistRange.values
          .map((r) => PopupMenuItem(value: r, child: Text(rangeLabel(r))))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline.withAlpha(120)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: cs.primary,
                fontWeight: FontWeight.w600)),
            Icon(Icons.arrow_drop_down, size: 16, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _WatchlistTile extends StatelessWidget {
  final WatchlistEntry entry;
  final StockInfo? info;
  final double? perf;
  final bool loading;
  final bool perfLoading;
  final bool showSector;
  final VoidCallback onTap;
  final VoidCallback onAlarm;
  final VoidCallback onRemove;

  const _WatchlistTile({
    required this.entry,
    required this.info,
    required this.perf,
    required this.loading,
    required this.perfLoading,
    required this.showSector,
    required this.onTap,
    required this.onAlarm,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = perf ?? 0.0;
    final up = pct >= 0;
    final perfColor = perf != null ? (up ? Colors.green : Colors.red) : cs.onSurface.withAlpha(100);
    final hasAlarm = entry.hasAlarm;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Symbol + name column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.symbol,
                      style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 14, color: cs.primary)),
                  Text(entry.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12,
                          color: cs.onSurface.withAlpha(140))),
                  if (showSector && entry.sector != null)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(GicsMapper.sector(entry.sector),
                          style: TextStyle(fontSize: 10,
                              color: cs.onSurface.withAlpha(160))),
                    ),
                ],
              ),
            ),
            // Price + performance column
            if (loading)
              const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 1.5))
            else if (info != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${info!.currentPrice.toStringAsFixed(info!.currentPrice < 10 ? 3 : 2)} ${info!.currency}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  if (perfLoading)
                    const SizedBox(width: 12, height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5))
                  else if (perf != null)
                    Text(
                      '${up ? '+' : ''}${pct.toStringAsFixed(2)}%',
                      style: TextStyle(fontSize: 12, color: perfColor,
                          fontWeight: FontWeight.w500),
                    ),
                ],
              ),
            ],
            const SizedBox(width: 4),
            // Alarm bell
            IconButton(
              icon: Icon(
                hasAlarm ? Icons.notifications_active : Icons.notifications_none,
                size: 20,
                color: hasAlarm ? Colors.amber.shade600 : cs.onSurface.withAlpha(100),
              ),
              onPressed: onAlarm,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
            // Remove
            IconButton(
              icon: Icon(Icons.bookmark_remove_outlined, size: 20,
                  color: cs.onSurface.withAlpha(120)),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Alarm dialog ──────────────────────────────────────────────────────────────

class _AlarmDialog extends StatefulWidget {
  final WatchlistEntry entry;
  final double? currentPrice;
  final String currency;

  const _AlarmDialog({
    required this.entry,
    this.currentPrice,
    required this.currency,
  });

  @override
  State<_AlarmDialog> createState() => _AlarmDialogState();
}

class _AlarmDialogState extends State<_AlarmDialog> {
  late final TextEditingController _slCtrl;
  late final TextEditingController _tpCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _slCtrl = TextEditingController(
        text: widget.entry.stopLoss?.toStringAsFixed(2) ?? '');
    _tpCtrl = TextEditingController(
        text: widget.entry.targetPrice?.toStringAsFixed(2) ?? '');
  }

  @override
  void dispose() {
    _slCtrl.dispose();
    _tpCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(double? sl, double? tp) async {
    setState(() => _saving = true);
    // Request notification permission if first alarm
    if ((sl != null || tp != null) && !widget.entry.hasAlarm) {
      await AlarmService.requestPermission();
    }
    if (!mounted) return;
    await context.read<ChartState>().updateAlarm(widget.entry.symbol, sl, tp);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final price = widget.currentPrice;
    final currency = widget.currency;
    final hasAlarm = widget.entry.hasAlarm;

    return AlertDialog(
      title: Text(l10n.wlAlarmTitle(widget.entry.symbol)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (price != null) ...[
            Text(
              l10n.wlAlarmCurrentPrice(
                '${price.toStringAsFixed(price < 10 ? 3 : 2)} $currency'),
              style: TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(150)),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _slCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.wlAlarmStopLoss,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.trending_down, color: Colors.red),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tpCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.wlAlarmTarget,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.trending_up, color: Colors.green),
            ),
          ),
        ],
      ),
      actions: [
        if (hasAlarm)
          TextButton(
            onPressed: _saving ? null : () => _save(null, null),
            child: Text(l10n.wlAlarmClear,
                style: TextStyle(color: cs.error)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.wlAlarmCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : () {
            final sl = double.tryParse(_slCtrl.text.replaceAll(',', '.'));
            final tp = double.tryParse(_tpCtrl.text.replaceAll(',', '.'));
            _save(sl, tp);
          },
          child: _saving
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(l10n.wlAlarmSave),
        ),
      ],
    );
  }
}
