#!/usr/bin/env python3
"""
fetch_screener_data.py – Nightly screener data builder for Chart Monitor.

US stocks  (S&P 500, Nasdaq, Russell 2000, NYSE 200):
  → Finnhub  /stock/metric + /quote          60 calls/min   ~67 min
European stocks (DAX 40, SMI 20, FTSE 100):
  → Twelve Data  /quote + /statistics         8 calls/min   ~40 min
                                                 Total:   ~107 min

Output: output/screener-data.json  (uploaded to Cyon via GitHub Actions)
"""
import json
import os
import sys
import time
from datetime import datetime, timezone

import requests

# ── Credentials ──────────────────────────────────────────────────────────────
FINNHUB_KEY      = os.environ.get('FINNHUB_KEY', '')
TWELVE_DATA_KEY  = os.environ.get('TWELVE_DATA_KEY', '')

# ── Rate limits ───────────────────────────────────────────────────────────────
SLEEP_FH = 1.05   # Finnhub:     ~57 calls/min  (limit: 60)
SLEEP_TD = 7.6    # Twelve Data: ~7.9 calls/min (limit:  8)
TIMEOUT  = 15     # seconds per request

# ── Paths ─────────────────────────────────────────────────────────────────────
_DIR        = os.path.dirname(os.path.abspath(__file__))
NAMES_FILE  = os.path.join(_DIR, 'symbol_names.json')
OUTPUT_FILE = os.path.join(_DIR, '..', 'output', 'screener-data.json')

# ── Finnhub (US stocks) ───────────────────────────────────────────────────────

def _fh_get(endpoint: str, params: dict) -> dict:
    time.sleep(SLEEP_FH)
    params['token'] = FINNHUB_KEY
    r = requests.get(
        f'https://finnhub.io/api/v1/{endpoint}', params=params, timeout=TIMEOUT
    )
    r.raise_for_status()
    return r.json()


def fetch_us_stock(symbol: str, names: dict) -> dict | None:
    """Fetch price, 52-week return and PE for a US stock via Finnhub."""
    try:
        # Call 1: basic financials → 52-week return + trailing PE
        md     = _fh_get('stock/metric', {'symbol': symbol, 'metric': 'all'})
        m      = md.get('metric') or {}
        perf1y = m.get('52WeekPriceReturnDaily')
        if perf1y is None:
            return None
        perf1y = round(float(perf1y), 2)

        pe_raw = m.get('peTTM')
        pe     = None
        if pe_raw is not None:
            pe_f = float(pe_raw)
            if 0 < pe_f < 10_000:
                pe = round(pe_f, 1)

        # Call 2: current price
        q     = _fh_get('quote', {'symbol': symbol})
        price = float(q.get('c', 0) or 0)
        if price > 0:
            price = round(price, 2)

        entry: dict = {
            's': symbol,
            'n': names.get(symbol, symbol),
            'p': price,
            'r': perf1y,
        }
        if pe is not None:
            entry['pe'] = pe
        return entry

    except Exception as exc:
        print(f'  WARN  {symbol}: {exc}', file=sys.stderr)
        return None


# ── Twelve Data (European stocks) ─────────────────────────────────────────────

def _td_get(endpoint: str, params: dict) -> dict:
    time.sleep(SLEEP_TD)
    params['apikey'] = TWELVE_DATA_KEY
    r = requests.get(
        f'https://api.twelvedata.com/{endpoint}', params=params, timeout=TIMEOUT
    )
    r.raise_for_status()
    return r.json()


def _td_params(yahoo_sym: str) -> dict | None:
    """Convert Yahoo Finance symbol (e.g. SAP.DE) to Twelve Data params."""
    if yahoo_sym.endswith('.DE'):
        return {'symbol': yahoo_sym[:-3], 'exchange': 'XETRA'}
    if yahoo_sym.endswith('.SW'):
        return {'symbol': yahoo_sym[:-3], 'exchange': 'SIX'}
    if yahoo_sym.endswith('.L'):
        return {'symbol': yahoo_sym[:-2], 'exchange': 'LSE'}
    return None


