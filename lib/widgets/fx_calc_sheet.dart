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
    _tabController = TabController(length: 3, vsync: this);
    _loadTab();
  }

  Future<void> _loadTab() async {
    final prefs = await SharedPreferences.getInstance();
    final tab = (prefs.getInt(_kFxTab) ?? 0).clamp(0, 2);
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
          // Tabs + Schliessen
          Stack(
            alignment: Alignment.centerRight,
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: l10n.fxCurrencyTab),
                  Tab(text: l10n.fxSavingsTab),
                  Tab(text: l10n.fxFinanceTab),
                ],
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
                _FinancePanel(),
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


// ── Hilfs-Funktionen ────────────────────────────────────────────────────────

int _calcNeededDecimals(double v, {int max = 10}) {
  if (v == v.truncateToDouble()) return 0;
  final s = v.toStringAsPrecision(12);
  if (s.contains('e') || s.contains('E')) return max;
  final dot = s.indexOf('.');
  if (dot < 0) return 0;
  final dec = s.substring(dot + 1);
  int n = dec.length;
  while (n > 0 && dec[n - 1] == '0') { n--; }
  return math.min(n, max);
}

// ── Finanz Panel (TVM / Amort / Cash / Conv / B/E) ───────────────────────────

enum _FinMode { tvm, amort, cash, conv, breakeven }
enum _TvmField { n, i, pv, pmt, fv }

class _FinancePanel extends StatefulWidget {
  @override
  State<_FinancePanel> createState() => _FinancePanelState();
}

class _FinancePanelState extends State<_FinancePanel> {
  _FinMode _mode = _FinMode.tvm;

  final _nCtrl   = TextEditingController();
  final _iCtrl   = TextEditingController();
  final _pvCtrl  = TextEditingController();
  final _pmtCtrl = TextEditingController();
  final _fvCtrl  = TextEditingController();
  bool _bgn = false;
  String _tvmResult = '';
  String _tvmError  = '';

  final _amortFromCtrl = TextEditingController(text: '1');
  final _amortToCtrl   = TextEditingController(text: '1');
  String _amortResult  = '';

  final List<TextEditingController> _cfCtrls = [
    TextEditingController(text: '0'),
    TextEditingController(text: '0'),
  ];
  final _npvRateCtrl = TextEditingController();
  String _cashResult = '';
  String _cashError  = '';

  final _nomCtrl = TextEditingController();
  final _effCtrl = TextEditingController();
  final _mCtrl   = TextEditingController(text: '12');
  String _convResult = '';

  final _fcCtrl = TextEditingController();
  final _vcCtrl = TextEditingController();
  final _prCtrl = TextEditingController();
  String _beResult = '';

