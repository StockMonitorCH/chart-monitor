import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/company_info.dart';
import '../models/news_item.dart';
import '../services/yahoo_finance_service.dart';
import '../utils/gics_mapper.dart';
import '../l10n/app_localizations.dart';

class StockDetailsSheet extends StatefulWidget {
  final String symbol;
  final String name;

  const StockDetailsSheet({super.key, required this.symbol, required this.name});

  static void show(BuildContext context, String symbol, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StockDetailsSheet(symbol: symbol, name: name),
    );
  }

  @override
  State<StockDetailsSheet> createState() => _StockDetailsSheetState();
}

class _StockDetailsSheetState extends State<StockDetailsSheet> {
  final _service = YahooFinanceService();
  CompanyInfo? _info;
  List<NewsItem> _news = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.fetchCompanyInfo(widget.symbol),
        _service.fetchNews(widget.symbol),
      ]);
      if (mounted) {
        setState(() {
          _info = results[0] as CompanyInfo;
          _news = results[1] as List<NewsItem>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.97,
      maxChildSize: 0.97,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          _Handle(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.symbol} – ${widget.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(height: 8),
                            Text(l10n.errorLoading),
                            TextButton(onPressed: _load, child: Text(l10n.retry)),
                          ],
                        ),
                      )
                    : _buildContent(l10n, scrollController),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n, ScrollController sc) {
    final info = _info!;
    final locale = Localizations.localeOf(context).toString();
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return ListView(
      controller: sc,
      padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomPad),
      children: [
        // ── ETF / Fonds: Zusammensetzung ─────────────────────────────────────
        if (info.isEtf) ...[
          _SectionTitle(l10n.detailsComposition, url: info.website),
          if (info.topHoldings.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l10n.noData,
                  style: TextStyle(fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(120))),
            )
          else ...[
            const SizedBox(height: 4),
            ...info.topHoldings.take(10).map((h) =>
                _HoldingRow(holding: h, maxPercent: info.topHoldings.first.percent)),
          ],
          if (info.sectorWeightings.isNotEmpty) ...[
            _SectionTitle(l10n.detailsSectorWeights),
            const SizedBox(height: 4),
            ...info.sectorWeightings.take(8).map((s) =>
                _SectorWeightRow(weight: s, maxPercent: info.sectorWeightings.first.percent)),
            const SizedBox(height: 8),
          ],
        ] else ...[
          // ── Aktie: Unternehmensinfo ────────────────────────────────────────
          _SectionTitle(l10n.detailsCompanyInfo, url: info.website),
          _InfoGrid(
            noDataLabel: l10n.noData,
            cells: [
              if (info.sector != null) _InfoCell(l10n.detailsSector, GicsMapper.sector(info.sector)),
              if (info.industry != null) _InfoCell(l10n.detailsIndustry, GicsMapper.industry(info.industry)),
              if (info.country != null) _InfoCell(l10n.detailsCountry, info.country!),
              if (info.ceo != null) _InfoCell(l10n.detailsCEO, info.ceo!),
              if (info.employees != null)
                _InfoCell(
                  l10n.detailsEmployees,
                  NumberFormat.compact(locale: 'en_US').format(info.employees),
                ),
              if (info.marketCap != null)
                _InfoCell(
                  l10n.detailsMarketCap,
                  '${_formatLarge(info.marketCap!, locale)} ${info.currency}',
                ),
            ],
          ),
        ],

        // Valuation
        _SectionTitle(l10n.detailsValuation),
        _InfoGrid(
          noDataLabel: l10n.noData,
          cells: [
            if (info.peRatio != null)
              _InfoCell(locale.startsWith('de') ? 'KGV' : 'P/E', info.peRatio!.toStringAsFixed(2)),
            if (info.eps != null)
              _InfoCell('EPS', info.eps!.toStringAsFixed(2)),
            if (info.beta != null)
              _InfoCell('Beta', info.beta!.toStringAsFixed(2)),
            if (info.fiftyTwoWeekHigh != null)
              _InfoCell(l10n.details52wHigh, info.fiftyTwoWeekHigh!.toStringAsFixed(2)),
            if (info.fiftyTwoWeekLow != null)
              _InfoCell(l10n.details52wLow, info.fiftyTwoWeekLow!.toStringAsFixed(2)),
            if (info.nextEarningsDate != null)
              _InfoCell(l10n.detailsNextEarnings, info.nextEarningsDate!),
          ],
        ),

        // Dividends
        if (info.dividendRate != null || info.dividendYield != null || info.dividendHistory.isNotEmpty) ...[
          _SectionTitle(l10n.detailsDividends),
          if (info.dividendRate != null || info.dividendYield != null || info.exDividendDate != null)
            _InfoGrid(cells: [
              if (info.dividendRate != null)
                _InfoCell(
                  l10n.detailsDivRate,
                  '${info.dividendRate!.toStringAsFixed(2)} ${info.currency}',
                ),
              if (info.dividendYield != null)
                _InfoCell(
                  l10n.detailsDivYield,
                  '${(info.dividendYield! * 100).toStringAsFixed(2)}%',
                ),
              if (info.exDividendDate != null)
                _InfoCell(l10n.detailsExDivDate, info.exDividendDate!),
            ]),
          if (info.dividendHistory.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.detailsDivHistory,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: _DividendChart(history: info.dividendHistory, currency: info.currency),
            ),
          ],
        ],

        // Description
        if (info.description != null && info.description!.isNotEmpty) ...[
          _SectionTitle(l10n.detailsDescription),
          Text(info.description!, style: const TextStyle(fontSize: 13)),
        ],

        // News
        _SectionTitle(l10n.detailsNews),
        if (_news.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(l10n.newsNone,
                style: TextStyle(fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(120))),
          )
        else
          ..._news.map((n) => _NewsRow(item: n)),

        // Debug info (temporary – shown only when company data is unavailable)
        if (info.debugInfo != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withAlpha(100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('API Debug', style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 11, color: Colors.orange)),
                const SizedBox(height: 4),
                Text(info.debugInfo!,
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
              ],
            ),
          ),
        ],

      ],
    );
  }

  String _formatLarge(double value, String locale) {
    final de = locale.startsWith('de');
    if (value >= 1e12) {
      return '${(value / 1e12).toStringAsFixed(2)} ${de ? 'Bio.' : 'T'}';
    }
    if (value >= 1e9) {
      return '${(value / 1e9).toStringAsFixed(2)} ${de ? 'Mrd.' : 'B'}';
    }
    if (value >= 1e6) {
      return '${(value / 1e6).toStringAsFixed(2)} ${de ? 'Mio.' : 'M'}';
    }
    return NumberFormat.compact(locale: 'en_US').format(value);
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? url;
  const _SectionTitle(this.title, {this.url});

  String _displayUrl(String raw) {
    var s = raw;
    if (s.startsWith('https://')) s = s.substring(8);
    if (s.startsWith('http://')) s = s.substring(7);
    if (s.startsWith('www.')) s = s.substring(4);
    if (s.endsWith('/')) s = s.substring(0, s.length - 1);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: style),
          if (url != null) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () => launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.language, size: 14, color: cs.primary.withAlpha(200)),
                    const SizedBox(width: 5),
                    Text(
                      _displayUrl(url!),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: cs.primary.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCell {
  final String label;
  final String value;
  const _InfoCell(this.label, this.value);
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoCell> cells;
  final String? noDataLabel;
  const _InfoGrid({required this.cells, this.noDataLabel});

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          noDataLabel ?? '–',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
          ),
        ),
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: cells.map((c) => _Chip(c)).toList(),
    );
  }
}

