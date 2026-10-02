import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/module_widgets.dart';
import '../../../core/widgets/stitch_background.dart';
import '../../auth/current_user_notifier.dart';
import '../../match_engine/live_scoring_screen.dart';
import '../../match_engine/match_repository.dart';
import '../../doubles/providers/doubles_provider.dart';
import '../models/tournament_model.dart';
import '../providers/tournament_state.dart';
import 'widgets/bracket_tree_view.dart';
import 'widgets/create_tournament_sheet.dart';
import 'widgets/quick_tournament_score_sheet.dart';

class TournamentHubScreen extends ConsumerStatefulWidget {
  const TournamentHubScreen({super.key});
  @override
  ConsumerState<TournamentHubScreen> createState() =>
      _TournamentHubScreenState();
}

class _TournamentHubScreenState extends ConsumerState<TournamentHubScreen> {
  int _tab = 0;
  String? _selected;
  final _celebrated = <String>{};
  bool get _captain => ref.read(currentUserProvider)?.isCaptain ?? false;
  @override
  Widget build(BuildContext context) {
    final cups = ref.watch(tournamentProvider);
    final controller = ref.read(tournamentProvider.notifier);
    return StitchAppBackground(
        child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
                title: const Text('Tournament arena'),
                backgroundColor: Colors.transparent,
                actions: [
                  if (_captain)
                    IconButton(
                        tooltip: 'Create tournament',
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          final id = await showModalBottomSheet<String>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (_) => const CreateTournamentSheet());
                          if (mounted && id != null) {
                            setState(() {
                              _selected = id;
                              _tab = 0;
                            });
                          }
                        }),
                ]),
            body: ListView(padding: const EdgeInsets.all(20), children: [
              Text('CHASE THE CUP.',
                  style: AppTheme.labelCaps.copyWith(color: AppTheme.mintTeal)),
              const SizedBox(height: 8),
              Text('Make club history.', style: AppTheme.headlineXl),
              const SizedBox(height: 20),
              GlassTabs(
                  labels: const [
                    'Active tournaments',
                    'Points table',
                    'Past cups'
                  ],
                  selected: _tab,
                  onSelected: (i) => setState(() {
                        _tab = i;
                        _selected = null;
                      })),
              ModuleSyncBar(store: controller),
              cups.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Could not open tournaments: $e'),
                  data: (collection) {
                    final filtered = collection.cups
                        .where((t) => _tab == 2
                            ? t.completed
                            : _tab == 1
                                ? t.format == 'league'
                                : !t.completed)
                        .toList();
                    if (filtered.isEmpty) {
                      return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 50),
                          child: Column(children: [
                            const Icon(Icons.emoji_events_outlined,
                                size: 56, color: AppTheme.limeNeon),
                            const SizedBox(height: 16),
                            Text(
                                _tab == 2
                                    ? 'Your next legacy awaits.'
                                    : _tab == 1
                                        ? 'No league tables yet.'
                                        : 'A new champion starts here.',
                                style: AppTheme.headlineLg,
                                textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            Text(
                                _captain
                                    ? 'Create a cup or league with your checked-in squad.'
                                    : 'Your captain can create a cup or league.',
                                textAlign: TextAlign.center),
                          ]));
                    }
                    final cup =
                        filtered.where((t) => t.id == _selected).firstOrNull ??
                            filtered.first;
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                              initialValue: cup.id,
                              key: ValueKey('cup-${cup.id}-$_tab'),
                              isExpanded: true,
                              items: filtered
                                  .map((t) => DropdownMenuItem(
                                      value: t.id,
                                      child: Text(t.name,
                                          overflow: TextOverflow.ellipsis)))
                                  .toList(),
                              onChanged: (id) =>
                                  setState(() => _selected = id)),
                          const SizedBox(height: 16),
                          Wrap(spacing: 12, runSpacing: 8, children: [
                            Text(
                                '${cup.sides.length} ${cup.doubles ? 'pairs' : 'players'}',
                                style: AppTheme.bodySm),
                            Text('${cup.pointCap} points · best of 3',
                                style: AppTheme.bodySm),
                            if (_captain)
                              TextButton.icon(
                                  icon:
                                      const Icon(Icons.send_outlined, size: 16),
                                  label: const Text('Broadcast results'),
                                  onPressed: () => _broadcast(cup)),
                          ]),
                          if (cup.champion != null)
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: GlassPanel(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(children: [
                                      const Icon(Icons.emoji_events,
                                          color: AppTheme.limeNeon, size: 32),
                                      const SizedBox(width: 14),
                                      Expanded(
                                          child: Text(
                                              '${cup.champion!.name}\nCHAMPION',
                                              style: AppTheme.headlineMd)),
                                    ]))),
                          const SizedBox(height: 20),
                          if (cup.format == 'knockout')
                            BracketTreeView(
                                tournament: cup,
                                onMatchTap: (m) => _openMatch(cup, m))
                          else ...[
                            _table(cup),
                            const SizedBox(height: 12),
                            Text(
                                '2 points per win. Ties: head-to-head mini-table, set difference, point difference, then seed.',
                                style: AppTheme.bodySm
                                    .copyWith(color: AppTheme.textMuted)),
                            const SizedBox(height: 24),
                            for (final round in cup.rounds) ...[
                              Text(round.name, style: AppTheme.headlineMd),
                              const SizedBox(height: 8),
                              for (final match in round.matches)
                                ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                        '${cup.side(match.sideA)!.name} vs ${cup.side(match.sideB)!.name}'),
                                    subtitle: Text(match.sets.isEmpty
                                        ? match.status
                                        : match.sets
                                            .map((s) => "${s['a']}–${s['b']}")
                                            .join('  ')),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => _openMatch(cup, match)),
                              const SizedBox(height: 16)
                            ],
                          ],
                        ]);
                  }),
            ])));
  }

  Widget _table(Tournament cup) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(columnSpacing: 18, columns: [
        for (final label in [
          '#',
          'Player / pair',
          'MP',
          'W',
          'L',
          'SW',
          'SL',
          'PD',
          'PTS'
        ])
          DataColumn(label: Text(label, style: AppTheme.labelCaps))
      ], rows: [
        for (var i = 0; i < cup.standings.length; i++)
          DataRow(cells: [
            DataCell(Text('${i + 1}')),
            DataCell(
                SizedBox(width: 160, child: Text(cup.standings[i].side.name))),
            for (final n in [
              cup.standings[i].played,
              cup.standings[i].won,
              cup.standings[i].lost,
              cup.standings[i].setsWon,
              cup.standings[i].setsLost,
              cup.standings[i].pointDifference,
              cup.standings[i].points
            ])
              DataCell(Text('$n', style: AppTheme.statBadge)),
          ])
      ]));

  Future<void> _broadcast(Tournament cup) async {
    final sent = await ref.read(tournamentProvider.notifier).broadcast(cup.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(sent
              ? 'Results sent to the club channel.'
              : 'Broadcast could not be sent. Check Telegram configuration.')));
    }
  }

  Future<void> _completed(
      Tournament cup, String matchId, List<Map<String, int>> sets) async {
    final controller = ref.read(tournamentProvider.notifier);
    await controller.complete(cup.id, matchId, sets);
  }

  void _celebrate(Tournament cup) {
    if (!mounted) return;
    final updated = ref
        .read(tournamentProvider)
        .requireValue
        .cups
        .firstWhere((t) => t.id == cup.id);
    if (updated.champion != null && _celebrated.add(updated.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog<void>(
              context: context,
              builder: (_) => ChampionCelebration(
                  name: updated.champion!.name, cupName: updated.name));
        }
      });
    }
  }

  Future<void> _openMatch(Tournament cup, TournamentMatch match) async {
    if (!match.playable || !_captain) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(match.finished
              ? 'This result is final.'
              : !_captain
                  ? 'Your captain manages tournament matches.'
                  : 'Waiting for qualifiers.')));
      return;
    }
    final choice = await showModalBottomSheet<int>(
        context: context,
        useSafeArea: true,
        builder: (sheet) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                  '${cup.side(match.sideA)!.name}\nvs ${cup.side(match.sideB)!.name}',
                  style: AppTheme.headlineMd,
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ListTile(
                  leading: const Icon(Icons.sports_tennis),
                  title: const Text('Start Live Umpire Match'),
                  onTap: () => Navigator.pop(sheet, 0)),
              ListTile(
                  leading: const Icon(Icons.edit_note),
                  title: const Text('Quick Score Entry'),
                  onTap: () => Navigator.pop(sheet, 1)),
            ])));
    if (!mounted || choice == null) return;
    if (choice == 1) {
      await showModalBottomSheet<void>(
          context: context,
          useSafeArea: true,
          isScrollControlled: true,
          builder: (_) => QuickTournamentScoreSheet(
              cup: cup,
              match: match,
              onSave: (sets) async {
                final checked = Tournament.fromJson(cup.toJson());
                checked.completeMatch(match.id, sets);
                final a = cup.side(match.sideA)!.players,
                    b = cup.side(match.sideB)!.players;
                await ref.read(matchRepositoryProvider).saveCompletedMatch(
                    existingMatchId: match.id,
                    targetPoints: cup.pointCap,
                    bestOfSets: 3,
                    matchType: cup.doubles ? 'doubles' : 'singles',
                    category: 'tournament',
                    teamA1Id: a.first.id,
                    teamA2Id: a.length > 1 ? a[1].id : null,
                    teamB1Id: b.first.id,
                    teamB2Id: b.length > 1 ? b[1].id : null,
                    winnerTeam: checked.matches
                                .firstWhere((m) => m.id == match.id)
                                .winnerId ==
                            match.sideA
                        ? 'A'
                        : 'B',
                    sets: sets,
                    isRatingEligible: false);
                await _completed(cup, match.id, sets);
                ref.invalidate(doublesHistoryProvider);
              }));
      _celebrate(cup);
      return;
    }
    await runClubAction(context, () async {
      await ref.read(tournamentProvider.notifier).markLive(cup.id, match.id);
      if (!mounted) return;
      final a = cup.side(match.sideA)!.players,
          b = cup.side(match.sideB)!.players;
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => LiveScoringScreen(
                    teamA1: a[0].name,
                    teamA1Id: a[0].id,
                    teamA2: a.length > 1 ? a[1].name : null,
                    teamA2Id: a.length > 1 ? a[1].id : null,
                    teamB1: b[0].name,
                    teamB1Id: b[0].id,
                    teamB2: b.length > 1 ? b[1].name : null,
                    teamB2Id: b.length > 1 ? b[1].id : null,
                    matchCategory: 'tournament',
                    targetPoints: cup.pointCap,
                    bestOfSets: 3,
                    externalMatchId: match.id,
                    onCompleted: (result) =>
                        _completed(cup, match.id, result.completedSets),
                  )));
      _celebrate(cup);
      ref.invalidate(doublesHistoryProvider);
    });
  }
}

