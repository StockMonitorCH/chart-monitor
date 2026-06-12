import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

// ── Währungs-Konstanten ──────────────────────────────────────────────────────

const List<String> _kCurrencies = [
  'USD','CHF','EUR','GBP','JPY','CAD','AUD','CNY',
  'HKD','SEK','NOK','DKK','NZD','SGD','MXN','BRL','INR','KRW','TRY',
  'BTC','ETH','XRP','SOL',
  '─── Edelmetalle & Rohstoffe ───',
  'XAU (Gold/oz)','XAG (Silber/oz)','XPT (Platin/oz)',
  'XPD (Palladium/oz)','XCU (Kupfer/lb)',
];

const String _kSep = '─── Edelmetalle & Rohstoffe ───';

const Map<String, String> _kCrypto = {
  'BTC': 'BTC-USD', 'ETH': 'ETH-USD', 'XRP': 'XRP-USD', 'SOL': 'SOL-USD',
};

const Map<String, String> _kPrecious = {
  'XAU (Gold/oz)': 'GC=F',
  'XAG (Silber/oz)': 'SI=F',
  'XPT (Platin/oz)': 'PL=F',
  'XPD (Palladium/oz)': 'PA=F',
  'XCU (Kupfer/lb)': 'HG=F',
};

const List<List<String>> _kQuickPairs = [
  ['USD','CHF'],['CHF','USD'],
  ['EUR','CHF'],['CHF','EUR'],
  ['GBP','CHF'],['CHF','GBP'],
  ['EUR','USD'],['USD','EUR'],
  ['EUR','GBP'],['GBP','EUR'],
  ['JPY','CHF'],['CHF','JPY'],
];

// ── Yahoo Finance Kursabruf ──────────────────────────────────────────────────

Future<double?> _yahooRate(String symbol) async {
  try {
    final r = await http.get(
      Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$symbol'
          '?interval=1d&range=1d'),
      headers: {'User-Agent': 'ChartMonitor/1.0'},
    ).timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) return null;
    final j = jsonDecode(r.body);
    final price = j['chart']['result'][0]['meta']['regularMarketPrice'];
    return (price as num).toDouble();
  } catch (_) {
    return null;
  }
}

Future<(double?, String?)> _getRate(String from, String to, bool isDE) async {
  if (from == to) return (1.0, null);
  if (from == _kSep || to == _kSep) {
    return (null, isDE ? 'Trennzeile wählen' : 'Select a currency');
  }
  try {
    if (_kPrecious.containsKey(from)) {
      final usd = await _yahooRate(_kPrecious[from]!);
      if (usd == null) return (null, isDE ? 'Kurs nicht verfügbar' : 'Rate unavailable');
      if (to == 'USD') return (usd, null);
      final (r2, e) = await _getRate('USD', to, isDE);
      return r2 != null ? (usd * r2, null) : (null, e);
    }
    if (_kPrecious.containsKey(to)) {
      final usd = await _yahooRate(_kPrecious[to]!);
      if (usd == null) return (null, isDE ? 'Kurs nicht verfügbar' : 'Rate unavailable');
      if (from == 'USD') return (1.0 / usd, null);
      final (r1, e) = await _getRate(from, 'USD', isDE);
      return r1 != null ? (r1 / usd, null) : (null, e);
    }
    if (_kCrypto.containsKey(from) || _kCrypto.containsKey(to)) {
      if (_kCrypto.containsKey(from) && to == 'USD') {
        final p = await _yahooRate(_kCrypto[from]!);
        return p != null ? (p, null) : (null, isDE ? 'Kurs nicht verfügbar' : 'Rate unavailable');
      }
      if (from == 'USD' && _kCrypto.containsKey(to)) {
        final p = await _yahooRate(_kCrypto[to]!);
        return p != null ? (1.0 / p, null) : (null, isDE ? 'Kurs nicht verfügbar' : 'Rate unavailable');
      }
      final (r1, _) = await _getRate(from, 'USD', isDE);
      final (r2, _) = await _getRate('USD', to, isDE);
      if (r1 != null && r2 != null) return (r1 * r2, null);
      return (null, isDE ? 'Kurs nicht verfügbar' : 'Rate unavailable');
    }
    final p = await _yahooRate('$from$to=X');
    return p != null ? (p, null) : (null, isDE ? 'Kurs nicht verfügbar' : 'Rate unavailable');
  } catch (e) {
    return (null, e.toString());
  }
}

