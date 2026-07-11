import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/stock_rating_service.dart';

class StockRatingSheet {
  static Future<void> show(
    BuildContext context, {
    required String symbol,
    required String name,
    required double currentPrice,
    required Color color,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => _RatingDialog(
        symbol: symbol,
        name: name,
        currentPrice: currentPrice,
        color: color,
      ),
    );
  }
}

class _RatingDialog extends StatefulWidget {
  final String symbol;
  final String name;
  final double currentPrice;
  final Color color;

  const _RatingDialog({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.color,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  StockRatingResult? _result;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _compute();
  }

  Future<void> _compute() async {
    try {
      final result = await StockRatingService()
          .computeRating(widget.symbol, widget.currentPrice);
      if (mounted) setState(() { _result = result; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = true; _loading = false; });
    }
  }

  void _showInfoDialog(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx)!;
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(l10n.ratingInfoTitle,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            l10n.ratingInfoBody,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title row with info button ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.ratingTitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withAlpha(160),
                          ),
                        ),
                        Text(
                          widget.symbol,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: widget.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: theme.colorScheme.onSurface.withAlpha(140),
                    ),
                    tooltip: l10n.ratingInfoTitle,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 30, minHeight: 30),
                    onPressed: () => _showInfoDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Content ────────────────────────────────────────────────────
              if (_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(strokeWidth: 2),
                        const SizedBox(height: 10),
                        Text(l10n.ratingLoading,
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface
                                    .withAlpha(140))),
                      ],
                    ),
                  ),
                )
              else if (_error || _result == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(l10n.ratingError,
                        style: TextStyle(
                            color: theme.colorScheme.onSurface.withAlpha(140))),
                  ),
                )
              else
                _ResultContent(result: _result!, color: widget.color, l10n: l10n),

              const SizedBox(height: 8),

              // ── Disclaimer + close ─────────────────────────────────────────
              if (!_loading)
                Text(
                  l10n.ratingDisclaimer,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withAlpha(90),
                  ),
                ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultContent extends StatelessWidget {
  final StockRatingResult result;
  final Color color;
  final AppLocalizations l10n;

  const _ResultContent({
    required this.result,
    required this.color,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Overall rating – highlighted
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: _RatingRow(
            label: l10n.ratingOverall,
            stars: result.overall,
            bold: true,
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: Colors.grey.withAlpha(60)),
        const SizedBox(height: 4),
        _RatingRow(label: l10n.ratingPerformance, stars: result.performance),
        _RatingRow(label: l10n.ratingRisk, stars: result.risk),
        _RatingRow(label: l10n.ratingFundamental, stars: result.fundamental),
        _RatingRow(label: l10n.ratingTechnical, stars: result.technical),
        _RatingRow(label: l10n.ratingTradability, stars: result.tradability),
        _RatingRow(label: l10n.ratingAnalyst, stars: result.analyst),
      ],
    );
  }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final double stars;
  final bool bold;

  const _RatingRow({
    required this.label,
    required this.stars,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: bold ? 14 : 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          _StarRating(value: stars, size: bold ? 20 : 17),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final double value;
  final double size;

  const _StarRating({required this.value, this.size = 18});

  @override
  Widget build(BuildContext context) {
    const starColor = Colors.amber;
    final emptyColor = Colors.amber.withAlpha(80);
    final full = value.floor();
    final hasHalf = (value - full) >= 0.25;
    final empty = 5 - full - (hasHalf ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < full; i++)
          Icon(Icons.star_rounded, color: starColor, size: size),
        if (hasHalf)
          Icon(Icons.star_half_rounded, color: starColor, size: size),
        for (var i = 0; i < empty; i++)
          Icon(Icons.star_outline_rounded, color: emptyColor, size: size),
      ],
    );
  }
}