class ChampionCelebration extends StatelessWidget {
  const ChampionCelebration(
      {super.key, required this.name, required this.cupName});
  final String name, cupName;
  @override
  Widget build(BuildContext context) => Dialog(
      child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(seconds: 3),
              builder: (context, value, _) => CustomPaint(
                  foregroundPainter: _Confetti(value),
                  child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.emoji_events,
                            size: 80, color: AppTheme.limeNeon),
                        const SizedBox(height: 16),
                        Text('CHAMPION',
                            style: AppTheme.labelCaps
                                .copyWith(color: AppTheme.mintTeal)),
                        const SizedBox(height: 12),
                        Text(name,
                            style: AppTheme.headlineXl,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 10),
                        Text(cupName, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('WHAT A RUN')),
                      ]))))));
}

class _Confetti extends CustomPainter {
  _Confetti(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(21);
    for (var i = 0; i < 65; i++) {
      final x = random.nextDouble() * size.width,
          y = (random.nextDouble() + t * 1.4) % 1 * size.height;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 8 + i.toDouble());
      canvas.drawRect(
          const Rect.fromLTWH(-2, -4, 4, 8),
          Paint()
            ..color = (i.isEven ? AppTheme.limeNeon : AppTheme.mintTeal)
                .withValues(alpha: (1 - t) * .8));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti oldDelegate) => oldDelegate.t != t;
}
