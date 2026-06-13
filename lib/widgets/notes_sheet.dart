import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

class _Note {
  final String id;
  final String text;
  final DateTime timestamp;
  final String? symbol;

  const _Note({
    required this.id,
    required this.text,
    required this.timestamp,
    this.symbol,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'ts': timestamp.millisecondsSinceEpoch,
        if (symbol != null) 'sym': symbol,
      };

  factory _Note.fromJson(Map<String, dynamic> j) => _Note(
        id: j['id'] as String,
        text: j['text'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(j['ts'] as int),
        symbol: j['sym'] as String?,
      );
}

class NotesSheet extends StatefulWidget {
  final String? currentSymbol;
  const NotesSheet({super.key, this.currentSymbol});

  static Future<void> show(BuildContext context, {String? currentSymbol}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => NotesSheet(currentSymbol: currentSymbol),
    );
  }

  @override
  State<NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<NotesSheet> {
  static const _kNotes = 'cm_notes';
  List<_Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kNotes) ?? [];
    final notes = raw
        .map((s) {
          try {
            return _Note.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<_Note>()
        .toList();
    // Newest first
    notes.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (mounted) setState(() { _notes = notes; _loading = false; });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _kNotes, _notes.map((n) => jsonEncode(n.toJson())).toList());
  }

  Future<void> _addNote(String text) async {
    if (text.trim().isEmpty) return;
    final note = _Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      timestamp: DateTime.now(),
      symbol: widget.currentSymbol,
    );
    setState(() => _notes.insert(0, note));
    await _saveNotes();
  }

  Future<void> _deleteNote(String id) async {
    setState(() => _notes.removeWhere((n) => n.id == id));
    await _saveNotes();
  }

  Future<void> _clearAll(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(l10n.notesClearAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.wlAlarmCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.notesDelete,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _notes.clear());
      await _saveNotes();
    }
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.notesAdd),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: l10n.notesHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.wlAlarmCancel),
          ),
          ElevatedButton(
            onPressed: () {
              _addNote(ctrl.text);
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.wlAlarmSave),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFmt = DateFormat('dd.MM.yy HH:mm');

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  Icon(Icons.notes,
                      color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.notesTitle,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (_notes.isNotEmpty)
                    TextButton(
                      onPressed: () => _clearAll(context),
                      child: Text(l10n.notesClearAll,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 22),
                    tooltip: l10n.notesAdd,
                    onPressed: _showAddDialog,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _notes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notes_outlined,
                                  size: 48,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withAlpha(80)),
                              const SizedBox(height: 8),
                              Text(l10n.notesEmpty,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withAlpha(120))),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(l10n.notesAdd),
                                onPressed: _showAddDialog,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _notes.length,
                          separatorBuilder: (ctx, i) =>
                              const Divider(height: 1, indent: 16, endIndent: 16),
                          itemBuilder: (_, i) {
                            final note = _notes[i];
                            return ListTile(
                              dense: true,
                              title: Text(note.text,
                                  style: const TextStyle(fontSize: 13)),
                              subtitle: Row(
                                children: [
                                  Text(
                                    dateFmt.format(note.timestamp),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withAlpha(120)),
                                  ),
                                  if (note.symbol != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        note.symbol!,
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18),
                                tooltip: l10n.notesDelete,
                                onPressed: () => _deleteNote(note.id),
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}
