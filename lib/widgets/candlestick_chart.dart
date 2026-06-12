import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_data.dart';

class CandlestickChartWidget extends StatefulWidget {
  final List<ChartDataPoint> data;
  final List<ChartDataPoint> maWarmupData;
  final TimeRange range;
  final ChartIndicators indicators;

  const CandlestickChartWidget({
    super.key,
    required this.data,
    this.maWarmupData = const [],
    required this.range,
    this.indicators = ChartIndicators.none,
  });

  @override
  State<CandlestickChartWidget> createState() => _CandlestickChartWidgetState();
}

class _CandlestickChartWidgetState extends State<CandlestickChartWidget> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    final valid = widget.data.where((p) => p.hasOhlc).toList();
    if (valid.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        _InfoBar(
          data: valid,
          index: _hoveredIndex,
          range: widget.range,
          cs: cs,
        ),
        Expanded(
          child: GestureDetector(
            onTapDown: (d) => _onTouch(d.localPosition, context, valid),
            onPanUpdate: (d) => _onTouch(d.localPosition, context, valid),
            onPanEnd: (_) => setState(() => _hoveredIndex = null),
            onTapUp: (_) => setState(() => _hoveredIndex = null),
            child: CustomPaint(
              painter: _CandlestickPainter(
                data: valid,
                maWarmupData: widget.maWarmupData,
                range: widget.range,
                hoveredIndex: _hoveredIndex,
                indicators: widget.indicators,
                bullColor: Colors.green.shade400,
                bearColor: Colors.red.shade400,
                gridColor: cs.onSurface.withAlpha(30),
                labelColor: cs.onSurface.withAlpha(160),
                highlightColor: cs.primary.withAlpha(60),
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ],
    );
  }

  void _onTouch(Offset pos, BuildContext context, List<ChartDataPoint> data) {
    const leftPad = 64.0;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final chartW = box.size.width - leftPad;
    if (chartW <= 0) return;
    final candleW = chartW / data.length;
    final idx = ((pos.dx - leftPad) / candleW).floor().clamp(0, data.length - 1);
    if (idx != _hoveredIndex) setState(() => _hoveredIndex = idx);
  }
}

// ── Info bar shown when touching ─────────────────────────────────────────────

class _InfoBar extends StatelessWidget {
  final List<ChartDataPoint> data;
  final int? index;
  final TimeRange range;
  final ColorScheme cs;

  const _InfoBar({required this.data, required this.index, required this.range, required this.cs});

  @override
  Widget build(BuildContext context) {
    if (index == null || index! >= data.length) {
      return const SizedBox(height: 22);
    }
    final p = data[index!];
    final fmt = range.isIntraday ? DateFormat('HH:mm') : DateFormat('dd.MM.yy');
    final isBull = p.close >= (p.open ?? p.close);
    final color = isBull ? Colors.green.shade400 : Colors.red.shade400;

    String f(double v) => v >= 1000
        ? v.toStringAsFixed(0)
        : v < 10
            ? v.toStringAsFixed(3)
            : v.toStringAsFixed(2);

    return SizedBox(
      height: 22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(fmt.format(p.time),
              style: TextStyle(fontSize: 10, color: cs.onSurface.withAlpha(150))),
          const SizedBox(width: 8),
          _val('O', f(p.open!), cs),
          _val('H', f(p.high!), cs),
          _val('L', f(p.low!), cs),
          _val('C', f(p.close), cs, color: color),
        ],
      ),
    );
  }

  Widget _val(String label, String value, ColorScheme cs, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: RichText(
      text: TextSpan(
        children: [
          TextSpan(text: '$label ', style: TextStyle(fontSize: 9, color: cs.onSurface.withAlpha(120))),
          TextSpan(text: value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
              color: color ?? cs.onSurface.withAlpha(200))),
        ],
      ),
    ),
  );
}

// ── CustomPainter ─────────────────────────────────────────────────────────────

