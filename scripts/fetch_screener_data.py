#!/usr/bin/env python3
"""
fetch_screener_data.py – Nightly screener data builder for Chart Monitor.

US stocks  (S&P 500, Nasdaq, Russell 2000, NYSE 200):
  → Finnhub  /stock/metric + /quote          60 calls/min   ~67 min

European stocks (DAX 40, SMI 20, FTSE 100):
  → yfinance (Yahoo Finance)                  free, ~2 min

Output: output/screener-data.json  (uploaded to Cyon via GitHub Actions)
"""
import json
import os
import sys
import time
from datetime import datetime, timezone

import requests
import yfinance as yf

# ── Credentials ──────────────────────────────────────────────────────────────
FINNHUB_KEY = os.environ.get('FINNHUB_KEY', '')

# ── Rate limits ───────────────────────────────────────────────────────────────
SLEEP_FH = 1.05   # Finnhub:   ~57 calls/min (limit: 60)
SLEEP_YF = 0.3    # yfinance:  gentle throttle for Yahoo Finance
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


# ── yfinance (European stocks) ────────────────────────────────────────────────

def fetch_eu_stock(yahoo_sym: str) -> dict | None:
    """Fetch price, 52-week return and PE for a European stock via yfinance."""
    try:
        time.sleep(SLEEP_YF)
        t    = yf.Ticker(yahoo_sym)
        info = t.info

        price = info.get('regularMarketPrice') or info.get('currentPrice') or info.get('previousClose')
        if not price:
            return None
        price = round(float(price), 2)

        perf1y_dec = info.get('52WeekChange')
        if perf1y_dec is None:
            return None
        perf1y = round(float(perf1y_dec) * 100, 2)

        name = info.get('shortName') or info.get('longName') or yahoo_sym

        pe = None
        pe_raw = info.get('trailingPE')
        if pe_raw is not None:
            pe_f = float(pe_raw)
            if 0 < pe_f < 10_000:
                pe = round(pe_f, 1)

        entry: dict = {
            's': yahoo_sym,
            'n': name,
            'p': price,
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

    # ── Phase 2: European stocks via yfinance ─────────────────────────────────
    total_eu = len(EU_SYMBOLS_ORDERED)
    print(f'\n── European stocks: {total_eu} symbols via yfinance ────────────')
    for i, sym in enumerate(EU_SYMBOLS_ORDERED):
        if i % 30 == 0:
            print(f'  {i}/{total_eu}  ({100*i//total_eu}%)')
        entry = fetch_eu_stock(sym)
        if entry:
            data_map[sym] = entry

    ok_eu = sum(1 for s in EU_SYMBOLS_ORDERED if s in data_map)
    print(f'  Done: {ok_eu}/{total_eu} European symbols')

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
