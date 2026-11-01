# Changelog

All notable changes to Chart Monitor are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [2.7.0] – 2026-11-01

### Added
- Screener: 10 new indices – CAC 40, Nikkei 225, TSX, ASX 200, STI, Nifty 50, Hang Seng, EWZ Brazil, Scandinavia, Eastern Europe (18 indices total)

### Fixed
- Candlestick 1W: time axis now shows weekday names (Mon–Fri / Mo–Fr) instead of HH:mm timestamps
- Candlestick 1W: each trading day gets exactly one label (Wednesday was previously skipped)
- Candlestick 1W: weekday names follow device language (locale-aware)

---

## [2.6.3] – 2026-10-15

### Fixed
- iOS: keyboard pushes up UI correctly on real iPhones
- iOS: search suggestions display fixed on real devices

---

## [2.6.1] – 2026-09-10

### Changed
- Privacy policy updated: stock-monitor.ch added as screener data source

### Fixed
- Screener: US stocks with price 0 (delisted) excluded from results

---

## [2.6.0] – 2026-09-06

### Changed
- Screener completely reworked: data pre-computed nightly and fetched from stock-monitor.ch – no live API call from the app, Huawei-compatible
- Screener now includes DAX 40 (XETRA), SMI 20 (SIX), FTSE 100 (LSE) in addition to US indices
- Instant filtering: screener results appear without delay

---

## [2.5.0] – 2026-09-04

### Changed
- Screener migrated to pre-computed JSON data (internal milestone before 2.6.0 release)

---

## [2.4.0] – 2026-08-16

### Added
- Stock Screener: filter by 1-year performance (10% steps) and optional max. P/E ratio
- AND/OR logic to combine performance and P/E filters
- Universe selector: S&P 500, +NASDAQ 100, +Extended (~700 stocks incl. AI, quantum, EV, biotech, crypto)
- Up to 50 results sorted by performance (descending)
- Open chart or add to watchlist directly from results

---

## [2.3.0] – 2026-07-11

### Added
- Stock rating with 5-star system and 6 categories (performance, risk, fundamental, technical, tradability, analyst rating)
- Rating based on MAs, Bollinger Bands, RSI, beta, Sharpe ratio, alpha, dividend yield
- Analyst consensus: buy/hold/sell distribution with analyst count

---

## [2.2.0] – 2026-06-28

### Added
- Pre-market and post-market prices
- Analyst ratings (buy/hold/sell consensus)
- Custom date range selector
- Finance calculator (TVM, amortization, cash flow, interest conversion, break-even)
- Bollinger Bands indicator

### Fixed
- Analyst consensus always calculated from weighted average
- Analyst count derived from sum of individual values

---

## [2.1.0] – 2026-06-22

### Added
- Bollinger Bands on charts
- Index overview (SMI, DAX, S&P 500, NASDAQ and more)
- Notes per stock
- Index comparison chart
- MA lines (MA20, MA50, MA200) and trend line on candlestick chart

---

## [2.0.0] – 2026-06-10

### Added
- Initial release
- Stock chart display with time ranges: 1D, 1W, 1M, 3M, 6M, YTD, 1Y, 2Y, 5Y, Max
- Candlestick chart view
- Compare two stocks (percentage-normalized)
- Search by ISIN, ticker, or company name (Yahoo Finance)
- Watchlist with price alerts (stop-loss, target price)
- Auto-update check via GitHub Releases
- DE/EN language, dark theme, full persistence
- Supports Android 5.0+ (API 21)
