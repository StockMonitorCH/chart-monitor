// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Chart Monitor';

  @override
  String get searchHint => 'ISIN, ticker or company name';

  @override
  String get searchLabel => 'Search stock';

  @override
  String get compareLabel => 'Add comparison';

  @override
  String get removeCompare => 'Remove comparison';

  @override
  String get timeRange1D => '1D';

  @override
  String get timeRange1W => '1W';

  @override
  String get timeRange1M => '1M';

  @override
  String get timeRange3M => '3M';

  @override
  String get timeRange6M => '6M';

  @override
  String get timeRange1Y => '1Y';

  @override
  String get timeRange5Y => '5Y';

  @override
  String get timeRangeMax => 'Max';

  @override
  String get extendedHoursLabel => 'Extended Hours (Pre/Post Market)';

  @override
  String get noDataFound => 'No data found';

  @override
  String searchNoResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get loadingData => 'Loading data…';

  @override
  String get errorLoading => 'Error loading data';

  @override
  String get retry => 'Retry';

  @override
  String get infoTitle => 'Info';

  @override
  String get infoStockMonitor => 'Stock Monitor';

  @override
  String get infoStockMonitorDesc =>
      'Chart Monitor is part of Stock Monitor – the free portfolio app for desktop (Windows, Flatpak, RPM).';

  @override
  String get infoStockMonitorWebsite => 'Website: www.stock-monitor.ch';

  @override
  String get infoLicense => 'License';

  @override
  String get infoPrivacy => 'Privacy Policy';

  @override
  String get infoPrivacyDecline => 'Decline';

  @override
  String get infoPrivacyAccept => 'Accept';

  @override
  String get infoContact => 'Contact';

  @override
  String get infoDonate => 'Donate';

  @override
  String get infoDonateDesc =>
      'If you enjoy the app, I appreciate your support:';

  @override
  String get donateTwint => 'Donate via Twint';

  @override
  String get donatePaypal => 'Donate via PayPal';

  @override
  String get close => 'Close';

  @override
  String get stock1Label => 'Stock 1';

  @override
  String get stock2Label => 'Stock 2';

  @override
  String changePercent(String value) {
    return '$value%';
  }

  @override
  String get privacyTitle => 'Privacy Policy';

  @override
  String get privacyText =>
      'Chart Monitor does not store any personal data. Price data is retrieved from Yahoo Finance. No data is shared with third parties.';

  @override
  String get contactEmail => 'Contact via Email';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get analystTitle => 'Analysts';

  @override
  String get detailsTitle => 'Company Info';

  @override
  String get detailsCompanyInfo => 'Company';

  @override
  String get detailsValuation => 'Valuation';

  @override
  String get detailsDividends => 'Dividends';

  @override
  String get detailsDivHistory => 'Dividend History (per year)';

  @override
  String get detailsDescription => 'Description';

  @override
  String get detailsSector => 'Sector';

  @override
  String get detailsIndustry => 'Industry';

  @override
  String get detailsCountry => 'Country';

  @override
  String get detailsCEO => 'CEO';

  @override
  String get detailsEmployees => 'Employees';

  @override
  String get detailsMarketCap => 'Market Cap';

  @override
  String get details52wHigh => '52-W High';

  @override
  String get details52wLow => '52-W Low';

  @override
  String get detailsNextEarnings => 'Next Earnings';

  @override
  String get detailsDivRate => 'Dividend/Share';

  @override
  String get detailsDivYield => 'Dividend Yield';

  @override
  String get detailsExDivDate => 'Ex-Dividend';

  @override
  String get timeRange2Y => '2Y';

  @override
  String get timeRangeCustom => 'Custom';

  @override
  String get timeRangeMore => 'More';

  @override
  String periodPerf(String pct, String abs) {
    return '$pct / $abs';
  }

  @override
  String get customRangeTitle => 'Select period';

  @override
  String get customRangeFrom => 'From';

  @override
  String get customRangeTo => 'To';

  @override
  String get customRangeApply => 'Apply';

  @override
  String get customRangeDateInvalid => 'Invalid date or range';

  @override
  String get noData => 'No data available';

  @override
  String get detailsComposition => 'Composition';

  @override
  String get detailsTopHoldings => 'Top Holdings';

  @override
  String get detailsSectorWeights => 'Sector Weights';

  @override
  String get infoAppSubtitle => 'Stock charts & comparison';

  @override
  String get infoDataSource => 'Data source: Yahoo Finance';

  @override
  String get fxCalcTitle => 'FX Calculator';

  @override
  String get fxCurrencyTab => 'Currency';

  @override
  String get fxSavingsTab => 'Interest';

  @override
  String get fxFinanceTab => 'Finance';

  @override
  String get watchlistTitle => 'Watchlist';

  @override
  String get watchlistEmpty => 'Watchlist is empty';

  @override
  String get watchlistAdd => 'Add stock';

  @override
  String get detailsNews => 'News';

  @override
  String get newsNone => 'No news available';

  @override
  String get timeRangeYtd => 'YTD';

  @override
  String get preMarket => 'Pre-market';

  @override
  String get postMarket => 'After-hours';

  @override
  String get indicatorTrend => 'Trend';

  @override
  String get indicatorTarget => 'Target';

  @override
  String wlAlarmTitle(String symbol) {
    return 'Alert: $symbol';
  }

  @override
  String get wlAlarmStopLoss => 'Stop-Loss';

  @override
  String get wlAlarmTarget => 'Target Price';

  @override
  String wlAlarmCurrentPrice(String price) {
    return 'Current: $price';
  }

  @override
  String get wlAlarmSave => 'Save';

  @override
  String get wlAlarmClear => 'Clear Alert';

  @override
  String get wlAlarmCancel => 'Cancel';

  @override
  String get wlSortManual => 'Manual';

  @override
  String get wlSortAZ => 'A → Z';

  @override
  String get wlSortZA => 'Z → A';

  @override
  String get wlSortPerfDesc => 'Performance ↓';

  @override
  String get wlSortPerfAsc => 'Performance ↑';

  @override
  String get wlSortGics => 'Sector (GICS)';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get updateAvailable => 'Update available';

  @override
  String updateAvailableDesc(String version) {
    return 'Version $version is available.\n\nTap «Download» → APK downloads in browser → tap «Open» in the download notification → Install.';
  }

  @override
  String get updateLater => 'Later';

  @override
  String get updateDownload => 'Download';

  @override
  String updateUpToDate(String version) {
    return 'App is up to date (v$version)';
  }

  @override
  String get privacyConsentBody =>
      'Chart Monitor does not store personal data. Price data is fetched live from Yahoo Finance.\n\nPlease accept our privacy policy to use the app.';

  @override
  String get noConnection => 'No connection';

  @override
  String get indicesTitle => 'Indices';

  @override
  String get indicesCompareHint => 'Load index as comparison';

  @override
  String get indexCompareTitle => 'Index Comparison';

  @override
  String get indexCompareShowWatchlist => 'Include Watchlist';

  @override
  String get indexCompareSelectIndices => 'Select Indices';

  @override
  String get indexCompareAll => 'All';

  @override
  String get indexCompareNone => 'None';

  @override
  String get notesTitle => 'Notes';

  @override
  String get notesEmpty => 'No notes yet';

  @override
  String get notesAdd => 'Add note';

  @override
  String get notesHint => 'Enter note…';

  @override
  String get notesDelete => 'Delete';

  @override
  String get notesClearAll => 'Clear all';

  @override
  String get notesClearAllConfirm => 'Delete all notes?';
}
