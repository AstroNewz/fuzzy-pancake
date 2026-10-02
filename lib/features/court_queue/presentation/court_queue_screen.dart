import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/module_widgets.dart';
import '../../../core/widgets/stitch_background.dart';
import '../../attendance/attendance_repository.dart';
import '../../auth/current_user_notifier.dart';
import '../../match_engine/live_scoring_screen.dart';
import '../../tournament/models/tournament_model.dart';
import '../../trump_card/trump_card_model.dart';
import '../models/court_session_model.dart';
import '../providers/court_queue_state.dart';
import 'widgets/court_card_widget.dart';
import 'widgets/queue_reorderable_list.dart';
import 'widgets/auto_matchmaker_dialog.dart';

class CourtQueueScreen extends ConsumerStatefulWidget {
  const CourtQueueScreen({super.key});
  @override
  ConsumerState<CourtQueueScreen> createState() => _CourtQueueScreenState();
}

class _CourtQueueScreenState extends ConsumerState<CourtQueueScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _now = DateTime.now();
  int _tab = 0;
  bool _foreground = true;
  final _alerted = <String>{};
  bool get _captain => ref.read(currentUserProvider)?.isCaptain ?? false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_foreground) return;
      setState(() => _now = DateTime.now());
      final data = ref.read(courtQueueProvider).valueOrNull;
      for (final court in data?.courts ?? <CourtSession>[]) {
        if (court.startedAt != null &&
            court.remaining(_now) == 0 &&
            _alerted.add(court.id)) {
          SystemSound.play(SystemSoundType.alert);
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Court ${court.court}: time for changeover.')));
        }
      }
      if (_now.second % 20 == 0) ref.invalidate(todayAttendanceRecordsProvider);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(courtQueueProvider);
    final store = ref.read(courtQueueProvider.notifier);
    ref.listen(todayAttendanceRecordsProvider, (previous, next) {
      final players = ref.read(squadTrumpCardsProvider).valueOrNull;
      if (_captain && next.hasValue && players != null) {
        store
            .importAttendance(
                next.requireValue, players.map(ClubPlayer.fromCard).toList())
            .catchError((Object _) {});
      }
    });
    ref.listen(squadTrumpCardsProvider, (previous, next) {
      final logs = ref.read(todayAttendanceRecordsProvider).valueOrNull;
      if (_captain && next.hasValue && logs != null) {
        store
            .importAttendance(
                logs, next.requireValue.map(ClubPlayer.fromCard).toList())
            .catchError((Object _) {});
      }
    });
    ref.watch(todayAttendanceRecordsProvider);
    ref.watch(squadTrumpCardsProvider);
    return StitchAppBackground(
        child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
                title: const Text('Courtside rotation'),
                backgroundColor: Colors.transparent),
            body: ListView(padding: const EdgeInsets.all(20), children: [
              Text('LESS WAITING. MORE PLAY.',
                  style: AppTheme.labelCaps.copyWith(color: AppTheme.mintTeal)),
              const SizedBox(height: 8),
              Text('Your court is calling.', style: AppTheme.headlineXl),
              ModuleSyncBar(store: store),
              data.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('$e'),
                  data: (queue) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_captain)
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                for (var i = 1; i <= 3; i++)
                                  ChoiceChip(
                                      label: Text(
                                          '$i ${i == 1 ? 'court' : 'courts'}'),
                                      selected: queue.courtCount == i,
                                      onSelected: (_) => runClubAction(
                                          context, () => store.configure(i))),
                                ActionChip(
                                    label: const Text('Refresh check-ins'),
                                    avatar: const Icon(Icons.refresh, size: 16),
                                    onPressed: () => _refreshAttendance()),
                              ]),
                            const SizedBox(height: 16),
                            LayoutBuilder(builder: (context, c) {
                              final columns = c.maxWidth > 900
                                  ? 3
                                  : c.maxWidth > 600
                                      ? 2
                                      : 1;
                              return Wrap(
                                  spacing: 14,
                                  runSpacing: 14,
                                  children: [
                                    for (var i = 1; i <= queue.courtCount; i++)
                                      SizedBox(
                                          width: (c.maxWidth - (columns - 1) * 14) /
                                              columns,
                                          child: CourtCardWidget(
                                              court: i,
                                              session: queue.courts
                                                  .where((s) => s.court == i)
                                                  .firstOrNull,
                                              data: queue,
                                              now: _now,
                                              manage: _captain,
                                              onAssign: () => _assign(queue, i),
                                              onStart: () => runClubAction(
                                                  context,
                                                  () => store.start(queue.courts
                                                      .firstWhere(
                                                          (s) => s.court == i)
                                                      .id)),
                                              onFinish: () => runClubAction(
                                                  context,
                                                  () => store.finish(queue.courts
                                                      .firstWhere(
                                                          (s) => s.court == i)
                                                      .id)),
                                              onUmpire: () =>
                                                  _umpire(queue, queue.courts.firstWhere((s) => s.court == i)))),
                                  ]);
                            }),
                            const SizedBox(height: 24),
                            GlassTabs(
                                labels: [
                                  'Waiting (${queue.waiting(_now).length})',
                                  'On court (${queue.courts.fold<int>(0, (n, c) => n + c.players.length)})',
                                  'Cooldown (${queue.resting(_now).length})'
                                ],
                                selected: _tab,
                                onSelected: (i) => setState(() => _tab = i)),
                            const SizedBox(height: 12),
                            if (_tab == 0) ...[
                              Row(children: [
                                Expanded(
                                    child: Text(
                                        queue.manualOrder
                                            ? 'Captain’s queue order'
                                            : 'Fewest games, then longest wait',
                                        style: AppTheme.bodySm.copyWith(
                                            color: AppTheme.textMuted))),
                                if (queue.manualOrder && _captain)
                                  TextButton(
                                      onPressed: () => runClubAction(
                                          context, store.resetFairness),
                                      child: const Text('Reset fairness'))
                              ]),
                              QueueReorderableList(
                                  players: queue.waiting(_now),
                                  enabled: _captain,
                                  onReorder: (ids) => runClubAction(
                                      context, () => store.reorder(ids))),
                              if (queue.waiting(_now).isEmpty)
                                const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                        'Verified check-ins appear here. Refresh attendance after the captain confirms players.')),
                            ],
                            if (_tab == 1)
                              for (final p in queue.members
                                  .where((p) => queue.onCourt(p.player.id)))
                                ListTile(
                                    title: Text(p.player.name),
                                    subtitle:
                                        Text('${p.played} sessions completed')),
                            if (_tab == 2)
                              for (final p in queue.resting(_now))
                                ListTile(
                                    leading: const Icon(Icons.self_improvement),
                                    title: Text(p.player.name),
                                    subtitle: Text(
                                        'Ready in ${p.cooldownUntil!.difference(_now).inSeconds ~/ 60 + 1} min · ${p.played} played')),
                            const SizedBox(height: 20),
                            Text(
                                'Sessions run for 15 minutes, followed by a 5-minute cooldown. A court stays occupied until the captain rotates it.',
                                style: AppTheme.bodySm
                                    .copyWith(color: AppTheme.textMuted)),
                          ])),
            ])));
  }

  Future<void> _refreshAttendance() => runClubAction(context, () async {
        ref.invalidate(todayAttendanceRecordsProvider);
        final logs = await ref.read(todayAttendanceRecordsProvider.future),
            players = await ref.read(squadTrumpCardsProvider.future);
        await ref
            .read(courtQueueProvider.notifier)
            .importAttendance(logs, players.map(ClubPlayer.fromCard).toList());
      });
  Future<void> _assign(CourtQueueData data, int court) async {
    final doubles = await showDialog<bool>(
        context: context,
        builder: (c) =>
            AlertDialog(title: const Text('Choose your match'), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Singles')),
              FilledButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('Fair doubles'))
            ]));
    if (doubles == null || !mounted) return;
    await runClubAction(context, () async {
      final waiting = data.waiting(DateTime.now());
      if (waiting.length < (doubles ? 4 : 2)) {
        throw StateError('Not enough waiting players for this format.');
      }
      final teams = doubles
          ? CourtQueueData.balanceDoubles(waiting)
          : ([waiting[0]], [waiting[1]]);
      final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) =>
              AutoMatchmakerDialog(teamA: teams.$1, teamB: teams.$2));
      if (confirmed == true) {
        await ref.read(courtQueueProvider.notifier).allocate(
            court,
            teams.$1.map((p) => p.player.id).toList(),
            teams.$2.map((p) => p.player.id).toList());
      }
    });
  }

  Future<void> _umpire(CourtQueueData data, CourtSession session) =>
      runClubAction(context, () async {
        await ref.read(courtQueueProvider.notifier).start(session.id);
        if (!mounted) return;
        final a = session.teamA
                .map((id) =>
                    data.members.firstWhere((p) => p.player.id == id).player)
                .toList(),
            b = session.teamB
                .map((id) =>
                    data.members.firstWhere((p) => p.player.id == id).player)
                .toList();
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
                    matchCategory: 'practice',
                    externalMatchId: session.id,
                    onCompleted: (_) => ref
                        .read(courtQueueProvider.notifier)
                        .finish(session.id))));
      });
}