def fetch_eu_stock(yahoo_sym: str) -> dict | None:
    """Fetch price, 52-week return and PE for a European stock via Twelve Data."""
    try:
        td_p = _td_params(yahoo_sym)
        if td_p is None:
            return None

        # Call 1: quote → current price + company name
        quote = _td_get('quote', td_p)
        if quote.get('status') == 'error' or 'close' not in quote:
            return None

        price = float(quote.get('close') or 0)
        name  = quote.get('name') or yahoo_sym

        # Call 2: statistics → 52-week return (decimal) + trailing PE
        stats = _td_get('statistics', td_p)
        if stats.get('status') == 'error':
            return None

        s       = stats.get('statistics') or {}
        w52_chg = (s.get('stock_price_summary') or {}).get('fifty_two_week_change')
        pe_raw  = (s.get('valuations') or {}).get('trailing_pe')

        if w52_chg is None:
            return None  # 52-week return unavailable → skip

        # Twelve Data returns this field as a decimal fraction (0.35 = +35%)
        perf1y = round(float(w52_chg) * 100, 2)

        pe = None
        if pe_raw is not None:
            pe_f = float(pe_raw)
            if 0 < pe_f < 10_000:
                pe = round(pe_f, 1)

        entry: dict = {
            's': yahoo_sym,      # keep Yahoo format as identifier (used in app)
            'n': name,
            'p': round(price, 2) if price > 0 else 0,
            'r': perf1y,
        }
        if pe is not None:
            entry['pe'] = pe
        return entry

    except Exception as exc:
        print(f'  WARN  {yahoo_sym}: {exc}', file=sys.stderr)
        return None


# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    if not FINNHUB_KEY:
        sys.exit('ERROR: FINNHUB_KEY environment variable not set')

    sys.path.insert(0, _DIR)
    from symbol_lists import INDEX_MAP, US_SYMBOLS_ORDERED, EU_SYMBOLS_ORDERED

    # Load name cache (populated by fetch_symbol_names.py weekly job)
    names: dict[str, str] = {}
    if os.path.exists(NAMES_FILE):
        with open(NAMES_FILE, encoding='utf-8') as f:
            names = json.load(f)

    data_map: dict[str, dict] = {}

    # ── Phase 1: US stocks via Finnhub ───────────────────────────────────────
    total_us = len(US_SYMBOLS_ORDERED)
    print(f'\n── US stocks: {total_us} symbols via Finnhub ──────────────────')
    for i, sym in enumerate(US_SYMBOLS_ORDERED):
        if i % 100 == 0:
            print(f'  {i}/{total_us}  ({100*i//total_us}%)')
        entry = fetch_us_stock(sym, names)
        if entry:
            data_map[sym] = entry

    ok_us = sum(1 for s in US_SYMBOLS_ORDERED if s in data_map)
    print(f'  Done: {ok_us}/{total_us} US symbols')

    # ── Phase 2: European stocks via Twelve Data ──────────────────────────────
    if TWELVE_DATA_KEY and EU_SYMBOLS_ORDERED:
        total_eu = len(EU_SYMBOLS_ORDERED)
        print(f'\n── European stocks: {total_eu} symbols via Twelve Data ─────')
        for i, sym in enumerate(EU_SYMBOLS_ORDERED):
            if i % 30 == 0:
                print(f'  {i}/{total_eu}  ({100*i//total_eu}%)')
            entry = fetch_eu_stock(sym)
            if entry:
                data_map[sym] = entry

        ok_eu = sum(1 for s in EU_SYMBOLS_ORDERED if s in data_map)
        print(f'  Done: {ok_eu}/{total_eu} European symbols')
    else:
        if not TWELVE_DATA_KEY:
            print('\nINFO: TWELVE_DATA_KEY not set – skipping European stocks')

    # ── Build output JSON ─────────────────────────────────────────────────────
    output = {
        'generated_at': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
        'data': {
            key: [data_map[s] for s in syms if s in data_map]
            for key, syms in INDEX_MAP.items()
        },
    }

    os.makedirs(os.path.dirname(os.path.abspath(OUTPUT_FILE)), exist_ok=True)
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(output, f, separators=(',', ':'))

    kb      = os.path.getsize(OUTPUT_FILE) / 1024
    entries = sum(len(v) for v in output['data'].values())
    print(f'\nOutput: {OUTPUT_FILE}  ({kb:.0f} KB, {entries} entries total)')


if __name__ == '__main__':
    main()
