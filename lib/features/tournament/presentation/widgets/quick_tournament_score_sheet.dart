import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../models/tournament_model.dart';

class QuickTournamentScoreSheet extends StatefulWidget {
  const QuickTournamentScoreSheet(
      {super.key,
      required this.cup,
      required this.match,
      required this.onSave});
  final Tournament cup;
  final TournamentMatch match;
  final Future<void> Function(List<Map<String, int>>) onSave;
  @override
  State<QuickTournamentScoreSheet> createState() =>
      _QuickTournamentScoreSheetState();
}

class _QuickTournamentScoreSheetState extends State<QuickTournamentScoreSheet> {
  final _scores = List.generate(6, (_) => TextEditingController());
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    for (final c in _scores) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Quick score entry', style: AppTheme.headlineLg),
        const SizedBox(height: 12),
        Text(
            '${widget.cup.side(widget.match.sideA)?.name}\nvs\n${widget.cup.side(widget.match.sideB)?.name}',
            textAlign: TextAlign.center),
        const SizedBox(height: 16),
        for (var i = 0; i < 3; i++)
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                SizedBox(
                    width: 56,
                    child: Text('SET ${i + 1}', style: AppTheme.labelCaps)),
                Expanded(
                    child: TextField(
                        controller: _scores[i * 2],
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Team A'))),
                const SizedBox(width: 12),
                Expanded(
                    child: TextField(
                        controller: _scores[i * 2 + 1],
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Team B'))),
              ])),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: AppTheme.errorRed)),
        const SizedBox(height: 12),
        FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() {
                      _saving = true;
                      _error = null;
                    });
                    try {
                      final sets = <Map<String, int>>[];
                      var emptySeen = false;
                      for (var i = 0; i < 3; i++) {
                        final a = _scores[i * 2].text.trim(),
                            b = _scores[i * 2 + 1].text.trim();
                        if (a.isEmpty && b.isEmpty) {
                          emptySeen = true;
                          continue;
                        }
                        if (emptySeen ||
                            int.tryParse(a) == null ||
                            int.tryParse(b) == null) {
                          throw ArgumentError('Enter complete sets in order.');
                        }
                        sets.add({'a': int.parse(a), 'b': int.parse(b)});
                      }
                      await widget.onSave(sets);
                      if (context.mounted) Navigator.pop(context, true);
                    } catch (e) {
                      if (mounted) {
                        setState(() => _error = e
                            .toString()
                            .replaceFirst('Invalid argument(s): ', ''));
                      }
                    } finally {
                      if (mounted) setState(() => _saving = false);
                    }
                  },
            child: Text(_saving ? 'SAVING…' : 'SAVE RESULT & ADVANCE')),
      ]));
}
