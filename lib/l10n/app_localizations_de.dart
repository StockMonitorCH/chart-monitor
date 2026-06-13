// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Chart Monitor';

  @override
  String get searchHint => 'ISIN, Kürzel oder Firmenname';

  @override
  String get searchLabel => 'Aktie suchen';

  @override
  String get compareLabel => 'Vergleich hinzufügen';

  @override
  String get removeCompare => 'Vergleich entfernen';

  @override
  String get timeRange1D => '1T';

  @override
  String get timeRange1W => '1W';

  @override
  String get timeRange1M => '1M';

  @override
  String get timeRange3M => '3M';

  @override
  String get timeRange6M => '6M';

  @override
  String get timeRange1Y => '1J';

  @override
  String get timeRange5Y => '5J';

  @override
  String get timeRangeMax => 'Max';

  @override
  String get noDataFound => 'Keine Daten gefunden';

  @override
  String searchNoResults(String query) {
    return 'Keine Ergebnisse für \"$query\"';
  }

  @override
  String get loadingData => 'Daten werden geladen…';

  @override
  String get errorLoading => 'Fehler beim Laden der Daten';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get infoTitle => 'Info';

  @override
  String get infoStockMonitor => 'Stock Monitor';

  @override
  String get infoStockMonitorDesc =>
      'Chart Monitor ist Teil von Stock Monitor – der kostenlosen Portfolio-App für Desktop (Windows, Flatpak, RPM).';

  @override
  String get infoStockMonitorWebsite => 'Website: www.stock-monitor.ch';

  @override
  String get infoLicense => 'Lizenz';

  @override
  String get infoPrivacy => 'Datenschutzerklärung';

  @override
  String get infoPrivacyDecline => 'Ablehnen';

  @override
  String get infoPrivacyAccept => 'Akzeptieren';

  @override
  String get infoContact => 'Kontakt';

  @override
  String get infoDonate => 'Spenden';

  @override
  String get infoDonateDesc =>
      'Wenn dir die App gefällt, freue ich mich über eine kleine Unterstützung:';

  @override
  String get donateTwint => 'Spenden via Twint';

  @override
  String get donatePaypal => 'Spenden via PayPal';

  @override
  String get close => 'Schließen';

  @override
  String get stock1Label => 'Aktie 1';

  @override
  String get stock2Label => 'Aktie 2';

  @override
  String changePercent(String value) {
    return '$value%';
  }

  @override
  String get privacyTitle => 'Datenschutzerklärung';

  @override
  String get privacyText =>
      'Chart Monitor speichert keine persönlichen Daten. Kursdaten werden von Yahoo Finance abgerufen. Es werden keine Daten an Dritte weitergegeben.';

  @override
  String get contactEmail => 'Kontakt per E-Mail';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get detailsTitle => 'Firmeninfos';

  @override
  String get detailsCompanyInfo => 'Unternehmen';

  @override
  String get detailsValuation => 'Bewertung';

  @override
  String get detailsDividends => 'Dividenden';

  @override
  String get detailsDivHistory => 'Dividendenhistorie (pro Jahr)';

  @override
  String get detailsDescription => 'Beschreibung';

  @override
  String get detailsSector => 'Sektor';

  @override
  String get detailsIndustry => 'Branche';

  @override
  String get detailsCountry => 'Land';

  @override
  String get detailsCEO => 'CEO';

  @override
  String get detailsEmployees => 'Mitarbeiter';

  @override
  String get detailsMarketCap => 'Marktkapitalisierung';

  @override
  String get details52wHigh => '52-W-Hoch';

  @override
  String get details52wLow => '52-W-Tief';

  @override
  String get detailsNextEarnings => 'Nächste Ergebnisse';

  @override
  String get detailsDivRate => 'Dividende/Aktie';

  @override
  String get detailsDivYield => 'Dividendenrendite';

  @override
  String get detailsExDivDate => 'Ex-Dividende';

  @override
  String get timeRange2Y => '2J';

  @override
  String get timeRangeCustom => 'Individuell';

  @override
  String get timeRangeMore => 'Mehr';

  @override
  String periodPerf(String pct, String abs) {
    return '$pct / $abs';
  }

  @override
  String get customRangeTitle => 'Zeitraum wählen';

  @override
  String get customRangeFrom => 'Von';

  @override
  String get customRangeTo => 'Bis';

  @override
  String get noData => 'Keine Daten verfügbar';

  @override
  String get detailsComposition => 'Zusammensetzung';

  @override
  String get detailsTopHoldings => 'Top-Positionen';

  @override
  String get detailsSectorWeights => 'Sektorgewichtung';

  @override
  String get infoAppSubtitle => 'Aktiencharts & Vergleiche';

  @override
  String get infoDataSource => 'Kursdaten: Yahoo Finance';

  @override
  String get fxCalcTitle => 'FX Rechner';

  @override
  String get fxCurrencyTab => 'Währung';

  @override
  String get fxSavingsTab => 'Zins';

  @override
  String get watchlistTitle => 'Watchlist';

  @override
  String get watchlistEmpty => 'Watchlist ist leer';

  @override
  String get watchlistAdd => 'Aktie hinzufügen';

  @override
  String get detailsNews => 'Nachrichten';

  @override
  String get newsNone => 'Keine Nachrichten verfügbar';

  @override
  String get timeRangeYtd => 'YTD';

  @override
  String get preMarket => 'Vorbörse';

  @override
  String get postMarket => 'Nachbörse';

  @override
  String get indicatorTrend => 'Trend';

  @override
  String get indicatorTarget => 'Ziel';

  @override
  String wlAlarmTitle(String symbol) {
    return 'Alarm: $symbol';
  }

  @override
  String get wlAlarmStopLoss => 'Stop-Loss';

  @override
  String get wlAlarmTarget => 'Zielkurs';

  @override
  String wlAlarmCurrentPrice(String price) {
    return 'Aktuell: $price';
  }

  @override
  String get wlAlarmSave => 'Speichern';

  @override
  String get wlAlarmClear => 'Alarm löschen';

  @override
  String get wlAlarmCancel => 'Abbrechen';

  @override
  String get wlSortManual => 'Manuell';

  @override
  String get wlSortAZ => 'A → Z';

  @override
  String get wlSortZA => 'Z → A';

  @override
  String get wlSortPerfDesc => 'Performance ↓';

  @override
  String get wlSortPerfAsc => 'Performance ↑';

  @override
  String get wlSortGics => 'Sektor (GICS)';

  @override
  String get checkForUpdates => 'Nach Updates suchen';

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String updateAvailableDesc(String version) {
    return 'Version $version ist verfügbar.\n\nAuf «Download» tippen → APK wird im Browser heruntergeladen → in der Download-Benachrichtigung auf «Öffnen» tippen → Installieren.';
  }

  @override
  String get updateLater => 'Später';

  @override
  String get updateDownload => 'Download';

  @override
  String updateUpToDate(String version) {
    return 'App ist aktuell (v$version)';
  }

  @override
  String get privacyConsentBody =>
      'Chart Monitor speichert keine persönlichen Daten. Kursdaten werden live von Yahoo Finance abgerufen.\n\nBitte stimme unserer Datenschutzerklärung zu, um die App zu nutzen.';

  @override
  String get noConnection => 'Keine Verbindung';

  @override
  String get indicesTitle => 'Indizes';

  @override
  String get indicesCompareHint => 'Index als Vergleich laden';

  @override
  String get indexCompareTitle => 'Indexvergleich';

  @override
  String get indexCompareShowWatchlist => 'Watchlist einbeziehen';

  @override
  String get indexCompareSelectIndices => 'Indizes auswählen';

  @override
  String get indexCompareAll => 'Alle';

  @override
  String get indexCompareNone => 'Keine';

  @override
  String get notesTitle => 'Notizen';

  @override
  String get notesEmpty => 'Keine Notizen vorhanden';

  @override
  String get notesAdd => 'Notiz hinzufügen';

  @override
  String get notesHint => 'Notiz eingeben…';

  @override
  String get notesDelete => 'Löschen';

  @override
  String get notesClearAll => 'Alle löschen';

  @override
  String get notesClearAllConfirm => 'Alle Notizen löschen?';
}