// ── Gemeinsames Display ──────────────────────────────────────────────────────

class _CalcDisplay extends StatelessWidget {
  final String main;
  final String sub;
  final String history;

  const _CalcDisplay({required this.main, this.sub = '', this.history = ''});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fs = main.length <= 9
        ? 32.0
        : main.length <= 14
            ? 24.0
            : 18.0;
    return SizedBox(
      height: 110,
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        color: cs.primaryContainer.withAlpha(80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (history.isNotEmpty)
              Text(history,
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withAlpha(120)),
                  textAlign: TextAlign.right),
            const Spacer(),
            Text(main,
                style: TextStyle(
                    fontSize: fs,
                    fontWeight: FontWeight.bold,
                    color: cs.primary),
                textAlign: TextAlign.right,
                maxLines: 2),
            if (sub.isNotEmpty)
              Text(sub,
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withAlpha(140)),
                  textAlign: TextAlign.right),
          ],
        ),
      ),
    );
  }
}

// ── Sheet ────────────────────────────────────────────────────────────────────

class FxCalcSheet extends StatelessWidget {
  const FxCalcSheet({super.key});

  static void show(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FxCalcSheetContent(l10n: l10n),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _FxCalcSheetContent extends StatefulWidget {
  final AppLocalizations l10n;
  const _FxCalcSheetContent({required this.l10n});

  @override
  State<_FxCalcSheetContent> createState() => _FxCalcSheetContentState();
}

class _FxCalcSheetContentState extends State<_FxCalcSheetContent>
    with SingleTickerProviderStateMixin {
  static const _kFxTab = 'fx_tab';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTab();
  }

  Future<void> _loadTab() async {
    final prefs = await SharedPreferences.getInstance();
    final tab = (prefs.getInt(_kFxTab) ?? 0).clamp(0, 1);
    if (mounted && tab != _tabController.index) {
      setState(() => _tabController.index = tab);
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      SharedPreferences.getInstance()
          .then((p) => p.setInt(_kFxTab, _tabController.index));
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _tabController.addListener(_onTabChanged);
    final l10n = widget.l10n;
    final h = MediaQuery.of(context).size.height * 0.94;
    return SizedBox(
      height: h,
      child: Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Titel (kompakt)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(l10n.fxCalcTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          // Tabs + Schliessen in einer Zeile
          Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: l10n.fxCurrencyTab),
                    Tab(text: l10n.fxSavingsTab),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CurrencyPanel(),
                _SavingsPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Währungsrechner ──────────────────────────────────────────────────────────

class _CurrencyPanel extends StatefulWidget {
  @override
  State<_CurrencyPanel> createState() => _CurrencyPanelState();
}

class _CurrencyPanelState extends State<_CurrencyPanel> {
  String _from = 'USD';
  String _to = 'CHF';
  String _input = '';
  String _result = '';
  String _rateLine = '';
  String _status = '';
  bool _loading = false;
  late bool _de;
  late String _locale;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    final from = p.getString('cm_currency_from') ?? 'USD';
    final to   = p.getString('cm_currency_to')   ?? 'CHF';
    final input = p.getString('cm_currency_input') ?? '';
    if (!mounted) return;
    setState(() { _from = from; _to = to; _input = input; });
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('cm_currency_from',  _from);
    await p.setString('cm_currency_to',    _to);
    await p.setString('cm_currency_input', _input);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = Localizations.localeOf(context).languageCode;
    _de = lang == 'de';
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    if (!_de) {
      _locale = 'en_US';
    } else if (deviceLocale.countryCode == 'CH') {
      _locale = 'de_CH';
    } else {
      _locale = 'de_DE';
    }
  }

  String _t(String de, String en) => _de ? de : en;

  String _fmt(double v, {int dec = 4}) {
    return NumberFormat.decimalPatternDigits(
        locale: _locale, decimalDigits: dec).format(v);
  }

  String get _displayText => _input.isEmpty ? '0' : _input;

  void _numBtn(String t) {
    setState(() {
      _result = '';
      if (t == 'CE') { _input = ''; } else if (t == '←') { if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1); } else if (t == '±') { _input = _input.startsWith('-') ? _input.substring(1) : (_input.isEmpty ? _input : '-$_input'); } else if (t == '.') { if (!_input.contains('.')) _input = '${_input.isEmpty ? "0" : _input}.'; } else if (_input == '0') { _input = t; } else { _input += t; }
    });
    _savePrefs();
  }

  Future<void> _convert() async {
    final amt = double.tryParse(_input);
    if (amt == null) {
      setState(() => _status = _t('Ungültiger Betrag', 'Invalid amount'));
      return;
    }
    setState(() { _loading = true; _status = _t('⚡ Lade Kursdaten…', '⚡ Loading rates…'); _rateLine = ''; });
    final (rate, err) = await _getRate(_from, _to, _de);
    if (!mounted) return;
    if (rate == null) {
      setState(() { _loading = false; _status = err ?? _t('Fehler', 'Error'); });
      return;
    }
    final converted = amt * rate;
    setState(() {
      _loading = false;
      _result = _fmt(converted, dec: converted.abs() < 1 ? 6 : 4);
      _rateLine = '1 $_from = ${_fmt(rate)} $_to';
      _status = _t('✓ Kurs aktuell (Yahoo Finance)', '✓ Rate current (Yahoo Finance)');
    });
  }

  void _swap() {
    setState(() { final t = _from; _from = _to; _to = t; _result = ''; });
    _savePrefs();
    _convert();
  }

  Widget _btn(String label, {Color? bg, Color? fg, int flex = 1}) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bg ?? cs.surfaceContainerHighest,
            foregroundColor: fg ?? cs.onSurfaceVariant,
            minimumSize: const Size(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          onPressed: () => _numBtn(label),
          child: Text(label, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildDropdownRow(ColorScheme cs) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    child: Row(
      children: [
        Expanded(child: _CurrencyDropdown(value: _from, onChanged: (v) { setState(() { _from = v; _result = ''; }); _savePrefs(); })),
        IconButton(icon: const Icon(Icons.swap_horiz), onPressed: _swap),
        Expanded(child: _CurrencyDropdown(value: _to, onChanged: (v) { setState(() { _to = v; _result = ''; }); _savePrefs(); })),
      ],
    ),
  );

  Widget _buildQuickPairs(ColorScheme cs) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('Schnellwahl', 'Quick pairs'),
            style: TextStyle(fontSize: 11, color: cs.onSurface.withAlpha(120))),
        const SizedBox(height: 4),
        Wrap(
          spacing: 5,
          runSpacing: 4,
          children: _kQuickPairs.map((p) => ActionChip(
            label: Text('${p[0]}/${p[1]}', style: const TextStyle(fontSize: 11)),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              setState(() { _from = p[0]; _to = p[1]; });
              _savePrefs();
              _convert();
            },
          )).toList(),
        ),
      ],
    ),
  );

  Widget _buildNumpad(ColorScheme cs) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(child: Row(children: [_btn('7'), _btn('8'), _btn('9')])),
              Expanded(child: Row(children: [_btn('4'), _btn('5'), _btn('6')])),
              Expanded(child: Row(children: [_btn('1'), _btn('2'), _btn('3')])),
              Expanded(child: Row(children: [
                _btn('±', bg: cs.secondaryContainer, fg: cs.onSecondaryContainer),
                _btn('0'),
                _btn('.'),
              ])),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _btn('←', bg: cs.secondaryContainer, fg: cs.onSecondaryContainer),
              _btn('CE', bg: cs.secondaryContainer, fg: cs.onSecondaryContainer),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _loading ? null : _convert,
                    child: _loading
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : const Icon(Icons.currency_exchange, size: 26),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final display = _CalcDisplay(
      main: _result.isNotEmpty ? '$_to  $_result' : _displayText,
      sub: _result.isNotEmpty
          ? '$_displayText $_from  →  $_to'
          : '$_from  →  $_to',
      history: _rateLine,
    );

    final statusWidget = _status.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(_status,
                style: TextStyle(fontSize: 11, color: cs.onSurface.withAlpha(120))),
          )
        : null;

    if (isLandscape) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Links: Display fix, darunter Dropdowns + Status + Schnellwahl scrollbar
          Expanded(
            flex: 2,
            child: Column(
              children: [
                display,
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildDropdownRow(cs),
                        ?statusWidget,
                        _buildQuickPairs(cs),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          // Rechts: Nummernpad
          Expanded(
            flex: 3,
            child: _buildNumpad(cs),
          ),
        ],
      );
    }

    // Hochformat
    return Column(
      children: [
        display,
        _buildDropdownRow(cs),
        ?statusWidget,
        Expanded(child: _buildNumpad(cs)),
        SafeArea(
          top: false, left: false, right: false,
          child: _buildQuickPairs(cs),
        ),
      ],
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  const _CurrencyDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
          isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
      items: _kCurrencies.map((c) => DropdownMenuItem(
        value: c,
        enabled: c != _kSep,
        child: Text(c,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontStyle: c == _kSep ? FontStyle.italic : null,
              color: c == _kSep ? Colors.grey : null,
              fontSize: 13,
            )),
      )).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}