class _Chip extends StatelessWidget {
  final _InfoCell cell;
  const _Chip(this.cell);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(cell.label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
              )),
          const SizedBox(height: 2),
          Text(cell.value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _DividendChart extends StatelessWidget {
  final List<DividendEntry> history;
  final String currency;

  const _DividendChart({required this.history, required this.currency});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final lang = Localizations.localeOf(context).languageCode;
    final forecastLabel = lang == 'de' ? 'Prognose' : 'Forecast';

    final now = DateTime.now();
    final currentYear = now.year;
    final nextYear = currentYear + 1;

    // Aggregate dividends by year
    final Map<int, double> byYear = {};
    for (final d in history) {
      byYear[d.date.year] = (byYear[d.date.year] ?? 0) + d.amount;
    }
    if (byYear.isEmpty) return const SizedBox.shrink();

    final actualYears = byYear.keys.toList()..sort();

    // Last complete year as forecast basis
    final completeYears = actualYears.where((y) => y < currentYear).toList();
    final lastCompleteYear = completeYears.isNotEmpty ? completeYears.last : null;
    final forecastAmount = lastCompleteYear != null ? byYear[lastCompleteYear]! : null;

    // Projected remainder for current year
    final currentActual = byYear[currentYear] ?? 0.0;
    double projectedRemainder = 0;
    if (currentActual > 0) {
      final dayOfYear =
          now.difference(DateTime(currentYear)).inDays.clamp(1, 364);
      final fraction = dayOfYear / 365.0;
      final annualized = currentActual / fraction;
      projectedRemainder = annualized - currentActual;
      if (forecastAmount != null) {
        final cap = (forecastAmount - currentActual).clamp(0.0, double.infinity);
        projectedRemainder = cap;
      }
    }

    // Build display list: actual years + optional forecast year
    final displayYears = [...actualYears];
    if (forecastAmount != null && forecastAmount > 0) {
      displayYears.add(nextYear);
    }

    // Max Y for axis
    final allAmounts = [
      ...byYear.values,
      ?forecastAmount,
      if (projectedRemainder > 0) currentActual + projectedRemainder,
    ];
    final maxAmount = allAmounts.reduce((a, b) => a > b ? a : b);
    final maxY = maxAmount * 1.25;
    final yInterval = _niceInterval(maxY / 4);

    // Build bars
    final bars = displayYears.asMap().entries.map((e) {
      final idx = e.key;
      final year = e.value;

      if (year == nextYear && forecastAmount != null) {
        // Forecast bar: lighter fill + border
        return BarChartGroupData(
          x: idx,
          barRods: [
            BarChartRodData(
              toY: forecastAmount,
              width: 14,
              color: primary.withAlpha(50),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              borderSide: BorderSide(color: primary.withAlpha(150), width: 1.5),
            ),
          ],
        );
      }

      final actual = byYear[year]!;
      if (year == currentYear && projectedRemainder > 0.001) {
        // Stacked: paid (solid) + projected remainder (lighter)
        final total = actual + projectedRemainder;
        return BarChartGroupData(
          x: idx,
          barRods: [
            BarChartRodData(
              toY: total,
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
              rodStackItems: [
                BarChartRodStackItem(0, actual, primary),
                BarChartRodStackItem(actual, total, primary.withAlpha(80)),
              ],
            ),
          ],
        );
      }

      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: actual,
            color: primary,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: bars,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= displayYears.length) {
                  return const SizedBox.shrink();
                }
                final year = displayYears[idx];
                final isForecast = year == nextYear;
                return Text(
                  isForecast ? '$year*' : '$year',
                  style: TextStyle(
                    fontSize: 9,
                    fontStyle:
                        isForecast ? FontStyle.italic : FontStyle.normal,
                    color: onSurface.withAlpha(isForecast ? 120 : 160),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value > maxY) return const SizedBox.shrink();
                return Text(
                  value.toStringAsFixed(value < 1 ? 2 : 1),
                  style: TextStyle(fontSize: 9, color: onSurface.withAlpha(160)),
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
          getDrawingHorizontalLine: (_) => FlLine(
            color: Theme.of(context).dividerColor.withAlpha(60),
            strokeWidth: 0.8,
          ),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              final idx = group.x;
              if (idx < 0 || idx >= displayYears.length) return null;
              final year = displayYears[idx];
              if (year == nextYear) {
                return BarTooltipItem(
                  '$year*\n${rod.toY.toStringAsFixed(2)} $currency\n($forecastLabel)',
                  const TextStyle(
                      fontSize: 11, fontStyle: FontStyle.italic),
                );
              }
              if (year == currentYear && projectedRemainder > 0.001) {
                return BarTooltipItem(
                  '$year\n${rod.toY.toStringAsFixed(2)} $currency'
                  '\n(${byYear[year]!.toStringAsFixed(2)} + $forecastLabel)',
                  const TextStyle(fontSize: 11),
                );
              }
              return BarTooltipItem(
                '$year\n${rod.toY.toStringAsFixed(2)} $currency',
                const TextStyle(fontSize: 11),
              );
            },
          ),
        ),
      ),
    );
  }

  double _niceInterval(double raw) {
    if (raw <= 0) return 1;
    if (raw < 0.05) return 0.02;
    if (raw < 0.15) return 0.05;
    if (raw < 0.3) return 0.1;
    if (raw < 0.6) return 0.25;
    if (raw < 1.2) return 0.5;
    if (raw < 3) return 1;
    if (raw < 6) return 2;
    if (raw < 15) return 5;
    if (raw < 30) return 10;
    if (raw < 60) return 25;
    return (raw / 10).ceilToDouble() * 10;
  }
}

