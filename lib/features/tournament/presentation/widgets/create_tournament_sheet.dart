import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../trump_card/trump_card_model.dart';
import '../../models/tournament_model.dart';
import '../../providers/tournament_state.dart';

class CreateTournamentSheet extends ConsumerStatefulWidget {
  const CreateTournamentSheet({super.key});
  @override
  ConsumerState<CreateTournamentSheet> createState() =>
      _CreateTournamentSheetState();
}

class _CreateTournamentSheetState extends ConsumerState<CreateTournamentSheet> {
  final _name = TextEditingController();
  final _selected = <String>{};
  int _step = 0, _cap = 21;
  bool _doubles = false, _random = false, _saving = false;
  String _format = 'knockout';
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final players = ref.watch(squadTrumpCardsProvider);
    return SizedBox(
        height: MediaQuery.sizeOf(context).height * .88,
        child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Create your next cup.', style: AppTheme.headlineLg),
                  const SizedBox(height: 12),
                  GlassTabs(
                      labels: const ['1 · Format', '2 · Rules', '3 · Players'],
                      selected: _step,
                      onSelected: (i) {
                        if (i < _step) setState(() => _step = i);
                      }),
                  const SizedBox(height: 16),
                  Expanded(
                      child: SingleChildScrollView(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                        if (_step == 0) ...[
                          TextField(
                              controller: _name,
                              maxLength: 60,
                              decoration: const InputDecoration(
                                  labelText: 'Tournament name',
                                  hintText: 'Friday Night Cup')),
                          const SizedBox(height: 16),
                          for (final format in [
                            (
                              'knockout',
                              'Knockout cup',
                              'Single elimination, seeded byes, final and bronze playoff.'
                            ),
                            (
                              'league',
                              'Round-robin league',
                              'Everyone plays everyone. Two points for a win.'
                            )
                          ])
                            ListTile(
                                selected: _format == format.$1,
                                leading: Icon(_format == format.$1
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off),
                                onTap: () =>
                                    setState(() => _format = format.$1),
                                title: Text(format.$2),
                                subtitle: Text(format.$3)),
                        ],
                        if (_step == 1) ...[
                          Text('GAME FORMAT', style: AppTheme.labelCaps),
                          const SizedBox(height: 10),
                          GlassTabs(
                              labels: const ['Singles', 'Doubles'],
                              selected: _doubles ? 1 : 0,
                              onSelected: (i) =>
                                  setState(() => _doubles = i == 1)),
                          const SizedBox(height: 24),
                          Text('POINT TARGET', style: AppTheme.labelCaps),
                          Wrap(spacing: 8, children: [
                            for (final p in [11, 15, 21])
                              ChoiceChip(
                                  label: Text('$p points'),
                                  selected: _cap == p,
                                  onSelected: (_) => setState(() => _cap = p))
                          ]),
                          const SizedBox(height: 16),
                          Text(
                              'Best of three sets. Win by two, with a ${_cap + 9}-point ceiling. 11 and 15 are club variants; 21 is standard BWF scoring.',
                              style: AppTheme.bodyMd),
                        ],
                        if (_step == 2) ...[
                          SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Random draw'),
                              subtitle: Text(_random
                                  ? 'Shuffle the draw and doubles partners.'
                                  : 'Seed by current Elo. Doubles partners pair in seed order.'),
                              value: _random,
                              onChanged: (v) => setState(() => _random = v)),
                          Text('${_selected.length} players selected',
                              style: AppTheme.headlineMd),
                          players.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (_, __) => TextButton(
                                  onPressed: () =>
                                      ref.invalidate(squadTrumpCardsProvider),
                                  child: const Text('Retry player list')),
                              data: (cards) => Column(children: [
                                    TextButton(
                                        onPressed: () => setState(() {
                                              if (_selected.length ==
                                                  cards.length) {
                                                _selected.clear();
                                              } else {
                                                _selected.addAll(cards
                                                    .map((c) => c.playerId));
                                              }
                                            }),
                                        child:
                                            const Text('Select / clear all')),
                                    for (final card in cards)
                                      CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          value:
                                              _selected.contains(card.playerId),
                                          onChanged: (v) => setState(() {
                                                if (v == true) {
                                                  _selected.add(card.playerId);
                                                } else {
                                                  _selected
                                                      .remove(card.playerId);
                                                }
                                              }),
                                          title: Text(card.fullName),
                                          subtitle: Text(
                                              '${card.eloRating} Elo · ${card.ovrRating} OVR')),
                                  ])),
                        ],
                        if (_error != null)
                          Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: AppTheme.errorRed))),
                      ]))),
                  FilledButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              if (_step < 2) {
                                if (_step == 0 && _name.text.trim().isEmpty) {
                                  setState(() =>
                                      _error = 'Enter a tournament name.');
                                  return;
                                }
                                setState(() {
                                  _step++;
                                  _error = null;
                                });
                                return;
                              }
                              setState(() {
                                _saving = true;
                                _error = null;
                              });
                              try {
                                final cup = Tournament.create(
                                    name: _name.text,
                                    format: _format,
                                    doubles: _doubles,
                                    pointCap: _cap,
                                    randomDraw: _random,
                                    players: (players.valueOrNull ?? [])
                                        .where((p) =>
                                            _selected.contains(p.playerId))
                                        .map(ClubPlayer.fromCard)
                                        .toList());
                                await ref
                                    .read(tournamentProvider.notifier)
                                    .create(cup);
                                if (context.mounted) {
                                  Navigator.pop(context, cup.id);
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() => _error = e
                                      .toString()
                                      .replaceFirst(
                                          'Invalid argument(s): ', ''));
                                }
                              } finally {
                                if (mounted) setState(() => _saving = false);
                              }
                            },
                      child: Text(_saving
                          ? 'CREATING…'
                          : _step == 2
                              ? 'CREATE TOURNAMENT'
                              : 'CONTINUE')),
                ])));
  }
}