class _CandlestickPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final List<ChartDataPoint> maWarmupData;
  final TimeRange range;
  final int? hoveredIndex;
  final ChartIndicators indicators;
  final Color bullColor;
  final Color bearColor;
  final Color gridColor;
  final Color labelColor;
  final Color highlightColor;

  const _CandlestickPainter({
    required this.data,
    required this.maWarmupData,
    required this.range,
    required this.hoveredIndex,
    required this.indicators,
    required this.bullColor,
    required this.bearColor,
    required this.gridColor,
    required this.labelColor,
    required this.highlightColor,
  });

  static const _leftPad = 64.0;
  static const _bottomPad = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final chartW = size.width - _leftPad;
    final chartH = size.height - _bottomPad;

    final allHighs = data.map((p) => p.high!);
    final allLows  = data.map((p) => p.low!);
    double minY = allLows.reduce(math.min);
    double maxY = allHighs.reduce(math.max);

    // Expand Y range to include target price if visible
    if (indicators.showTargetLine && indicators.analystTarget != null) {
      final t = indicators.analystTarget!;
      if (t < minY) minY = t;
      if (t > maxY) maxY = t;
    }

    // Expand for MA lines (using combined warmup+chart data)
    final combinedForExpand = _buildMaData(data, maWarmupData);
    if (indicators.showMa20) _expandForMA(combinedForExpand, 20, minY, maxY, (lo, hi) { minY = lo; maxY = hi; });
    if (indicators.showMa50) _expandForMA(combinedForExpand, 50, minY, maxY, (lo, hi) { minY = lo; maxY = hi; });
    if (indicators.showMa200) _expandForMA(combinedForExpand, 200, minY, maxY, (lo, hi) { minY = lo; maxY = hi; });

    final range_ = maxY - minY;
    if (range_ == 0) return;
    final padY = range_ * 0.05;
    final yMin = minY - padY;
    final yMax = maxY + padY;

    double xPos(int i) => _leftPad + (i + 0.5) * chartW / data.length;
    double yPos(double v) => chartH * (1 - (v - yMin) / (yMax - yMin));

    // ── Grid + Y labels ───────────────────────────────────────────────────────
    final labelCount = (chartH / 50).floor().clamp(3, 6);
    final interval = _niceInterval((yMax - yMin) / labelCount);
    final firstLabel = (yMin / interval).ceil() * interval;

    final gridPaint = Paint()..color = gridColor..strokeWidth = 0.8;
    final labelStyle = TextStyle(color: labelColor, fontSize: 10);

    for (var v = firstLabel; v <= yMax + interval * 0.1; v += interval) {
      final y = yPos(v);
      if (y < 0 || y > chartH) continue;
      canvas.drawLine(Offset(_leftPad, y), Offset(size.width, y), gridPaint);
      _drawText(canvas, _formatY(v), Offset(0, y - 7), size: const Size(60, 14),
          style: labelStyle, align: TextAlign.right);
    }

    // ── X labels ──────────────────────────────────────────────────────────────
    final labelIndices = _labelPositions(data.length, 4);
    final dateFmt = range.isIntraday ? DateFormat('HH:mm') : DateFormat('dd.MM.');
    for (final idx in labelIndices) {
      final x = xPos(idx);
      _drawText(canvas, dateFmt.format(data[idx].time),
          Offset(x - 20, chartH + 4), size: const Size(40, 14),
          style: labelStyle, align: TextAlign.center);
    }

    // ── Highlight touched candle ──────────────────────────────────────────────
    if (hoveredIndex != null && hoveredIndex! < data.length) {
      final x = xPos(hoveredIndex!);
      final candleW = (chartW / data.length).clamp(4.0, 20.0);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, chartH / 2), width: candleW + 4, height: chartH),
        Paint()..color = highlightColor,
      );
    }

    // ── Candles ───────────────────────────────────────────────────────────────
    final bodyW = ((chartW / data.length) * 0.65).clamp(2.0, 14.0);

    for (var i = 0; i < data.length; i++) {
      final p = data[i];
      final x = xPos(i);
      final isBull = p.close >= p.open!;
      final color = isBull ? bullColor : bearColor;
      final paint = Paint()..color = color..strokeWidth = 1.0;

      final yHigh = yPos(p.high!);
      final yLow  = yPos(p.low!);
      canvas.drawLine(Offset(x, yHigh), Offset(x, yLow), paint);

      final yOpen  = yPos(p.open!);
      final yClose = yPos(p.close);
      final top    = math.min(yOpen, yClose);
      final bottom = math.max(yOpen, yClose);
      final bodyH  = (bottom - top).clamp(1.0, chartH);
      canvas.drawRect(
        Rect.fromLTWH(x - bodyW / 2, top, bodyW, bodyH),
        Paint()..color = color,
      );
    }

    // ── MA lines (with warmup data for full coverage) ─────────────────────────
    final combined = _buildMaData(data, maWarmupData);
    final visibleStart = combined.length - data.length;
    if (indicators.showMa20) {
      _drawMA(canvas, combined, 20, visibleStart, Colors.cyan.shade400, xPos, yPos, chartH);
    }
    if (indicators.showMa50) {
      _drawMA(canvas, combined, 50, visibleStart, Colors.orange.shade400, xPos, yPos, chartH);
    }
    if (indicators.showMa200) {
      _drawMA(canvas, combined, 200, visibleStart, Colors.purple.shade400, xPos, yPos, chartH);
    }

    // ── Trend line ────────────────────────────────────────────────────────────
    if (indicators.showTrendLine && data.length >= 2) {
      final n = data.length;
      double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
      for (var i = 0; i < n; i++) {
        sumX += i; sumY += data[i].close;
        sumXY += i * data[i].close; sumX2 += i * i;
      }
      final denom = n * sumX2 - sumX * sumX;
      if (denom != 0) {
        final slope = (n * sumXY - sumX * sumY) / denom;
        final intercept = (sumY - slope * sumX) / n;
        final paint = Paint()
          ..color = Colors.amber.shade400
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(xPos(0), yPos(intercept)),
          Offset(xPos(n - 1), yPos(slope * (n - 1) + intercept)),
          paint,
        );
      }
    }

    // ── Target line ───────────────────────────────────────────────────────────
    if (indicators.showTargetLine && indicators.analystTarget != null) {
      final y = yPos(indicators.analystTarget!);
      if (y >= 0 && y <= chartH) {
        _drawDashedLine(
          canvas,
          Offset(_leftPad, y),
          Offset(size.width, y),
          Colors.green.shade600,
          1.5,
        );
      }
    }
  }

  List<ChartDataPoint> _buildMaData(
      List<ChartDataPoint> chartData, List<ChartDataPoint> warmup) {
    if (warmup.isEmpty || chartData.isEmpty) return chartData;
    final chartStart = chartData.first.time;
    final before = warmup.where((p) => p.time.isBefore(chartStart)).toList();
    return [...before, ...chartData];
  }

  void _expandForMA(List<ChartDataPoint> data, int period, double currentMin, double currentMax,
      void Function(double, double) update) {
    if (data.length < period) return;
    double lo = currentMin, hi = currentMax;
    for (var i = period - 1; i < data.length; i++) {
      final sum = data.sublist(i - period + 1, i + 1).fold(0.0, (a, p) => a + p.close);
      final ma = sum / period;
      if (ma < lo) lo = ma;
      if (ma > hi) hi = ma;
    }
    update(lo, hi);
  }

  void _drawMA(Canvas canvas, List<ChartDataPoint> combined, int period, int visibleStart,
      Color color, double Function(int) xPos, double Function(double) yPos, double chartH) {
    if (combined.length < period) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path();
    bool started = false;
    for (var i = period - 1; i < combined.length; i++) {
      if (i < visibleStart) continue;
      final sum = combined.sublist(i - period + 1, i + 1).fold(0.0, (a, p) => a + p.close);
      final ma = sum / period;
      final visibleIdx = i - visibleStart;
      final x = xPos(visibleIdx);
      final y = yPos(ma);
      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Color color, double strokeWidth) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    const dashLen = 6.0;
    const gapLen = 4.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return;
    final ux = dx / len;
    final uy = dy / len;
    double dist = 0;
    bool drawing = true;
    Offset cur = start;
    while (dist < len) {
      final step = drawing ? dashLen : gapLen;
      final next = dist + step;
      final end_ = next > len ? len : next;
      final nx = start.dx + ux * end_;
      final ny = start.dy + uy * end_;
      if (drawing) {
        canvas.drawLine(cur, Offset(nx, ny), paint);
      }
      cur = Offset(nx, ny);
      dist = next;
      drawing = !drawing;
    }
  }

  Set<int> _labelPositions(int count, int n) {
    if (count <= n) return {for (var i = 0; i < count - 1; i++) i};
    final maxIdx = (count * 0.90).round().clamp(0, count - 2);
    final pos = <int>{};
    for (var i = 0; i < n; i++) { pos.add((i * maxIdx / (n - 1)).round().clamp(0, maxIdx)); }
    return pos;
  }

  double _niceInterval(double raw) {
    if (raw <= 0) return 1;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final frac = raw / mag;
    if (frac <= 1.5) return mag;
    if (frac <= 3)   return mag * 2;
    if (frac <= 7)   return mag * 5;
    return mag * 10;
  }

  String _formatY(double v) {
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    if (v < 10) return v.toStringAsFixed(3);
    return v.toStringAsFixed(v < 100 ? 2 : 0);
  }

  void _drawText(Canvas canvas, String text, Offset offset,
      {required Size size, required TextStyle style, TextAlign align = TextAlign.left}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: size.width);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_CandlestickPainter old) =>
      old.data != data ||
      old.maWarmupData != maWarmupData ||
      old.hoveredIndex != hoveredIndex ||
      old.indicators.showMa20 != indicators.showMa20 ||
      old.indicators.showMa50 != indicators.showMa50 ||
      old.indicators.showMa200 != indicators.showMa200 ||
      old.indicators.showTrendLine != indicators.showTrendLine ||
      old.indicators.showTargetLine != indicators.showTargetLine ||
      old.indicators.analystTarget != indicators.analystTarget;
}
