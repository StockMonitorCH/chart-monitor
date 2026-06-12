import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/chart_state.dart';
import '../models/stock_data.dart';
import '../widgets/candlestick_chart.dart';
import '../widgets/fx_calc_sheet.dart';
import '../widgets/info_dialog.dart';
import '../widgets/search_field.dart';
import '../widgets/stock_chart.dart';
import '../widgets/stock_details_sheet.dart';
import '../widgets/watchlist_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<ChartState>();
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart Monitor  v1.0.3',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: l10n.watchlistTitle,
            onPressed: () => WatchlistSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: l10n.fxCalcTitle,
            onPressed: () => FxCalcSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: l10n.infoTitle,
            onPressed: () => InfoDialog.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: isLandscape
            ? _LandscapeLayout(state: state, l10n: l10n)
            : _PortraitLayout(state: state, l10n: l10n),
      ),
    );
  }
}

// ── Portrait ──────────────────────────────────────────────────────────────────

class _PortraitLayout extends StatelessWidget {
  final ChartState state;
  final AppLocalizations l10n;
  const _PortraitLayout({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SearchRow(state: state, l10n: l10n),
        _PriceRow(state: state, l10n: l10n),
        _TimeRangeBar(state: state, l10n: l10n),
        if (state.hasStock1 && !state.hasStock2 && !state.selectedRange.isIntraday)
          _IndicatorBar(state: state, l10n: l10n),
        Expanded(child: _ChartArea(state: state, l10n: l10n)),
      ],
    );
  }
}

// ── Landscape ─────────────────────────────────────────────────────────────────

