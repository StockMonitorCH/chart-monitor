import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_data.dart';

class StockChart extends StatelessWidget {
  final List<ChartDataPoint> data1;
  final List<ChartDataPoint> data2;
  final List<ChartDataPoint> maWarmupData;
  final String? label1;
  final String? label2;
  final TimeRange range;
  final ChartIndicators indicators;

  const StockChart({
    super.key,
    required this.data1,
    this.data2 = const [],
    this.maWarmupData = const [],
    this.label1,
    this.label2,
    required this.range,
    this.indicators = ChartIndicators.none,
  });

  @override
  Widget build(BuildContext context) {
    if (data1.isEmpty) return const SizedBox.shrink();

    final isSingle = data2.isEmpty;
    final normalize = !isSingle;
    final base1 = data1.first.close;
    final base2 = data2.isNotEmpty ? data2.first.close : 1.0;

    final isUp = data1.last.close >= data1.first.close;
    final color1 = isSingle
        ? (isUp ? Colors.green.shade400 : Colors.red.shade400)
        : Theme.of(context).colorScheme.primary;
    const color2 = Colors.orange;

    // When comparing two stocks the X range is anchored to data1 length.
    // data2 is stretched/compressed proportionally so both lines always span
    // the full chart width regardless of how many data points each stock has
    // (different exchanges have different trading hours → different counts).
    List<FlSpot> toSpots(List<ChartDataPoint> pts, double base, {double? forceMaxX}) {
      if (pts.isEmpty) return [];
      final maxX = forceMaxX ?? (pts.length - 1).toDouble();
      if (pts.length == 1) {
        return [FlSpot(0, normalize ? 0.0 : pts.first.close)];
      }
      return pts.asMap().entries.map((e) {
        final x = (e.key / (pts.length - 1)) * maxX;
        final y = normalize ? ((e.value.close / base) - 1) * 100 : e.value.close;
        return FlSpot(x, y);
      }).toList();
    }

    final refMaxX = (data1.length - 1).toDouble();
    final spots1 = toSpots(data1, base1);
    final spots2 = data2.isNotEmpty
        ? toSpots(data2, base2, forceMaxX: refMaxX)
        : <FlSpot>[];

    final combinedMaData = _buildMaData(data1, maWarmupData);
    final visibleStart = combinedMaData.length - data1.length;

    final ma20Spots = (isSingle && indicators.showMa20)
        ? _calcMA(combinedMaData, 20, visibleStart)
        : <FlSpot>[];
    final ma50Spots = (isSingle && indicators.showMa50)
        ? _calcMA(combinedMaData, 50, visibleStart)
        : <FlSpot>[];
    final ma200Spots = (isSingle && indicators.showMa200)
        ? _calcMA(combinedMaData, 200, visibleStart)
        : <FlSpot>[];

    final trendSpots = (isSingle && indicators.showTrendLine)
        ? _calcTrendLine(spots1)
        : <FlSpot>[];

    final targetPrice = (isSingle && indicators.showTargetLine && indicators.analystTarget != null)
        ? indicators.analystTarget!
        : null;
    final targetSpots = targetPrice != null
        ? [FlSpot(0, targetPrice), FlSpot((data1.length - 1).toDouble(), targetPrice)]
        : <FlSpot>[];

    // Bollinger Bands (only single stock, absolute prices)
    final bbResult = (isSingle && indicators.showBollinger && !normalize && data1.length >= 20)
        ? _calcBollinger(data1, 20, 2.0)
        : (upper: <FlSpot>[], lower: <FlSpot>[]);
    final bbUpperSpots = bbResult.upper;
    final bbLowerSpots = bbResult.lower;

    final allY = [
      ...spots1.map((s) => s.y),
      ...spots2.map((s) => s.y),
      ...ma20Spots.map((s) => s.y),
      ...ma50Spots.map((s) => s.y),
      ...ma200Spots.map((s) => s.y),
      ...trendSpots.map((s) => s.y),
      ...bbUpperSpots.map((s) => s.y),
      ...bbLowerSpots.map((s) => s.y),
      ?targetPrice,
    ];
    final minY = allY.reduce((a, b) => a < b ? a : b);
    final maxY = allY.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1 + 0.01;

    final bbColor = Colors.purple.shade300;

    final lineBars = [
      LineChartBarData(
        spots: spots1,
        isCurved: true,
        color: color1,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: isSingle
            ? BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [color1.withAlpha(50), color1.withAlpha(0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              )
            : BarAreaData(show: false),
      ),
      if (spots2.isNotEmpty)
        LineChartBarData(
          spots: spots2,
          isCurved: true,
          color: color2,
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
      if (bbUpperSpots.isNotEmpty)
        LineChartBarData(
          spots: bbUpperSpots,
          isCurved: false,
          color: bbColor,
          barWidth: 1,
          dashArray: [5, 3],
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      if (bbLowerSpots.isNotEmpty)
        LineChartBarData(
          spots: bbLowerSpots,
          isCurved: false,
          color: bbColor,
          barWidth: 1,
          dashArray: [5, 3],
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: bbUpperSpots.isNotEmpty,
            color: bbColor.withAlpha(25),
            // fills between lower and upper by spotsLine referencing bar index 2 (upper)
            applyCutOffY: false,
            spotsLine: BarAreaSpotsLine(show: false),
          ),
          aboveBarData: BarAreaData(
            show: bbUpperSpots.isNotEmpty,
            color: bbColor.withAlpha(25),
            cutOffY: bbUpperSpots.isNotEmpty ? bbUpperSpots.first.y : 0,
            applyCutOffY: false,
          ),
        ),
      if (ma20Spots.isNotEmpty)
        LineChartBarData(
          spots: ma20Spots,
          isCurved: false,
          color: Colors.cyan.shade400,
          barWidth: 1.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      if (ma50Spots.isNotEmpty)
        LineChartBarData(
          spots: ma50Spots,
          isCurved: false,
          color: Colors.orange.shade400,
          barWidth: 1.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      if (ma200Spots.isNotEmpty)
        LineChartBarData(
          spots: ma200Spots,
          isCurved: false,
          color: Colors.purple.shade400,
          barWidth: 1.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      if (trendSpots.isNotEmpty)
        LineChartBarData(
          spots: trendSpots,
          isCurved: false,
          color: Colors.amber.shade400,
          barWidth: 1.5,
          dashArray: [8, 4],
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      if (targetSpots.isNotEmpty)
        LineChartBarData(
          spots: targetSpots,
          isCurved: false,
          color: Colors.green.shade600,
          barWidth: 1.5,
          dashArray: [6, 4],
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
    ];

    // Fewer labels for intraday (narrow time slots)
    final labelCount = range.isIntraday ? 3 : 4;
    final labelIndices = _labelPositions(data1.length, labelCount);

    return Column(
      children: [
        if (normalize && (label1 != null || label2 != null))
          _Legend(label1: label1, label2: label2, color1: color1, color2: color2),
        if (isSingle && _hasAnyIndicator())
          _IndicatorLegend(
            showMa20: ma20Spots.isNotEmpty,
            showMa50: ma50Spots.isNotEmpty,
            showMa200: ma200Spots.isNotEmpty,
            showTrend: trendSpots.isNotEmpty,
            showTarget: targetSpots.isNotEmpty,
            showBollinger: bbUpperSpots.isNotEmpty,
            targetPrice: targetPrice,
          ),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: minY - padding,
              maxY: maxY + padding,
              lineBarsData: lineBars,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: normalize ? 56 : 64,
                    getTitlesWidget: (value, meta) {
                      // Skip boundary values to prevent overlap at top/bottom
                      if (value == meta.min || value == meta.max) {
                        return const SizedBox.shrink();
                      }
                      return _leftTitle(value, normalize, context);
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 1,
                    getTitlesWidget: (value, meta) => _bottomTitle(
                      value.toInt(), data1, range, labelIndices, context, meta),
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false, reservedSize: 20)),
              ),
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Theme.of(context).dividerColor.withAlpha(60),
                  strokeWidth: 0.8,
                ),
                getDrawingVerticalLine: (_) => FlLine(
                  color: Theme.of(context).dividerColor.withAlpha(40),
                  strokeWidth: 0.6,
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) =>
                      Theme.of(context).colorScheme.inverseSurface,
                  getTooltipItems: (touchedSpots) {
                    final onInverse =
                        Theme.of(context).colorScheme.onInverseSurface;
                    final dataBarCount = spots2.isNotEmpty ? 2 : 1;
                    return touchedSpots.map((spot) {
                      if (spot.barIndex >= dataBarCount) {
                        return const LineTooltipItem('', TextStyle(fontSize: 0));
                      }
                      final isLine2 = spots2.isNotEmpty && spot.barIndex == 1;
                      final pts = isLine2 ? data2 : data1;
                      final idx = spot.spotIndex.clamp(0, pts.length - 1);
                      final label =
                          isLine2 ? (label2 ?? 'Stock 2') : (label1 ?? 'Stock 1');
                      final price = pts[idx].close;
                      final dt = pts[idx].time;
                      final dateFmt = range == TimeRange.oneDay
                          ? DateFormat('HH:mm')
                          : DateFormat('dd.MM.yyyy');
                      final dateStr = dateFmt.format(dt);
                      final text = normalize
                          ? '$label\n${spot.y >= 0 ? '+' : ''}${spot.y.toStringAsFixed(2)}%\n$dateStr'
                          : '$label\n${price.toStringAsFixed(2)}\n$dateStr';
                      return LineTooltipItem(
                        text,
                        TextStyle(color: onInverse, fontSize: 12),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _hasAnyIndicator() =>
      indicators.showMa20 ||
      indicators.showMa50 ||
      indicators.showMa200 ||
      indicators.showTrendLine ||
      indicators.showTargetLine ||
      indicators.showBollinger;

  List<ChartDataPoint> _buildMaData(
      List<ChartDataPoint> chartData, List<ChartDataPoint> warmup) {
    if (warmup.isEmpty || chartData.isEmpty) return chartData;
    final chartStart = chartData.first.time;
    final before = warmup.where((p) => p.time.isBefore(chartStart)).toList();
    return [...before, ...chartData];
  }

  List<FlSpot> _calcMA(
      List<ChartDataPoint> combined, int period, int visibleStart) {
    if (combined.length < period) return [];
    final spots = <FlSpot>[];
    for (var i = period - 1; i < combined.length; i++) {
      if (i < visibleStart) continue;
      final sum = combined.sublist(i - period + 1, i + 1)
          .fold(0.0, (acc, p) => acc + p.close);
      final ma = sum / period;
      spots.add(FlSpot((i - visibleStart).toDouble(), ma));
    }
    return spots;
  }

  List<FlSpot> _calcTrendLine(List<FlSpot> spots) {
    if (spots.length < 2) return [];
    final n = spots.length.toDouble();
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (final s in spots) {
      sumX += s.x;
      sumY += s.y;
      sumXY += s.x * s.y;
      sumX2 += s.x * s.x;
    }
    final denom = n * sumX2 - sumX * sumX;
    if (denom == 0) return [];
    final slope = (n * sumXY - sumX * sumY) / denom;
    final intercept = (sumY - slope * sumX) / n;
    return [
      FlSpot(spots.first.x, slope * spots.first.x + intercept),
      FlSpot(spots.last.x, slope * spots.last.x + intercept),
    ];
  }

  ({List<FlSpot> upper, List<FlSpot> lower}) _calcBollinger(
      List<ChartDataPoint> data, int period, double multiplier) {
    if (data.length < period) return (upper: [], lower: []);
    final upper = <FlSpot>[];
    final lower = <FlSpot>[];
    for (var i = period - 1; i < data.length; i++) {
      final window = data.sublist(i - period + 1, i + 1);
      final mean = window.fold(0.0, (a, p) => a + p.close) / period;
      final variance = window.fold(0.0, (a, p) => a + (p.close - mean) * (p.close - mean)) / period;
      final std = math.sqrt(variance);
      upper.add(FlSpot(i.toDouble(), mean + multiplier * std));
      lower.add(FlSpot(i.toDouble(), mean - multiplier * std));
    }
    return (upper: upper, lower: lower);
  }

  Set<int> _labelPositions(int count, int labelCount) {
    if (count <= 0) return {};
    if (count <= labelCount) {
      return {for (var i = 0; i < count - 1; i++) i};
    }
    final maxIdx = (count * 0.90).round().clamp(0, count - 2);
    final positions = <int>{};
    for (var i = 0; i < labelCount; i++) {
      final idx = (i * maxIdx / (labelCount - 1)).round();
      positions.add(idx.clamp(0, maxIdx));
    }
    return positions;
  }

  Widget _leftTitle(double value, bool normalize, BuildContext context) {
    final style = TextStyle(
      fontSize: 11,
      color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
    );
    if (normalize) {
      return Text('${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}%',
          style: style);
    }
    if (value >= 1000) {
      return Text('${(value / 1000).toStringAsFixed(1)}k', style: style);
    }
    return Text(value.toStringAsFixed(value < 10 ? 2 : 0), style: style);
  }

  Widget _bottomTitle(int index, List<ChartDataPoint> data, TimeRange range,
      Set<int> labelIndices, BuildContext context, TitleMeta meta) {
    if (!labelIndices.contains(index)) return const SizedBox.shrink();
    if (index < 0 || index >= data.length) return const SizedBox.shrink();

    final style = TextStyle(
      fontSize: 11,
      color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
    );
    final dt = data[index].time;
    final fmt = range == TimeRange.oneDay
        ? DateFormat('HH:mm')
        : range == TimeRange.oneWeek
            ? DateFormat('EEE')   // Mo, Di, Mi …
            : (range == TimeRange.fiveYears ||
                    range == TimeRange.max ||
                    range == TimeRange.twoYears)
                ? DateFormat('MM/yy')
                : DateFormat('dd.MM.');
    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text(fmt.format(dt), style: style),
    );
  }
}

class _Legend extends StatelessWidget {
  final String? label1;
  final String? label2;
  final Color color1;
  final Color color2;

  const _Legend(
      {this.label1, this.label2, required this.color1, required this.color2});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (label1 != null) ...[
            Container(width: 16, height: 3, color: color1),
            const SizedBox(width: 4),
            Text(label1!, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 16),
          ],
          if (label2 != null) ...[
            Container(width: 16, height: 3, color: color2),
            const SizedBox(width: 4),
            Text(label2!, style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _IndicatorLegend extends StatelessWidget {
  final bool showMa20;
  final bool showMa50;
  final bool showMa200;
  final bool showTrend;
  final bool showTarget;
  final bool showBollinger;
  final double? targetPrice;

  const _IndicatorLegend({
    required this.showMa20,
    required this.showMa50,
    required this.showMa200,
    required this.showTrend,
    required this.showTarget,
    required this.showBollinger,
    this.targetPrice,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (showBollinger) items.add(_LegendItem('BB(20,2)', Colors.purple.shade300, dashed: true));
    if (showMa20) items.add(_LegendItem('MA20', Colors.cyan.shade400));
    if (showMa50) items.add(_LegendItem('MA50', Colors.orange.shade400));
    if (showMa200) items.add(_LegendItem('MA200', Colors.purple.shade400));
    if (showTrend) items.add(_LegendItem('Trend', Colors.amber.shade400, dashed: true));
    if (showTarget && targetPrice != null) {
      items.add(_LegendItem(
        'Ziel ${targetPrice!.toStringAsFixed(2)}',
        Colors.green.shade600,
        dashed: true,
      ));
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Wrap(
        spacing: 10,
        runSpacing: 2,
        alignment: WrapAlignment.center,
        children: items,
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool dashed;
  const _LegendItem(this.label, this.color, {this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dashed
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 2, color: color),
                const SizedBox(width: 2),
                Container(width: 4, height: 2, color: color),
              ])
            : Container(width: 12, height: 2, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(180))),
      ],
    );
  }
}
