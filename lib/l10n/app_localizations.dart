import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Chart Monitor'**
  String get appTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'ISIN, ticker or company name'**
  String get searchHint;

  /// No description provided for @searchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search stock'**
  String get searchLabel;

  /// No description provided for @compareLabel.
  ///
  /// In en, this message translates to:
  /// **'Add comparison'**
  String get compareLabel;

  /// No description provided for @removeCompare.
  ///
  /// In en, this message translates to:
  /// **'Remove comparison'**
  String get removeCompare;

  /// No description provided for @timeRange1D.
  ///
  /// In en, this message translates to:
  /// **'1D'**
  String get timeRange1D;

  /// No description provided for @timeRange1W.
  ///
  /// In en, this message translates to:
  /// **'1W'**
  String get timeRange1W;

  /// No description provided for @timeRange1M.
  ///
  /// In en, this message translates to:
  /// **'1M'**
  String get timeRange1M;

  /// No description provided for @timeRange3M.
  ///
  /// In en, this message translates to:
  /// **'3M'**
  String get timeRange3M;

  /// No description provided for @timeRange6M.
  ///
  /// In en, this message translates to:
  /// **'6M'**
  String get timeRange6M;

  /// No description provided for @timeRange1Y.
  ///
  /// In en, this message translates to:
  /// **'1Y'**
  String get timeRange1Y;

  /// No description provided for @timeRange5Y.
  ///
  /// In en, this message translates to:
  /// **'5Y'**
  String get timeRange5Y;

  /// No description provided for @timeRangeMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get timeRangeMax;

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get noDataFound;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String searchNoResults(String query);

  /// No description provided for @loadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading data…'**
  String get loadingData;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @infoTitle.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get infoTitle;

  /// No description provided for @infoStockMonitor.
  ///
  /// In en, this message translates to:
  /// **'Stock Monitor'**
  String get infoStockMonitor;

  /// No description provided for @infoStockMonitorDesc.
  ///
  /// In en, this message translates to:
  /// **'Chart Monitor is part of Stock Monitor – the free portfolio app for desktop (Windows, Flatpak, RPM).'**
  String get infoStockMonitorDesc;

  /// No description provided for @infoStockMonitorWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website: www.stock-monitor.ch'**
  String get infoStockMonitorWebsite;

  /// No description provided for @infoLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get infoLicense;

  /// No description provided for @infoPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get infoPrivacy;

  /// No description provided for @infoPrivacyDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get infoPrivacyDecline;

  /// No description provided for @infoPrivacyAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get infoPrivacyAccept;

  /// No description provided for @infoContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get infoContact;

  /// No description provided for @infoDonate.
  ///
  /// In en, this message translates to:
  /// **'Donate'**
  String get infoDonate;

  /// No description provided for @infoDonateDesc.
  ///
  /// In en, this message translates to:
  /// **'If you enjoy the app, I appreciate your support:'**
  String get infoDonateDesc;

  /// No description provided for @donateTwint.
  ///
  /// In en, this message translates to:
  /// **'Donate via Twint'**
  String get donateTwint;

  /// No description provided for @donatePaypal.
  ///
  /// In en, this message translates to:
  /// **'Donate via PayPal'**
  String get donatePaypal;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @stock1Label.
  ///
  /// In en, this message translates to:
  /// **'Stock 1'**
  String get stock1Label;

  /// No description provided for @stock2Label.
  ///
  /// In en, this message translates to:
  /// **'Stock 2'**
  String get stock2Label;

  /// No description provided for @changePercent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String changePercent(String value);

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyTitle;

  /// No description provided for @privacyText.
  ///
  /// In en, this message translates to:
  /// **'Chart Monitor does not store any personal data. Price data is retrieved from Yahoo Finance. No data is shared with third parties.'**
  String get privacyText;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact via Email'**
  String get contactEmail;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @detailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Company Info'**
  String get detailsTitle;

  /// No description provided for @detailsCompanyInfo.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get detailsCompanyInfo;

  /// No description provided for @detailsValuation.
  ///
  /// In en, this message translates to:
  /// **'Valuation'**
  String get detailsValuation;

  /// No description provided for @detailsDividends.
  ///
  /// In en, this message translates to:
  /// **'Dividends'**
  String get detailsDividends;

  /// No description provided for @detailsDivHistory.
  ///
  /// In en, this message translates to:
  /// **'Dividend History (per year)'**
  String get detailsDivHistory;

  /// No description provided for @detailsDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get detailsDescription;

  /// No description provided for @detailsSector.
  ///
  /// In en, this message translates to:
  /// **'Sector'**
  String get detailsSector;

  /// No description provided for @detailsIndustry.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get detailsIndustry;

  /// No description provided for @detailsCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get detailsCountry;

  /// No description provided for @detailsCEO.
  ///
  /// In en, this message translates to:
  /// **'CEO'**
  String get detailsCEO;

  /// No description provided for @detailsEmployees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get detailsEmployees;

  /// No description provided for @detailsMarketCap.
  ///
  /// In en, this message translates to:
  /// **'Market Cap'**
  String get detailsMarketCap;

  /// No description provided for @details52wHigh.
  ///
  /// In en, this message translates to:
  /// **'52-W High'**
  String get details52wHigh;

  /// No description provided for @details52wLow.
  ///
  /// In en, this message translates to:
  /// **'52-W Low'**
  String get details52wLow;

  /// No description provided for @detailsNextEarnings.
  ///
  /// In en, this message translates to:
  /// **'Next Earnings'**
  String get detailsNextEarnings;

  /// No description provided for @detailsDivRate.
  ///
  /// In en, this message translates to:
  /// **'Dividend/Share'**
  String get detailsDivRate;

  /// No description provided for @detailsDivYield.
  ///
  /// In en, this message translates to:
  /// **'Dividend Yield'**
  String get detailsDivYield;

  /// No description provided for @detailsExDivDate.
  ///
  /// In en, this message translates to:
  /// **'Ex-Dividend'**
  String get detailsExDivDate;

  /// No description provided for @timeRange2Y.
  ///
  /// In en, this message translates to:
  /// **'2Y'**
  String get timeRange2Y;

  /// No description provided for @timeRangeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get timeRangeCustom;

  /// No description provided for @timeRangeMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get timeRangeMore;

  /// No description provided for @periodPerf.
  ///
  /// In en, this message translates to:
  /// **'{pct} / {abs}'**
  String periodPerf(String pct, String abs);

  /// No description provided for @customRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Select period'**
  String get customRangeTitle;

  /// No description provided for @customRangeFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get customRangeFrom;

  /// No description provided for @customRangeTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get customRangeTo;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @detailsComposition.
  ///
  /// In en, this message translates to:
  /// **'Composition'**
  String get detailsComposition;

  /// No description provided for @detailsTopHoldings.
  ///
  /// In en, this message translates to:
  /// **'Top Holdings'**
  String get detailsTopHoldings;

  /// No description provided for @detailsSectorWeights.
  ///
  /// In en, this message translates to:
  /// **'Sector Weights'**
  String get detailsSectorWeights;

  /// No description provided for @infoAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stock charts & comparison'**
  String get infoAppSubtitle;

  /// No description provided for @infoDataSource.
  ///
  /// In en, this message translates to:
  /// **'Data source: Yahoo Finance'**
  String get infoDataSource;

  /// No description provided for @fxCalcTitle.
  ///
  /// In en, this message translates to:
  /// **'FX Calculator'**
  String get fxCalcTitle;

  /// No description provided for @fxCurrencyTab.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get fxCurrencyTab;

  /// No description provided for @fxSavingsTab.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get fxSavingsTab;

  /// No description provided for @watchlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get watchlistTitle;

  /// No description provided for @watchlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'Watchlist is empty'**
  String get watchlistEmpty;

  /// No description provided for @watchlistAdd.
  ///
  /// In en, this message translates to:
  /// **'Add stock'**
  String get watchlistAdd;

  /// No description provided for @detailsNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get detailsNews;

  /// No description provided for @newsNone.
  ///
  /// In en, this message translates to:
  /// **'No news available'**
  String get newsNone;

  /// No description provided for @timeRangeYtd.
  ///
  /// In en, this message translates to:
  /// **'YTD'**
  String get timeRangeYtd;

  /// No description provided for @preMarket.
  ///
  /// In en, this message translates to:
  /// **'Pre-market'**
  String get preMarket;

  /// No description provided for @postMarket.
  ///
  /// In en, this message translates to:
  /// **'After-hours'**
  String get postMarket;

  /// No description provided for @indicatorTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get indicatorTrend;

  /// No description provided for @indicatorTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get indicatorTarget;

  /// No description provided for @wlAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Alert: {symbol}'**
  String wlAlarmTitle(String symbol);

  /// No description provided for @wlAlarmStopLoss.
  ///
  /// In en, this message translates to:
  /// **'Stop-Loss'**
  String get wlAlarmStopLoss;

  /// No description provided for @wlAlarmTarget.
  ///
  /// In en, this message translates to:
  /// **'Target Price'**
  String get wlAlarmTarget;

  /// No description provided for @wlAlarmCurrentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current: {price}'**
  String wlAlarmCurrentPrice(String price);

  /// No description provided for @wlAlarmSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get wlAlarmSave;

  /// No description provided for @wlAlarmClear.
  ///
  /// In en, this message translates to:
  /// **'Clear Alert'**
  String get wlAlarmClear;

  /// No description provided for @wlAlarmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get wlAlarmCancel;

  /// No description provided for @wlSortManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get wlSortManual;

  /// No description provided for @wlSortAZ.
  ///
  /// In en, this message translates to:
  /// **'A → Z'**
  String get wlSortAZ;

  /// No description provided for @wlSortZA.
  ///
  /// In en, this message translates to:
  /// **'Z → A'**
  String get wlSortZA;

  /// No description provided for @wlSortPerfDesc.
  ///
  /// In en, this message translates to:
  /// **'Performance ↓'**
  String get wlSortPerfDesc;

  /// No description provided for @wlSortPerfAsc.
  ///
  /// In en, this message translates to:
  /// **'Performance ↑'**
  String get wlSortPerfAsc;

  /// No description provided for @wlSortGics.
  ///
  /// In en, this message translates to:
  /// **'Sector (GICS)'**
  String get wlSortGics;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @updateAvailableDesc.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available.\n\nTap «Download» → APK downloads in browser → tap «Open» in the download notification → Install.'**
  String updateAvailableDesc(String version);

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get updateDownload;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'App is up to date (v{version})'**
  String updateUpToDate(String version);

  /// No description provided for @privacyConsentBody.
  ///
  /// In en, this message translates to:
  /// **'Chart Monitor does not store personal data. Price data is fetched live from Yahoo Finance.\n\nPlease accept our privacy policy to use the app.'**
  String get privacyConsentBody;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get noConnection;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