class _LandscapeLayout extends StatelessWidget {
  final ChartState state;
  final AppLocalizations l10n;
  const _LandscapeLayout({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 220,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: Column(
                    children: [
                      _SearchRow(state: state, l10n: l10n, compact: true),
                      _PriceRow(state: state, l10n: l10n, compact: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              _TimeRangeBar(state: state, l10n: l10n),
              if (state.hasStock1 && !state.hasStock2 && !state.selectedRange.isIntraday)
                _IndicatorBar(state: state, l10n: l10n),
              Expanded(child: _ChartArea(state: state, l10n: l10n)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SearchRow extends StatelessWidget {
  final ChartState state;
  final AppLocalizations l10n;
  final bool compact;
  const _SearchRow(
      {required this.state, required this.l10n, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const secondary = Colors.orange;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, compact ? 4 : 8, 12, 4),
      child: Column(
        children: [
          SearchField(
            label: l10n.stock1Label,
            accentColor: primary,
            currentSymbol: state.stock1Info?.symbol,
            onSelected: (r) => context.read<ChartState>().loadStock1(r.symbol),
            onClear: state.hasStock1
                ? () => context.read<ChartState>().clearStock1()
                : null,
          ),
          const SizedBox(height: 6),
          if (state.hasStock1)
            SearchField(
              label: l10n.stock2Label,
              accentColor: secondary,
              currentSymbol: state.stock2Info?.symbol,
              onSelected: (r) =>
                  context.read<ChartState>().loadStock2(r.symbol),
              onClear: () => context.read<ChartState>().removeStock2(),
            ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final ChartState state;
  final AppLocalizations l10n;
  final bool compact;
  const _PriceRow({required this.state, required this.l10n, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (!state.hasStock1) return const SizedBox.shrink();
    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 2 : 4),
      child: Column(
        children: [
          if (state.stock1Info != null)
            _PriceChip(
              info: state.stock1Info!,
              color: Theme.of(context).colorScheme.primary,
              loading: state.loadingStock1,
              compact: compact,
              periodChangePct: state.stock1PeriodChangePercent,
              periodChangeAbs: state.stock1PeriodChangeAbsolute,
              isOneDay: state.selectedRange == TimeRange.oneDay,
              inWatchlist: state.isInWatchlist(state.stock1Info!.symbol),
              l10n: l10n,
            ),
          if (state.stock2Info != null) ...[
            const SizedBox(height: 6),
            _PriceChip(
              info: state.stock2Info!,
              color: Colors.orange,
              loading: state.loadingStock2,
              compact: compact,
              periodChangePct: state.stock2PeriodChangePercent,
              periodChangeAbs: state.stock2PeriodChangeAbsolute,
              isOneDay: state.selectedRange == TimeRange.oneDay,
              inWatchlist: state.isInWatchlist(state.stock2Info!.symbol),
              l10n: l10n,
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final StockInfo info;
  final Color color;
  final bool loading;
  final bool compact;
  final double? periodChangePct;
  final double? periodChangeAbs;
  final bool isOneDay;
  final bool inWatchlist;
  final AppLocalizations l10n;

  const _PriceChip({
    required this.info,
    required this.color,
    required this.loading,
    required this.l10n,
    this.compact = false,
    this.periodChangePct,
    this.periodChangeAbs,
    this.isOneDay = true,
    this.inWatchlist = false,
  });

  @override
  Widget build(BuildContext context) {
    const stockLocale = 'en_US';
    final priceFmt = NumberFormat.decimalPatternDigits(
      locale: stockLocale,
      decimalDigits: info.currentPrice < 10 ? 3 : 2,
    );

    final showPeriodPerf = !isOneDay && periodChangePct != null;
    final pct = showPeriodPerf ? periodChangePct! : info.changePercent;
    final abs = showPeriodPerf ? (periodChangeAbs ?? 0.0) : null;
    final up = pct >= 0;
    final changeColor = up ? Colors.green : Colors.red;

    final absFmt = abs == null
        ? null
        : NumberFormat.decimalPatternDigits(
            locale: stockLocale,
            decimalDigits: info.currentPrice < 10 ? 3 : 2,
          );

    final pctStr = '${up ? '+' : ''}${pct.toStringAsFixed(2)}%';
    final absStr = abs == null
        ? null
        : '${up ? '+' : ''}${absFmt!.format(abs)} ${info.currency}';

    // Pre/post market
    final hasPreMarket = info.preMarketPrice != null;
    final hasPostMarket = info.postMarketPrice != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(80)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: loading
          ? const SizedBox(
              height: 32,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(info.symbol,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: compact ? 11 : 12,
                                      color: color)),
                              if (info.name.isNotEmpty && info.name != info.symbol)
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 160),
                                  child: Text(
                                    info.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: compact ? 9 : 10,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withAlpha(140),
                                    ),
                                  ),
                                ),
                              Text(
                                '${priceFmt.format(info.currentPrice)} ${info.currency}',
                                style: TextStyle(
                                    fontSize: compact ? 13 : 15,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(pctStr,
                                  style: TextStyle(
                                      fontSize: compact ? 12 : 13,
                                      fontWeight: FontWeight.w600,
                                      color: changeColor)),
                              if (absStr != null)
                                Text(absStr,
                                    style: TextStyle(
                                        fontSize: compact ? 11 : 12,
                                        color: changeColor)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        inWatchlist ? Icons.bookmark : Icons.bookmark_border,
                        size: 18,
                        color: inWatchlist ? color : color.withAlpha(160),
                      ),
                      tooltip: l10n.watchlistTitle,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => context.read<ChartState>().toggleWatchlist(info.symbol, info.name),
                    ),
                    IconButton(
                      icon: Icon(Icons.business_outlined, size: 18, color: color),
                      tooltip: l10n.detailsTitle,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () =>
                          StockDetailsSheet.show(context, info.symbol, info.name),
                    ),
                  ],
                ),
                // Pre/post market row
                if (hasPreMarket || hasPostMarket)
                  _ExtMarketRow(
                    label: hasPreMarket ? l10n.preMarket : l10n.postMarket,
                    price: hasPreMarket ? info.preMarketPrice! : info.postMarketPrice!,
                    changePct: hasPreMarket ? info.preMarketChangePct : info.postMarketChangePct,
                    currency: info.currency,
                    priceFmt: priceFmt,
                  ),
              ],
            ),
    );
  }
}

class _ExtMarketRow extends StatelessWidget {
  final String label;
  final double price;
  final double? changePct;
  final String currency;
  final NumberFormat priceFmt;

  const _ExtMarketRow({
    required this.label,
    required this.price,
    required this.changePct,
    required this.currency,
    required this.priceFmt,
  });

  @override
  Widget build(BuildContext context) {
    final pct = changePct ?? 0.0;
    final up = pct >= 0;
    final c = up ? Colors.green : Colors.red;
    final pctStr = '${up ? '+' : ''}${pct.toStringAsFixed(2)}%';
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '$label: ${priceFmt.format(price)} $currency  $pctStr',
        style: TextStyle(fontSize: 11, color: c),
      ),
    );
  }
}

// ── Time range bar ────────────────────────────────────────────────────────────

class _TimeRangeBar extends StatelessWidget {
  final ChartState state;
  final AppLocalizations l10n;
  const _TimeRangeBar({required this.state, required this.l10n});

  // Main visible buttons: 1T 1W 1M 3M 6M YTD 1J
  static const _mainRanges = [
    TimeRange.oneDay,
    TimeRange.oneWeek,
    TimeRange.oneMonth,
    TimeRange.threeMonths,
    TimeRange.sixMonths,
    TimeRange.ytd,
    TimeRange.oneYear,
  ];

  // Hidden in "Mehr" dropdown: 2J 5J Max Individuell
  static const _extendedRanges = [
    TimeRange.twoYears,
    TimeRange.fiveYears,
    TimeRange.max,
    TimeRange.custom,
  ];

  bool get _extendedSelected =>
      _extendedRanges.contains(state.selectedRange);

  String _mainLabel(TimeRange r) {
    switch (r) {
      case TimeRange.oneDay: return l10n.timeRange1D;
      case TimeRange.oneWeek: return l10n.timeRange1W;
      case TimeRange.oneMonth: return l10n.timeRange1M;
      case TimeRange.threeMonths: return l10n.timeRange3M;
      case TimeRange.sixMonths: return l10n.timeRange6M;
      case TimeRange.ytd: return l10n.timeRangeYtd;
      case TimeRange.oneYear: return l10n.timeRange1Y;
      default: return '';
    }
  }

  String _extLabel(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    switch (state.selectedRange) {
      case TimeRange.twoYears: return l10n.timeRange2Y;
      case TimeRange.fiveYears: return l10n.timeRange5Y;
      case TimeRange.max: return l10n.timeRangeMax;
      case TimeRange.custom:
        final lbl = state.customRangeLabel(locale);
        return lbl.isNotEmpty ? lbl : l10n.timeRangeCustom;
      default: return l10n.timeRangeMore;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCandle = state.canUseCandlestick;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._mainRanges.map((r) => _RangeButton(
                        label: _mainLabel(r),
                        selected: state.selectedRange == r,
                        onTap: () => context.read<ChartState>().changeRange(r),
                      )),
                  _MoreButton(
                    label: _extLabel(context),
                    selected: _extendedSelected,
                    state: state,
                    l10n: l10n,
                  ),
                ],
              ),
            ),
          ),
          // Candlestick toggle
          if (canCandle || state.candlestick)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => context.read<ChartState>().toggleCandlestick(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: state.candlestick
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.candlestick_chart_outlined,
                    size: 18,
                    color: state.candlestick
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface.withAlpha(160),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RangeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RangeButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface.withAlpha(180),
          ),
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final String label;
  final bool selected;
  final ChartState state;
  final AppLocalizations l10n;

  const _MoreButton({
    required this.label,
    required this.selected,
    required this.state,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTapDown: (details) => _showMenu(context, details.globalPosition),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface.withAlpha(180),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 14,
              color: selected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface.withAlpha(180),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context, Offset tapPosition) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final relPos = RelativeRect.fromRect(
      Rect.fromPoints(tapPosition, tapPosition),
      Offset.zero & overlay.size,
    );

    final result = await showMenu<String>(
      context: context,
      position: relPos,
      items: [
        PopupMenuItem(
          value: '2y',
          child: _MenuItem(
            label: l10n.timeRange2Y,
            selected: state.selectedRange == TimeRange.twoYears,
          ),
        ),
        PopupMenuItem(
          value: '5y',
          child: _MenuItem(
            label: l10n.timeRange5Y,
            selected: state.selectedRange == TimeRange.fiveYears,
          ),
        ),
        PopupMenuItem(
          value: 'max',
          child: _MenuItem(
            label: l10n.timeRangeMax,
            selected: state.selectedRange == TimeRange.max,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'custom',
          child: _MenuItem(
            label: l10n.timeRangeCustom,
            selected: state.selectedRange == TimeRange.custom,
            icon: Icons.date_range,
          ),
        ),
      ],
    );

    if (!context.mounted) return;

    switch (result) {
      case '2y':
        context.read<ChartState>().changeRange(TimeRange.twoYears);
      case '5y':
        context.read<ChartState>().changeRange(TimeRange.fiveYears);
      case 'max':
        context.read<ChartState>().changeRange(TimeRange.max);
      case 'custom':
        await _pickCustomRange(context);
    }
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: state.customStart ?? now.subtract(const Duration(days: 90)),
        end: state.customEnd ?? now,
      ),
      helpText: l10n.customRangeTitle,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx),
        child: child!,
      ),
    );
    if (picked != null && context.mounted) {
      context.read<ChartState>().changeRange(
            TimeRange.custom,
            start: picked.start,
            end: picked.end,
          );
    }
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  const _MenuItem({required this.label, this.selected = false, this.icon});

  @override
  Widget build(BuildContext context) {
    final color = selected ? Theme.of(context).colorScheme.primary : null;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
        ],
        Text(label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: color,
            )),
        if (selected) ...[
          const SizedBox(width: 6),
          Icon(Icons.check, size: 14,
              color: Theme.of(context).colorScheme.primary),
        ],
      ],
    );
  }
}

