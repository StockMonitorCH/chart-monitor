import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/chart_state.dart';
import 'index_comparison_sheet.dart';
import 'index_data.dart';

class IndexSheet extends StatelessWidget {
  const IndexSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const IndexSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = context.watch<ChartState>();
    final currentStock2 = state.stock2Info?.symbol;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  Icon(Icons.bar_chart,
                      color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.indicesTitle,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (currentStock2 != null &&
                      kIndices.any((i) => i.symbol == currentStock2))
                    TextButton(
                      onPressed: () {
                        context.read<ChartState>().removeStock2();
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.removeCompare,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12)),
                    ),
                  // Open comparison chart
                  IconButton(
                    icon: const Icon(Icons.stacked_bar_chart_outlined, size: 22),
                    tooltip: l10n.indexCompareTitle,
                    onPressed: () {
                      Navigator.of(context).pop();
                      IndexComparisonSheet.show(context,
                          watchlist: state.watchlist.toList());
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(l10n.indicesCompareHint,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(140))),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                itemCount: kIndices.length,
                separatorBuilder: (ctx, i) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (_, i) {
                  final entry = kIndices[i];
                  final isSelected = currentStock2 == entry.symbol;
                  return ListTile(
                    dense: true,
                    leading: _RegionBadge(entry.region),
                    title: Text(entry.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        )),
                    subtitle: Text(entry.symbol,
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(120))),
                    trailing: isSelected
                        ? Icon(Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18)
                        : const Icon(Icons.add_chart_outlined,
                            size: 18, color: Colors.grey),
                    onTap: () {
                      if (isSelected) {
                        context.read<ChartState>().removeStock2();
                      } else {
                        context.read<ChartState>().loadStock2(entry.symbol);
                      }
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RegionBadge extends StatelessWidget {
  final String region;
  const _RegionBadge(this.region);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 22,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        region,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