// ── Zinsrechner ──────────────────────────────────────────────────────────────

class _SavingsPanel extends StatefulWidget {
  @override
  State<_SavingsPanel> createState() => _SavingsPanelState();
}

const List<String> _kFiatCurrencies = [
  'CHF','USD','EUR','GBP','JPY','CAD','AUD','CNY',
  'HKD','SEK','NOK','DKK','NZD','SGD','MXN','BRL','INR','KRW','TRY',
];

class _SavingsPanelState extends State<_SavingsPanel> {
  final _startCtrl   = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _yearsCtrl   = TextEditingController();
  final _rateCtrl    = TextEditingController();

  bool   _isWithdrawal = false;
  String _currency     = 'CHF';
  double _endWithout   = 0;
  double _endWith      = 0;
  double _totalPaid    = 0;
  double _interestGain = 0;
  double? _yearsToDepletion;

  late bool _de;
  late String _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _de = Localizations.localeOf(context).languageCode == 'de';
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    if (!_de) {
      _locale = 'en_US';
    } else if (deviceLocale.countryCode == 'CH') {
      _locale = 'de_CH';
    } else {
      _locale = 'de_DE';
    }
  }

  String _t(String de, String en) => _de ? de : en;

  @override
  void initState() {
    super.initState();
    _loadPrefs().then((_) {
      _startCtrl.addListener(_onChanged);
      _depositCtrl.addListener(_onChanged);
      _yearsCtrl.addListener(_onChanged);
      _rateCtrl.addListener(_onChanged);
      _calculate();
    });
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _startCtrl.text   = p.getString('cm_savings_start')   ?? '10000';
    _depositCtrl.text = p.getString('cm_savings_deposit') ?? '1200';
    _yearsCtrl.text   = p.getString('cm_savings_years')   ?? '20';
    _rateCtrl.text    = p.getString('cm_savings_rate')    ?? '5.0';
    if (mounted) {
      setState(() {
        _isWithdrawal = p.getBool('cm_savings_withdrawal') ?? false;
        _currency = p.getString('cm_savings_currency') ?? 'CHF';
      });
    }
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('cm_savings_start',      _startCtrl.text);
    await p.setString('cm_savings_deposit',    _depositCtrl.text);
    await p.setString('cm_savings_years',      _yearsCtrl.text);
    await p.setString('cm_savings_rate',       _rateCtrl.text);
    await p.setBool('cm_savings_withdrawal',   _isWithdrawal);
    await p.setString('cm_savings_currency',   _currency);
  }

  void _onChanged() { _savePrefs(); _calculate(); }

  @override
  void dispose() {
    _startCtrl.dispose();
    _depositCtrl.dispose();
    _yearsCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  double? _calcYearsToDepletion(double start, double wpy, double rate) {
    if (wpy <= 0 || start <= 0) return null;
    if (rate <= 0) return start / wpy;
    if (rate * start >= wpy) return null;
    final w = -wpy;
    final ratio = w / (rate * start + w);
    if (ratio <= 0) return null;
    return math.log(ratio) / math.log(1 + rate);
  }

  void _calculate() {
    final start   = double.tryParse(_startCtrl.text.replaceAll(',', '.'))   ?? 0;
    final depAmt  = double.tryParse(_depositCtrl.text.replaceAll(',', '.')) ?? 0;
    final deposit = depAmt * (_isWithdrawal ? -1 : 1);
    final years   = int.tryParse(_yearsCtrl.text)                          ?? 0;
    final rate    = (double.tryParse(_rateCtrl.text.replaceAll(',', '.'))  ?? 0) / 100;

    if (years <= 0) {
      setState(() { _endWithout = 0; _endWith = 0; _totalPaid = 0; _interestGain = 0; _yearsToDepletion = null; });
      return;
    }
    final factor = math.pow(1 + rate, years).toDouble();
    final without = start * factor;
    final withDep = rate == 0
        ? without + deposit * years
        : without + deposit * (factor - 1) / rate;
    final paid = start + deposit * years;
    setState(() {
      _endWithout       = without;
      _endWith          = withDep;
      _totalPaid        = paid;
      _interestGain     = withDep - paid;
      _yearsToDepletion = _isWithdrawal ? _calcYearsToDepletion(start, depAmt, rate) : null;
    });
  }

  String _fmt(double v) {
    if (v.abs() >= 1000000) {
      return '${NumberFormat('#,##0.##', _locale).format(v / 1000000)} Mio.';
    }
    return NumberFormat('#,##0.00', _locale).format(v);
  }

  Widget _field(String label, TextEditingController ctrl, String suffix) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final depAmt = double.tryParse(_depositCtrl.text.replaceAll(',', '.')) ?? 0;
    final yrs = int.tryParse(_yearsCtrl.text) ?? 0;
    final depleted = _isWithdrawal && _endWith <= 0 && _yearsToDepletion != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _field(_t('Startkapital', 'Initial capital'), _startCtrl, _currency)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _currency,
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        items: _kFiatCurrencies.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(fontSize: 14)),
                        )).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _currency = v);
                          _savePrefs();
                        },
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text(_t('Einzahlung', 'Deposit')),
                          icon: const Icon(Icons.add, size: 16),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(_t('Entnahme', 'Withdrawal')),
                          icon: const Icon(Icons.remove, size: 16),
                        ),
                      ],
                      selected: {_isWithdrawal},
                      onSelectionChanged: (s) =>
                          setState(() { _isWithdrawal = s.first; _savePrefs(); _calculate(); }),
                    ),
                  ),
                  _field(_t('Betrag / Jahr', 'Amount / year'), _depositCtrl, _currency),
                  _field(_t('Laufzeit', 'Duration'), _yearsCtrl, _t('Jahre', 'years')),
                  _field(_t('Zinssatz', 'Interest rate'), _rateCtrl, '%'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: cs.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t('Ergebnis', 'Result'),
                      style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer.withAlpha(160))),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        depleted
                            ? _t('Aufgebraucht nach', 'Depleted after')
                            : _isWithdrawal
                                ? _t('Mit Entnahmen', 'With withdrawals')
                                : _t('Mit Einzahlungen', 'With deposits'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      depleted
                          ? _buildDepletion(_yearsToDepletion!, cs)
                          : Text('${_fmt(_endWith)} $_currency',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.primary)),
                    ],
                  ),
                  const Divider(height: 16),
                  _row(_t('Nur Zinseszins', 'Compound interest only'), '${_fmt(_endWithout)} $_currency', cs),
                  _row(
                    _isWithdrawal
                        ? _t('− Entnahmen gesamt', '− Total withdrawals')
                        : _t('+ Einzahlungen gesamt', '+ Total deposits'),
                    _isWithdrawal
                        ? '− ${_fmt(depAmt * yrs)} $_currency'
                        : '+ ${_fmt(depAmt * yrs)} $_currency',
                    cs,
                  ),
                  const Divider(height: 12),
                  _row(
                    _isWithdrawal
                        ? _t('Entnommen total', 'Total withdrawn')
                        : _t('Eingezahlt total', 'Total paid in'),
                    '${_fmt(_totalPaid)} $_currency', cs,
                  ),
                  _row(
                    _t('Zinsgewinn total', 'Total interest gain'),
                    '${_fmt(_interestGain)} $_currency', cs,
                    valueColor: _interestGain >= 0 ? Colors.green.shade700 : Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepletion(double totalYears, ColorScheme cs) {
    final y = totalYears.floor();
    final m = ((totalYears - y) * 12).round();
    final label = m > 0 ? _t('~$y J. $m M.', '~$y yr $m mo') : _t('~$y Jahre', '~$y years');
    return Text(label,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.error));
  }

  Widget _row(String label, String value, ColorScheme cs, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer.withAlpha(180)))),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: valueColor ?? cs.onPrimaryContainer)),
        ],
      ),
    );
  }
}