// ── Indicator bar (MA, Trend, Ziel) ──────────────────────────────────────────

class _IndicatorBar extends StatelessWidget {
  final ChartState state;
  final AppLocalizations l10n;
  const _IndicatorBar({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final len = state.maDataLength;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _IndicatorChip(
              label: 'MA20',
              active: state.showMa20,
              enabled: len >= 20,
              color: Colors.cyan.shade400,
              onTap: () => context.read<ChartState>().toggleMa20(),
            ),
            const SizedBox(width: 4),
            _IndicatorChip(
              label: 'MA50',
              active: state.showMa50,
              enabled: len >= 50,
              color: Colors.orange.shade400,
              onTap: () => context.read<ChartState>().toggleMa50(),
            ),
            const SizedBox(width: 4),
            _IndicatorChip(
              label: 'MA200',
              active: state.showMa200,
              enabled: len >= 200,
              color: Colors.purple.shade400,
              onTap: () => context.read<ChartState>().toggleMa200(),
            ),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 16,
              color: Theme.of(context).dividerColor,
            ),
            const SizedBox(width: 8),
            _IndicatorChip(
              label: l10n.indicatorTrend,
              active: state.showTrendLine,
              enabled: state.stock1Data.length >= 2,
              color: Colors.amber.shade400,
              onTap: () => context.read<ChartState>().toggleTrendLine(),
            ),
            const SizedBox(width: 4),
            _IndicatorChip(
              label: l10n.indicatorTarget,
              active: state.showTargetLine,
              enabled: state.analystTargetPrice != null,
              color: Colors.green.shade400,
              onTap: () => context.read<ChartState>().toggleTargetLine(),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicatorChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  const _IndicatorChip({
    required this.label,
    required this.active,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : color.withAlpha(70);
    final isOn = active && enabled;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isOn ? effectiveColor.withAlpha(40) : Colors.transparent,
          border: Border.all(
            color: isOn ? effectiveColor : effectiveColor.withAlpha(100),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isOn ? FontWeight.bold : FontWeight.normal,
            color: isOn ? effectiveColor : effectiveColor.withAlpha(160),
          ),
        ),
      ),
    );
  }
}

