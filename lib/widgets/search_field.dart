import 'dart:async';
import 'package:flutter/material.dart';
import '../models/stock_data.dart';
import '../services/yahoo_finance_service.dart';
import '../l10n/app_localizations.dart';

class SearchField extends StatefulWidget {
  final String label;
  final Color accentColor;
  final void Function(StockSearchResult) onSelected;
  final VoidCallback? onClear;
  final String? currentSymbol;

  const SearchField({
    super.key,
    required this.label,
    required this.accentColor,
    required this.onSelected,
    this.onClear,
    this.currentSymbol,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _service = YahooFinanceService();

  List<StockSearchResult> _results = [];
  bool _loading = false;
  Timer? _debounce;
  OverlayEntry? _overlay;
  final _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    if (widget.currentSymbol != null) {
      _controller.text = widget.currentSymbol!;
    }
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        // Verzögerung damit Tap auf Dropdown-Eintrag zuerst verarbeitet wird
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted && !_focus.hasFocus) _removeOverlay();
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      _removeOverlay();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final results = await _service.search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
      if (_results.isNotEmpty) _showOverlay();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlay = OverlayEntry(builder: (_) => _buildDropdown());
    Overlay.of(context).insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _select(StockSearchResult result) {
    _controller.text = result.symbol;
    _removeOverlay();
    _focus.unfocus();
    widget.onSelected(result);
  }

  Widget _buildDropdown() {
    return Positioned(
      width: 300,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 48),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final r = _results[i];
                return ListTile(
                  dense: true,
                  title: Text(r.shortName, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${r.symbol} · ${r.exchange}',
                      style: const TextStyle(fontSize: 11)),
                  onTap: () => _select(r),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        onChanged: _onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: l10n.searchHint,
          hintStyle: const TextStyle(fontSize: 12),
          prefixIcon: Icon(Icons.search, color: widget.accentColor, size: 20),
          suffixIcon: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : widget.currentSymbol != null && widget.onClear != null
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _controller.clear();
                        _removeOverlay();
                        widget.onClear!();
                      },
                    )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: widget.accentColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: widget.accentColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        ),
      ),
    );
  }
}
