import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

/// Schliesst die Tastatur beim Tippen auf eine freie Fläche und zeigt auf iOS
/// eine "Fertig"-Leiste über der Tastatur – die Zahlentastaturen von iOS haben
/// keine eigene Fertig-Taste.
class KeyboardDoneBar extends StatelessWidget {
  final Widget child;

  const KeyboardDoneBar({super.key, required this.child});

  static const double _barHeight = 44;

  void _dismiss() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboard = mq.viewInsets.bottom;
    final showBar = defaultTargetPlatform == TargetPlatform.iOS && keyboard > 0;
    final theme = Theme.of(context);

    // Baumstruktur bleibt immer gleich, damit der Zustand der App beim
    // Ein-/Ausblenden der Tastatur nicht verloren geht.
    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _dismiss,
          child: MediaQuery(
            // Inhalt weicht zusätzlich der Leiste aus
            data: mq.copyWith(
              viewInsets: mq.viewInsets.copyWith(
                bottom: showBar ? keyboard + _barHeight : keyboard,
              ),
            ),
            child: child,
          ),
        ),
        if (showBar)
          Positioned(
            left: 0,
            right: 0,
            bottom: keyboard,
            height: _barHeight,
            child: Material(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.dividerColor, width: 0.5),
                  ),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextButton(
                  onPressed: _dismiss,
                  child: Text(
                    AppLocalizations.of(context)!.keyboardDone,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