// ── Chart area ────────────────────────────────────────────────────────────────

class _ChartArea extends StatelessWidget {
  final ChartState state;
  final AppLocalizations l10n;
  const _ChartArea({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    if (!state.hasStock1) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withAlpha(100)),
            const SizedBox(height: 12),
            Text(l10n.searchLabel,
                style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(120))),
          ],
        ),
      );
    }

    if (state.errorStock1 != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.red),
            const SizedBox(height: 8),
            Text(l10n.errorLoading),
            TextButton(
              onPressed: () => context
                  .read<ChartState>()
                  .loadStock1(state.stock1Info!.symbol),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (state.loadingStock1 && state.stock1Data.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l10n.loadingData),
          ],
        ),
      );
    }

    final ind = state.hasStock2 ? ChartIndicators.none : state.indicators;

    if (state.candlestick && state.canUseCandlestick) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
        child: CandlestickChartWidget(
          data: state.stock1Data,
          maWarmupData: state.stock1MaData,
          range: state.selectedRange,
          indicators: ind,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 8),
      child: StockChart(
        data1: state.stock1Data,
        maWarmupData: state.stock1MaData,
        data2: state.stock2Data,
        label1: state.stock1Info?.symbol,
        label2: state.stock2Info?.symbol,
        range: state.selectedRange,
        indicators: ind,
      ),
    );
  }
}