  late bool _de;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _de = Localizations.localeOf(context).languageCode == 'de';
  }

  String _t(String de, String en) => _de ? de : en;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _nCtrl.text   = p.getString('cm_fin_n')   ?? '';
      _iCtrl.text   = p.getString('cm_fin_i')   ?? '';
      _pvCtrl.text  = p.getString('cm_fin_pv')  ?? '';
      _pmtCtrl.text = p.getString('cm_fin_pmt') ?? '';
      _fvCtrl.text  = p.getString('cm_fin_fv')  ?? '';
      _bgn = p.getBool('cm_fin_bgn') ?? false;
      _amortFromCtrl.text = p.getString('cm_fin_amort_from') ?? '1';
      _amortToCtrl.text   = p.getString('cm_fin_amort_to')   ?? '1';
      _npvRateCtrl.text   = p.getString('cm_fin_npv_rate')   ?? '';
      _nomCtrl.text = p.getString('cm_fin_nom') ?? '';
      _effCtrl.text = p.getString('cm_fin_eff') ?? '';
      _mCtrl.text   = p.getString('cm_fin_m')   ?? '12';
      _fcCtrl.text  = p.getString('cm_fin_fc')  ?? '';
      _vcCtrl.text  = p.getString('cm_fin_vc')  ?? '';
      _prCtrl.text  = p.getString('cm_fin_pr')  ?? '';
      final cfCount = p.getInt('cm_fin_cf_count') ?? 2;
      while (_cfCtrls.length < cfCount) {
        _cfCtrls.add(TextEditingController(text: '0'));
      }
      for (int i = 0; i < _cfCtrls.length; i++) {
        _cfCtrls[i].text = p.getString('cm_fin_cf_$i') ?? '0';
      }
    });
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('cm_fin_n',   _nCtrl.text);
    await p.setString('cm_fin_i',   _iCtrl.text);
    await p.setString('cm_fin_pv',  _pvCtrl.text);
    await p.setString('cm_fin_pmt', _pmtCtrl.text);
    await p.setString('cm_fin_fv',  _fvCtrl.text);
    await p.setBool('cm_fin_bgn', _bgn);
    await p.setString('cm_fin_amort_from', _amortFromCtrl.text);
    await p.setString('cm_fin_amort_to',   _amortToCtrl.text);
    await p.setString('cm_fin_npv_rate',   _npvRateCtrl.text);
    await p.setString('cm_fin_nom', _nomCtrl.text);
    await p.setString('cm_fin_eff', _effCtrl.text);
    await p.setString('cm_fin_m',   _mCtrl.text);
    await p.setString('cm_fin_fc',  _fcCtrl.text);
    await p.setString('cm_fin_vc',  _vcCtrl.text);
    await p.setString('cm_fin_pr',  _prCtrl.text);
    await p.setInt('cm_fin_cf_count', _cfCtrls.length);
    for (int i = 0; i < _cfCtrls.length; i++) {
      await p.setString('cm_fin_cf_$i', _cfCtrls[i].text);
    }
  }

  @override
  void dispose() {
    _nCtrl.dispose(); _iCtrl.dispose(); _pvCtrl.dispose();
    _pmtCtrl.dispose(); _fvCtrl.dispose();
    _amortFromCtrl.dispose(); _amortToCtrl.dispose();
    for (final c in _cfCtrls) { c.dispose(); }
    _npvRateCtrl.dispose();
    _nomCtrl.dispose(); _effCtrl.dispose(); _mCtrl.dispose();
    _fcCtrl.dispose(); _vcCtrl.dispose(); _prCtrl.dispose();
    super.dispose();
  }

  // ── TVM Mathematik ──────────────────────────────────────────────────────────

  double _tvmEq(double n, double r, double pv, double pmt, double fv) {
    if (r.abs() < 1e-12) return pv + pmt * n + fv;
    final x = math.pow(1 + r, n).toDouble();
    final f = _bgn ? (1 + r) : 1.0;
    return pv * x + pmt * f * (x - 1) / r + fv;
  }

  void _solveTVM(_TvmField field) {
    setState(() { _tvmError = ''; _tvmResult = ''; });
    final vals = {
      _TvmField.n:   _parseNum(_nCtrl.text),
      _TvmField.i:   _parseNum(_iCtrl.text),
      _TvmField.pv:  _parseNum(_pvCtrl.text),
      _TvmField.pmt: _parseNum(_pmtCtrl.text),
      _TvmField.fv:  _parseNum(_fvCtrl.text),
    };
    vals.remove(field);
    if (vals.values.any((v) => v == null)) {
      setState(() => _tvmError = _t('Bitte die anderen 4 Felder ausfüllen', 'Please fill the other 4 fields'));
      return;
    }
    final n   = vals[_TvmField.n]!;
    final i   = vals[_TvmField.i];
    final pv  = vals[_TvmField.pv];
    final pmt = vals[_TvmField.pmt];
    final fv  = vals[_TvmField.fv];
    double result;
    try {
      result = switch (field) {
        _TvmField.n   => _solveN(i! / 100, pv!, pmt!, fv!),
        _TvmField.i   => _solveI(n, pv!, pmt!, fv!) * 100,
        _TvmField.pv  => _solvePV(n, i! / 100, pmt!, fv!),
        _TvmField.pmt => _solvePMT(n, i! / 100, pv!, fv!),
        _TvmField.fv  => _solveFV(n, i! / 100, pv!, pmt!),
      };
    } catch (_) {
      setState(() => _tvmError = _t('Keine Lösung gefunden', 'No solution found'));
      return;
    }
    if (!result.isFinite) {
      setState(() => _tvmError = _t('Keine Lösung gefunden', 'No solution found'));
      return;
    }
    final label = switch (field) {
      _TvmField.n   => 'N',
      _TvmField.i   => 'I%',
      _TvmField.pv  => _t('BW', 'PV'),
      _TvmField.pmt => _t('Rate', 'PMT'),
      _TvmField.fv  => _t('EW', 'FV'),
    };
    final dec = _calcNeededDecimals(result);
    final fmt = NumberFormat.decimalPatternDigits(locale: _de ? 'de_CH' : 'en_US', decimalDigits: dec);
    setState(() {
      _tvmResult = '$label = ${fmt.format(result)}';
      switch (field) {
        case _TvmField.n:   _nCtrl.text   = _fmtInput(result);
        case _TvmField.i:   _iCtrl.text   = _fmtInput(result);
        case _TvmField.pv:  _pvCtrl.text  = _fmtInput(result);
        case _TvmField.pmt: _pmtCtrl.text = _fmtInput(result);
        case _TvmField.fv:  _fvCtrl.text  = _fmtInput(result);
      }
    });
    _savePrefs();
  }

  double _solvePV(double n, double r, double pmt, double fv) {
    if (r.abs() < 1e-12) return -(pmt * n + fv);
    final x = math.pow(1 + r, n).toDouble();
    final f = _bgn ? (1 + r) : 1.0;
    return -(pmt * f * (x - 1) / r + fv) / x;
  }

  double _solveFV(double n, double r, double pv, double pmt) {
    if (r.abs() < 1e-12) return -(pv + pmt * n);
    final x = math.pow(1 + r, n).toDouble();
    final f = _bgn ? (1 + r) : 1.0;
    return -(pv * x + pmt * f * (x - 1) / r);
  }

  double _solvePMT(double n, double r, double pv, double fv) {
    if (r.abs() < 1e-12) { if (n == 0) throw Exception(); return -(pv + fv) / n; }
    final x = math.pow(1 + r, n).toDouble();
    final f = _bgn ? (1 + r) : 1.0;
    return -(pv * x + fv) * r / ((x - 1) * f);
  }

  double _solveN(double r, double pv, double pmt, double fv) {
    if (pmt == 0) {
      if (r.abs() < 1e-12 || fv / pv >= 0) throw Exception();
      return math.log(-fv / pv) / math.log(1 + r);
    }
    if (r.abs() < 1e-12) return -(pv + fv) / pmt;
    final f = _bgn ? (1 + r) : 1.0;
    final num = f * pmt - fv * r;
    final den = f * pmt + pv * r;
    if (num <= 0 || den <= 0) throw Exception();
    return math.log(num / den) / math.log(1 + r);
  }

  double _solveI(double n, double pv, double pmt, double fv) {
    double r = (pmt != 0) ? 0.1 : math.pow(-fv / pv, 1 / n).toDouble() - 1;
    r = r.clamp(-0.999, 10.0);
    for (int k = 0; k < 200; k++) {
      final fr = _tvmEq(n, r, pv, pmt, fv);
      final eps = math.max(r.abs() * 1e-6, 1e-8);
      final fp = (_tvmEq(n, r + eps, pv, pmt, fv) - _tvmEq(n, r - eps, pv, pmt, fv)) / (2 * eps);
      if (fp.abs() < 1e-15) break;
      final step = (fr / fp).clamp(-0.5, 0.5);
      r = (r - step).clamp(-0.999, 100.0);
      if (step.abs() < 1e-12) break;
    }
    return r;
  }

  void _computeAmort() {
    final n   = _parseNum(_nCtrl.text);
    final i   = _parseNum(_iCtrl.text);
    final pv  = _parseNum(_pvCtrl.text);
    final pmt = _parseNum(_pmtCtrl.text);
    if (n == null || i == null || pv == null || pmt == null) {
      setState(() => _amortResult = _t('TVM-Werte (N, I%, BW, Rate) fehlen', 'TVM values (N, I%, PV, PMT) missing'));
      return;
    }
    final from = math.max(1, int.tryParse(_amortFromCtrl.text) ?? 1);
    final to   = math.min(n.toInt(), int.tryParse(_amortToCtrl.text) ?? 1);
    if (from > to) { setState(() => _amortResult = _t('Von > Bis', 'From > To')); return; }
    final r = i / 100;
    double balance = pv;
    for (int k = 1; k < from; k++) { balance = balance * (1 + r) + pmt; }
    double totalInt = 0, totalPrin = 0;
    for (int k = from; k <= to; k++) {
      final interest  = balance * r;
      final principal = -(pmt + interest);
      totalInt  += interest;
      totalPrin += principal;
      balance    = balance * (1 + r) + pmt;
    }
    setState(() {
      _amortResult =
          '${_t("Zinsen", "Interest")}: ${_fmtC(totalInt)}\n'
          '${_t("Tilgung", "Principal")}: ${_fmtC(totalPrin)}\n'
          '${_t("Saldo", "Balance")}: ${_fmtC(balance)}';
    });
    _savePrefs();
  }

  void _computeNPV() {
    final r = _parseNum(_npvRateCtrl.text);
    if (r == null) { setState(() { _cashError = _t('Zinssatz fehlt', 'Rate missing'); _cashResult = ''; }); return; }
    double npv = 0;
    for (int i = 0; i < _cfCtrls.length; i++) {
      npv += (_parseNum(_cfCtrls[i].text) ?? 0) / math.pow(1 + r / 100, i);
    }
    setState(() { _cashError = ''; _cashResult = 'NPV = ${_fmtC(npv)}'; });
    _savePrefs();
  }

  void _computeIRR() {
    final cfs = _cfCtrls.map((c) => _parseNum(c.text) ?? 0.0).toList();
    if (cfs.isEmpty || cfs[0] >= 0) {
      setState(() { _cashError = _t('CF0 muss negativ sein (Investition)', 'CF0 must be negative (investment)'); _cashResult = ''; });
      return;
    }
    double npvAt(double r) {
      double s = 0;
      for (int i = 0; i < cfs.length; i++) { s += cfs[i] / math.pow(1 + r, i); }
      return s;
    }
    double lo = -0.999, hi = 10.0;
    if (npvAt(lo) * npvAt(hi) > 0) {
      setState(() { _cashError = _t('Kein IRR gefunden', 'No IRR found'); _cashResult = ''; });
      return;
    }
    for (int k = 0; k < 100; k++) {
      final mid = (lo + hi) / 2;
      if (npvAt(lo) * npvAt(mid) <= 0) { hi = mid; } else { lo = mid; }
      if ((hi - lo) < 1e-10) { break; }
    }
    setState(() { _cashError = ''; _cashResult = 'IRR = ${_fmtC((lo + hi) / 2 * 100)} %'; });
    _savePrefs();
  }

  void _convNomToEff() {
    final nom = _parseNum(_nomCtrl.text);
    final m   = _parseNum(_mCtrl.text);
    if (nom == null || m == null || m == 0) return;
    final eff = (math.pow(1 + nom / 100 / m, m).toDouble() - 1) * 100;
    setState(() { _effCtrl.text = _fmtInput(eff); _convResult = '${_t("Effektivzins", "Effective Rate")}: ${_fmtInput(eff)} %'; });
    _savePrefs();
  }

  void _convEffToNom() {
    final eff = _parseNum(_effCtrl.text);
    final m   = _parseNum(_mCtrl.text);
    if (eff == null || m == null || m == 0) return;
    final nom = m * (math.pow(1 + eff / 100, 1 / m) - 1) * 100;
    setState(() { _nomCtrl.text = _fmtInput(nom); _convResult = '${_t("Nominalzins", "Nominal Rate")}: ${_fmtInput(nom)} %'; });
    _savePrefs();
  }

  void _computeBreakEven() {
    final fc = _parseNum(_fcCtrl.text);
    final vc = _parseNum(_vcCtrl.text);
    final pr = _parseNum(_prCtrl.text);
    if (fc == null || vc == null || pr == null) return;
    final margin = pr - vc;
    if (margin <= 0) {
      setState(() => _beResult = _t('Preis ≤ Var.kosten → kein Break-Even', 'Price ≤ Var.cost → no break-even'));
      return;
    }
    final bepUnits = fc / margin;
    final bepRev   = bepUnits * pr;
    setState(() {
      _beResult =
          '${_t("BEP Menge", "BEP Units")}: ${_fmtInput(bepUnits)}\n'
          '${_t("BEP Umsatz", "BEP Revenue")}: ${_fmtC(bepRev)}\n'
          '${_t("Deckungsbeitrag/Stück", "Contrib. margin/unit")}: ${_fmtC(margin)}';
    });
    _savePrefs();
  }

  double? _parseNum(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.').replaceAll("'", ''));

  String _fmtInput(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(8).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  String _fmtC(double v) => NumberFormat('#,##0.00', _de ? 'de_CH' : 'en_US').format(v);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Row(
            children: [
              _modeChip(_FinMode.tvm,       'TVM',                              cs),
              _modeChip(_FinMode.amort,     _t('Amort', 'Amort'),               cs),
              _modeChip(_FinMode.cash,      _t('Cashflow', 'Cash'),             cs),
              _modeChip(_FinMode.conv,      _t('Konv', 'Conv'),                 cs),
              _modeChip(_FinMode.breakeven, _t('Break-Even', 'B/E'),            cs),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
            child: switch (_mode) {
              _FinMode.tvm       => _buildTVM(cs),
              _FinMode.amort     => _buildAmort(cs),
              _FinMode.cash      => _buildCash(cs),
              _FinMode.conv      => _buildConv(cs),
              _FinMode.breakeven => _buildBE(cs),
            },
          ),
        ),
      ],
    );
  }

  Widget _modeChip(_FinMode m, String label, ColorScheme cs) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      selected: _mode == m,
      onSelected: (_) => setState(() => _mode = m),
    ),
  );

  Widget _tvmRow(String label, String hint, TextEditingController ctrl, _TvmField field, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.primary)),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (_) => _savePrefs(),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 68,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _solveTVM(field),
              child: Text(_t('Lös.', 'Solve'), style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultBox(String text, ColorScheme cs) => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)),
    child: Text(text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer),
        textAlign: TextAlign.center),
  );

  Widget _buildTVM(ColorScheme cs) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(_t('Zeitwert des Geldes', 'Time Value of Money'),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.primary),
          textAlign: TextAlign.center),
      const SizedBox(height: 6),
      _tvmRow('N',               _t('Perioden', 'Periods'),            _nCtrl,   _TvmField.n,   cs),
      _tvmRow('I%',              _t('Zins/Periode %', 'Rate/Period %'), _iCtrl,   _TvmField.i,   cs),
      _tvmRow(_t('BW', 'PV'),    _t('Barwert', 'Present Value'),       _pvCtrl,  _TvmField.pv,  cs),
      _tvmRow(_t('Rate', 'PMT'), _t('Zahlung/Periode', 'Payment/Period'), _pmtCtrl, _TvmField.pmt, cs),
      _tvmRow(_t('EW', 'FV'),    _t('Endwert', 'Future Value'),        _fvCtrl,  _TvmField.fv,  cs),
      const SizedBox(height: 8),
      Row(
        children: [
          Text(_t('Zahlung: ', 'Payment: '), style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(_t('Ende', 'End'))),
              ButtonSegment(value: true,  label: Text(_t('Anfang', 'Beg'))),
            ],
            selected: {_bgn},
            onSelectionChanged: (s) { setState(() => _bgn = s.first); _savePrefs(); },
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size(60, 32)),
              textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
      if (_tvmResult.isNotEmpty) _resultBox(_tvmResult, cs),
      if (_tvmError.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_tvmError, style: TextStyle(color: cs.error), textAlign: TextAlign.center),
        ),
      const SizedBox(height: 10),
      Text(
        _t(
          '4 Felder ausfüllen → «Lös.» beim gesuchten Feld.\nVorzeichen: Eingang positiv, Ausgang negativ.',
          'Fill 4 fields → tap «Solve» on the unknown field.\nSign: inflow positive, outflow negative.',
        ),
        style: TextStyle(fontSize: 11, color: cs.onSurface.withAlpha(120)),
      ),
    ],
  );

  Widget _buildAmort(ColorScheme cs) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(_t('Amortisation', 'Amortization'),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.primary),
          textAlign: TextAlign.center),
      Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 10),
        child: Text(_t('Verwendet TVM-Werte (N, I%, BW, Rate)', 'Uses TVM values (N, I%, PV, PMT)'),
            style: TextStyle(fontSize: 11, color: cs.onSurface.withAlpha(140)),
            textAlign: TextAlign.center),
      ),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _amortFromCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _t('Von Periode', 'From Period'),
                border: const OutlineInputBorder(), isDense: true,
              ),
              onChanged: (_) => _savePrefs(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _amortToCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _t('Bis Periode', 'To Period'),
                border: const OutlineInputBorder(), isDense: true,
              ),
              onChanged: (_) => _savePrefs(),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      ElevatedButton(
        onPressed: _computeAmort,
        style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
        child: Text(_t('Berechnen', 'Calculate')),
      ),
      if (_amortResult.isNotEmpty) _resultBox(_amortResult, cs),
    ],
  );

  Widget _buildCash(ColorScheme cs) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(_t('Cashflow – NPV / IRR', 'Cash Flow – NPV / IRR'),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.primary),
          textAlign: TextAlign.center),
      const SizedBox(height: 8),
      ...List.generate(_cfCtrls.length, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(width: 44, child: Text('CF$i', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary))),
            Expanded(
              child: TextField(
                controller: _cfCtrls[i],
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  hintText: i == 0 ? _t('Investition (neg.)', 'Investment (neg.)') : '0',
                ),
                onChanged: (_) { setState(() {}); _savePrefs(); },
              ),
            ),
            if (i >= 2)
              IconButton(
                icon: Icon(Icons.remove_circle_outline, color: cs.error, size: 20),
                onPressed: () { setState(() { _cfCtrls[i].dispose(); _cfCtrls.removeAt(i); }); _savePrefs(); },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
          ],
        ),
      )),
      TextButton.icon(
        icon: const Icon(Icons.add, size: 18),
        label: Text(_t('CF hinzufügen', 'Add CF'), style: const TextStyle(fontSize: 13)),
        onPressed: () => setState(() => _cfCtrls.add(TextEditingController(text: '0'))),
      ),
      const SizedBox(height: 4),
      TextField(
        controller: _npvRateCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: _t('Zinssatz % (für NPV)', 'Rate % (for NPV)'),
          border: const OutlineInputBorder(), isDense: true,
        ),
        onChanged: (_) => _savePrefs(),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _computeNPV,
              style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
              child: const Text('NPV'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: _computeIRR,
              style: ElevatedButton.styleFrom(backgroundColor: cs.secondary, foregroundColor: cs.onSecondary),
              child: const Text('IRR'),
            ),
          ),
        ],
      ),
      if (_cashResult.isNotEmpty) _resultBox(_cashResult, cs),
      if (_cashError.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(_cashError, style: TextStyle(color: cs.error), textAlign: TextAlign.center),
        ),
    ],
  );

  Widget _buildConv(ColorScheme cs) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(_t('Zinskonversion', 'Interest Conversion'),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.primary),
          textAlign: TextAlign.center),
      const SizedBox(height: 12),
      TextField(
        controller: _mCtrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: _t('Perioden/Jahr (m)', 'Periods/Year (m)'),
          helperText: _t('12 = monatlich · 4 = vierteljährlich · 1 = jährlich', '12 = monthly · 4 = quarterly · 1 = annual'),
          border: const OutlineInputBorder(), isDense: true,
        ),
        onChanged: (_) => _savePrefs(),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _nomCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: _t('Nominalzins %', 'Nominal Rate %'),
          border: const OutlineInputBorder(), isDense: true,
        ),
        onChanged: (_) => _savePrefs(),
      ),
      const SizedBox(height: 4),
      ElevatedButton(
        onPressed: _convNomToEff,
        style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
        child: Text(_t('→ Effektivzins', '→ Effective Rate')),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _effCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: _t('Effektivzins %', 'Effective Rate %'),
          border: const OutlineInputBorder(), isDense: true,
        ),
        onChanged: (_) => _savePrefs(),
      ),
      const SizedBox(height: 4),
      ElevatedButton(
        onPressed: _convEffToNom,
        style: ElevatedButton.styleFrom(backgroundColor: cs.secondary, foregroundColor: cs.onSecondary),
        child: Text(_t('→ Nominalzins', '→ Nominal Rate')),
      ),
      if (_convResult.isNotEmpty) _resultBox(_convResult, cs),
    ],
  );

  Widget _buildBE(ColorScheme cs) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(_t('Break-Even', 'Break-Even'),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.primary),
          textAlign: TextAlign.center),
      const SizedBox(height: 12),
      _beField(_t('Fixkosten', 'Fixed Costs'), _fcCtrl),
      _beField(_t('Variable Kosten/Stück', 'Variable Cost/Unit'), _vcCtrl),
      _beField(_t('Verkaufspreis/Stück', 'Selling Price/Unit'), _prCtrl),
      const SizedBox(height: 4),
      ElevatedButton(
        onPressed: _computeBreakEven,
        style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary),
        child: Text(_t('Berechnen', 'Calculate')),
      ),
      if (_beResult.isNotEmpty) _resultBox(_beResult, Theme.of(context).colorScheme),
    ],
  );

  Widget _beField(String label, TextEditingController ctrl) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      onChanged: (_) => _savePrefs(),
    ),
  );
}