// ── ETF Holdings ─────────────────────────────────────────────────────────────

class _HoldingRow extends StatelessWidget {
  final EtfHolding holding;
  final double maxPercent;
  const _HoldingRow({required this.holding, required this.maxPercent});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final barFraction = maxPercent > 0 ? (holding.percent / maxPercent).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(holding.name,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (holding.symbol.isNotEmpty)
                  Text(holding.symbol,
                      style: TextStyle(fontSize: 10, color: cs.onSurface.withAlpha(120))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${(holding.percent * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: barFraction,
                    backgroundColor: cs.surfaceContainerHighest,
                    color: cs.primary,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsRow extends StatelessWidget {
  final NewsItem item;
  const _NewsRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lang = Localizations.localeOf(context).languageCode;
    final fmt = lang == 'de' ? DateFormat('dd.MM.yy HH:mm') : DateFormat('MM/dd/yy HH:mm');

    return InkWell(
      onTap: () {
        if (item.link.isNotEmpty) {
          launchUrl(Uri.parse(item.link), mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    '${item.publisher}  ·  ${fmt.format(item.publishedAt)}',
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withAlpha(130)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.open_in_new, size: 14, color: cs.onSurface.withAlpha(100)),
          ],
        ),
      ),
    );
  }
}

class _SectorWeightRow extends StatelessWidget {
  final EtfSectorWeight weight;
  final double maxPercent;
  const _SectorWeightRow({required this.weight, required this.maxPercent});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final barFraction = maxPercent > 0 ? (weight.percent / maxPercent).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(GicsMapper.etfSector(weight.sector),
                style: const TextStyle(fontSize: 12),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${(weight.percent * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 11, color: cs.onSurface.withAlpha(180))),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: barFraction,
                    backgroundColor: cs.surfaceContainerHighest,
                    color: cs.secondary,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
