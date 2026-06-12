import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

class InfoDialog extends StatelessWidget {
  const InfoDialog({super.key});

  static void show(BuildContext context) {
    showDialog(context: context, builder: (_) => const InfoDialog());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l10n.infoTitle),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header wie FX Calc
            Center(
              child: Column(
                children: [
                  Text('Chart Monitor',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: cs.primary)),
                  const SizedBox(height: 2),
                  Text(l10n.infoAppSubtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withAlpha(160))),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Text(l10n.infoStockMonitorDesc,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 8),
                          Text(l10n.infoDataSource,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11)),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.language, size: 16),
                            label: const Text('www.stock-monitor.ch',
                                style: TextStyle(fontSize: 13)),
                            onPressed: () => launchUrl(
                                Uri.parse('https://www.stock-monitor.ch'),
                                mode: LaunchMode.externalApplication),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            _Section(
              icon: Icons.volunteer_activism,
              title: l10n.infoDonate,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.infoDonateDesc, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 10),
                  // Twint QR-Code
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/twint_qr.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 4),
                        const Text('TWINT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _LinkButton(
                    label: l10n.donatePaypal,
                    url: 'https://paypal.me/StockMonitor',
                    icon: Icons.payment,
                  ),
                ],
              ),
            ),
            const Divider(),
            _Section(
              icon: Icons.mail_outline,
              title: l10n.infoContact,
              child: _LinkButton(
                label: 'info@stock-monitor.ch',
                url: 'mailto:info@stock-monitor.ch',
                icon: Icons.email_outlined,
              ),
            ),
            const Divider(),
            _Section(
              icon: Icons.lock_outline,
              title: l10n.infoPrivacy,
              child: Text(l10n.privacyText, style: const TextStyle(fontSize: 13)),
            ),
            const Divider(),
            _Section(
              icon: Icons.description_outlined,
              title: l10n.infoLicense,
              child: _LinkButton(
                label: 'GPL-3.0',
                url: 'https://www.gnu.org/licenses/gpl-3.0.html',
                icon: Icons.open_in_new,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _Section({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Padding(padding: const EdgeInsets.only(left: 22), child: child),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final String url;
  final IconData icon;

  const _LinkButton({required this.label, required this.url, required this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final uri = Uri.parse(url);
        final mode = uri.scheme == 'mailto'
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication;
        launchUrl(uri, mode: mode);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                )),
          ),
        ],
      ),
    );
  }
}
