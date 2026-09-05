#!/usr/bin/env python3
"""
fetch_symbol_names.py – Builds / updates the company-name cache.
Fetches company names from Finnhub /stock/profile2 for all screener symbols.
Runs weekly via GitHub Actions; result is committed back to the repo.

Only fetches names for symbols not already in symbol_names.json,
so subsequent weekly runs are very fast (only new symbols need fetching).
"""
import json
import os
import sys
import time

import requests

FINNHUB_KEY = os.environ.get('FINNHUB_KEY', '')
BASE    = 'https://finnhub.io/api/v1'
SLEEP   = 1.05
TIMEOUT = 15

_DIR       = os.path.dirname(os.path.abspath(__file__))
NAMES_FILE = os.path.join(_DIR, 'symbol_names.json')


def fetch_name(symbol: str) -> str:
    time.sleep(SLEEP)
    try:
        r = requests.get(
            f'{BASE}/stock/profile2',
            params={'symbol': symbol, 'token': FINNHUB_KEY},
            timeout=TIMEOUT,
        )
        data = r.json()
        return data.get('name') or symbol
    except Exception as exc:
        print(f'  WARN  {symbol}: {exc}', file=sys.stderr)
        return symbol


def main() -> None:
    if not FINNHUB_KEY:
        sys.exit('ERROR: FINNHUB_KEY environment variable not set')

    sys.path.insert(0, _DIR)
    from symbol_lists import US_SYMBOLS_ORDERED

    names: dict[str, str] = {}
    if os.path.exists(NAMES_FILE):
        with open(NAMES_FILE, encoding='utf-8') as f:
            names = json.load(f)

    # Only fetch names for US symbols — EU names come directly from Twelve Data /quote
    missing = [s for s in US_SYMBOLS_ORDERED if s not in names]
    total   = len(US_SYMBOLS_ORDERED)
    print(f'Total symbols: {total}  |  Already cached: {total - len(missing)}  |  To fetch: {len(missing)}')

    for i, sym in enumerate(missing):
        if i % 50 == 0:
            print(f'  {i}/{len(missing)}')
        names[sym] = fetch_name(sym)

    with open(NAMES_FILE, 'w', encoding='utf-8') as f:
        json.dump(names, f, sort_keys=True, indent=2, ensure_ascii=False)

    print(f'Done. symbol_names.json now contains {len(names)} entries.')


if __name__ == '__main__':
    main()
