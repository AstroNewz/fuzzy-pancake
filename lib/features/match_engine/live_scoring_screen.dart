import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/widgets/app_motion.dart';
import '../../core/services/audio_umpire_service.dart';
import '../../core/widgets/glass_panel.dart';
import 'umpire_preferences_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/bwf_scoring_rules.dart';
import 'match_engine_state.dart';
import 'live_match_draft.dart';
import 'match_repository.dart';
import '../auth/current_user_notifier.dart';
import '../ladder/ladder_state.dart';
import '../trump_card/trump_card_model.dart';
import '../../core/network/offline_sync_service.dart';

/// Live Court Umpire & Touch Scoring Screen with Point Commentary & Custom Match Points
class LiveScoringScreen extends ConsumerStatefulWidget {
  final String? externalMatchId;
  final Future<void> Function(LiveMatchState)? onCompleted;
  final String? teamA1;
  final String? teamA1Id;
  final String? teamA2;
  final String? teamA2Id;
  final String? teamB1;
  final String? teamB1Id;
  final String? teamB2;
  final String? teamB2Id;
  final String? matchCategory;
  final int? targetPoints;
  final int? bestOfSets;

  const LiveScoringScreen({
    super.key,
    this.externalMatchId,
    this.onCompleted,
    this.teamA1,
    this.teamA1Id,
    this.teamA2,
    this.teamA2Id,
    this.teamB1,
    this.teamB1Id,
    this.teamB2,
    this.teamB2Id,
    this.matchCategory,
    this.targetPoints,
    this.bestOfSets,
  });

  @override
  ConsumerState<LiveScoringScreen> createState() => _LiveScoringScreenState();
}

class _LiveScoringScreenState extends ConsumerState<LiveScoringScreen>
    with WidgetsBindingObserver, RouteAware {
  final _audio = AudioUmpireService();
  final _drafts = LiveMatchDraftRepository();
  bool _readyToScore = false;
  String? _restoreError;
  bool _draftErrorShown = false;
  ProviderSubscription<LiveMatchState>? _matchListener;
  ProviderSubscription<UmpirePreferences>? _preferenceListener;
  bool _foreground = true, _routeActive = true;
  bool? _lastAwake, _lastKeys;
  ModalRoute<dynamic>? _route;
  bool _isSavingMatch = false;
  bool _intervalDialogOpen = false;

  static const List<String> _quickTacticalTags = [
    'Smash Winner',
    'Net Kill',
    'Deceptive Drop',
    'Forced Error',
    'Unforced Error',
    'Service Fault',
    'Out of Bounds',
    'Long Rally',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audio.listen((key) {
      final match = ref.read(liveMatchProvider);
      if (!_readyToScore ||
          !_foreground ||
          !_routeActive ||
          !ref.read(umpirePreferencesProvider).buttons ||
          match.isPaused ||
          match.isMatchCompleted ||
          _isSavingMatch) {
        return;
      }
      final notifier = ref.read(liveMatchProvider.notifier);
      if (key == 'undo') {
        notifier.undoLastPoint();
        return;
      }
      final team = key == 'server'
          ? match.servingTeam
          : match.servingTeam == 'A'
              ? 'B'
              : 'A';
      if (team == 'A') {
        notifier.addPointTeamA();
      } else {
        notifier.addPointTeamB();
      }
    });
    _matchListener = ref.listenManual(liveMatchProvider, (before, after) {
      if (!_readyToScore) return;
      _saveDraft(after);
      _updateDevices(after);
      if (before == null || !_foreground || !_routeActive) return;
      final changed = before.teamAScore != after.teamAScore ||
          before.teamBScore != after.teamBScore ||
          before.currentSet != after.currentSet;
      if (!changed) return;
      final prefs = ref.read(umpirePreferencesProvider);
      if (prefs.voice) {
        _audio.speak(
            AudioUmpireService.callout(before, after), prefs.speechRate);
      }
      if (prefs.sounds &&
          (before.completedSets.length < after.completedSets.length ||
              BwfScoringRules.isAtInterval(after.teamAScore, after.teamBScore,
                  targetPoints: after.targetPoints))) {
        _audio.chime();
      }
    });
    _preferenceListener = ref.listenManual(umpirePreferencesProvider,
        (_, __) => _updateDevices(ref.read(liveMatchProvider)));
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeMatch());
  }

  Future<void> _initializeMatch() async {
    if (!mounted) return;
    setState(() => _restoreError = null);
    try {
      final id = widget.externalMatchId;
      final saved = id == null ? null : await _drafts.load(id);
      if (!mounted) return;
      if (saved != null) {
        if (saved.matchId != id ||
            saved.teamA1Id != widget.teamA1Id ||
            saved.teamB1Id != widget.teamB1Id ||
            saved.teamA2Id != widget.teamA2Id ||
            saved.teamB2Id != widget.teamB2Id ||
            saved.targetPoints != (widget.targetPoints ?? 21) ||
            saved.bestOfSets != (widget.bestOfSets ?? 3)) {
          throw StateError(
              'Saved match details differ. Reopen the original fixture to resume.');
        }
        ref.read(liveMatchProvider.notifier).restoreMatch(saved);
      } else {
        if (widget.teamA1 != null ||
            widget.teamB1 != null ||
            widget.matchCategory != null) {
          ref.read(liveMatchProvider.notifier).initMatch(
                matchId: widget.externalMatchId,
                matchType: widget.teamA2Id != null ? 'doubles' : 'singles',
                category: widget.matchCategory ?? 'ladder',
                isRatingEligible: widget.matchCategory != 'practice',
                targetPoints: widget.targetPoints ?? 21,
                bestOfSets: widget.bestOfSets ?? 3,
                teamA1Id: widget.teamA1Id ?? 'SD-0001',
                teamA1Name: widget.teamA1 ?? 'Sachin Jyani',
                teamA2Id: widget.teamA2Id,
                teamA2Name: widget.teamA2,
                teamB1Id: widget.teamB1Id ?? 'SD-0002',
                teamB1Name: widget.teamB1 ?? 'Ishan Narayan Shukla',
                teamB2Id: widget.teamB2Id,
                teamB2Name: widget.teamB2,
              );
        }
      }
      setState(() => _readyToScore = true);
      final match = ref.read(liveMatchProvider);
      _saveDraft(match);
      _updateDevices(match);
    } catch (_) {
      if (mounted)
        setState(() => _restoreError =
            'Could not restore this match. Your saved score has been kept.');
    }
  }

  Future<void> _saveDraft(LiveMatchState match) async {
    if (widget.externalMatchId == null ||
        match.matchId != widget.externalMatchId) return;
    try {
      await _drafts.save(match);
      _draftErrorShown = false;
    } catch (_) {
      if (mounted && !_draftErrorShown) {
        _draftErrorShown = true;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Live score could not be backed up. Keep this match open until saved.')));
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route && route != null) {
      umpireRouteObserver.unsubscribe(this);
      _route = route;
      umpireRouteObserver.subscribe(this, route);
    }
  }

  void _updateDevices(LiveMatchState match) {
    final active = _readyToScore &&
        _foreground &&
        _routeActive &&
        !match.isPaused &&
        !match.isMatchCompleted &&
        !_isSavingMatch;
    final keys = active && ref.read(umpirePreferencesProvider).buttons;
    if (_lastAwake == active && _lastKeys == keys) return;
    _lastAwake = active;
    _lastKeys = keys;
    _audio.active(keepAwake: active, keys: keys);
  }

  @override
  void didPushNext() {
    _routeActive = false;
    _updateDevices(ref.read(liveMatchProvider));
  }

  @override
  void didPopNext() {
    _routeActive = true;
    _updateDevices(ref.read(liveMatchProvider));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _lastKeys = null;
    _updateDevices(ref.read(liveMatchProvider));
  }

  @override
  void dispose() {
    _matchListener?.close();
    _preferenceListener?.close();
    umpireRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _audio.dispose();
    super.dispose();
  }

  void _showCommentDialog(BuildContext context) {
    final match = ref.read(liveMatchProvider);
    if (match.pointEvents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Score at least one point to attach commentary.')),
      );
      return;
    }
    final lastEvent = match.pointEvents.last;
    final textCtrl = TextEditingController(text: lastEvent.comment ?? '');
    String selectedTag = lastEvent.tag ?? _quickTacticalTags.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'POINT COMMENTARY (${lastEvent.scoreA}-${lastEvent.scoreB})',
                      style: AppTheme.chivo(
                          size: 14,
                          color: AppTheme.textWhite,
                          weight: FontWeight.w900),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppTheme.textMuted, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('QUICK TACTICAL TAG',
                    style: AppTheme.jetBrainsMono(
                        size: 10, color: AppTheme.textMuted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _quickTacticalTags.map((tag) {
                    final isSel = selectedTag == tag;
                    return ChoiceChip(
                      label: Text(tag),
                      selected: isSel,
                      selectedColor: AppTheme.limeNeon,
                      backgroundColor: AppTheme.surfaceVar,
                      labelStyle: AppTheme.jetBrainsMono(
                        size: 10,
                        weight: FontWeight.bold,
                        color: isSel ? Colors.black : AppTheme.textMuted,
                      ),
                      side: BorderSide(
                          color:
                              isSel ? AppTheme.limeNeon : AppTheme.borderDark),
                      onSelected: (_) => setModalState(() => selectedTag = tag),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Text('CUSTOM UMPIRE NOTE',
                    style: AppTheme.jetBrainsMono(
                        size: 10, color: AppTheme.textMuted)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: TextField(
                    controller: textCtrl,
                    style: AppTheme.spaceGrotesk(
                        size: 13, color: AppTheme.textWhite),
                    decoration: const InputDecoration(
                      hintText:
                          'e.g. Sharp angled crosscourt smash out of reach',
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.limeNeon,
                      foregroundColor: const Color(0xFF283500),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      ref
                          .read(liveMatchProvider.notifier)
                          .updateLastPointComment(
                            textCtrl.text.trim(),
                            tag: selectedTag,
                          );
                      Navigator.pop(ctx);
                    },
                    child: Text('SAVE COMMENTARY',
                        style:
                            AppTheme.chivo(size: 13, weight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCommentaryLogSheet(BuildContext context) {
    final match = ref.read(liveMatchProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.70,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MATCH COMMENTARY & TIMELINE',
                      style: AppTheme.chivo(
                          size: 15,
                          weight: FontWeight.w900,
                          color: AppTheme.textWhite),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppTheme.textMuted, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(color: AppTheme.borderDark),
                if (match.pointEvents.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No points scored yet. Start umpiring to build the timeline.',
                        style: AppTheme.spaceGrotesk(color: AppTheme.textMuted),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: match.pointEvents.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: AppTheme.borderDark, height: 1),
                      itemBuilder: (context, i) {
                        final evt =
                            match.pointEvents[match.pointEvents.length - 1 - i];
                        final isTeamA = evt.scoringTeam == 'A';
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isTeamA
                                  ? AppTheme.limeNeon.withValues(alpha: 0.15)
                                  : AppTheme.mintTeal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${evt.scoreA}-${evt.scoreB}',
                              style: AppTheme.jetBrainsMono(
                                size: 12,
                                weight: FontWeight.bold,
                                color: isTeamA
                                    ? AppTheme.limeNeon
                                    : AppTheme.mintTeal,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                evt.scorerName,
                                style: AppTheme.chivo(
                                    size: 13,
                                    weight: FontWeight.w700,
                                    color: AppTheme.textWhite),
                              ),
                              if (evt.tag != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceVar,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    evt.tag!,
                                    style: AppTheme.jetBrainsMono(
                                        size: 9.5,
                                        color: AppTheme.limeNeon,
                                        weight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle:
                              evt.comment != null && evt.comment!.isNotEmpty
                                  ? Text(
                                      evt.comment!,
                                      style: AppTheme.spaceGrotesk(
                                          size: 11.5,
                                          color: AppTheme.textMuted),
                                    )
                                  : null,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCustomizePointsDialog(BuildContext context) {
    final match = ref.read(liveMatchProvider);
    final ctrl = TextEditingController(text: match.targetPoints.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderDark)),
        title: Text('Adjust Target Points',
            style: AppTheme.chivo(size: 16, color: AppTheme.textWhite)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change the winning point threshold for this set:',
                style:
                    AppTheme.spaceGrotesk(size: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: AppTheme.jetBrainsMono(
                  size: 18, color: AppTheme.limeNeon, weight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'e.g. 11, 15, 21, 30',
                labelText: 'Target Match Points',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTheme.spaceGrotesk(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.limeNeon,
                foregroundColor: const Color(0xFF283500)),
            onPressed: () {
              final pts = int.tryParse(ctrl.text.trim());
              if (pts != null && pts > 0) {
                ref.read(liveMatchProvider.notifier).setTargetPoints(pts);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Update Target'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_readyToScore) {
      return Scaffold(
          appBar: AppBar(title: const Text('Live umpire')),
          body: Center(
              child: _restoreError == null
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_restoreError!, textAlign: TextAlign.center),
                        TextButton(
                            onPressed: _initializeMatch,
                            child: const Text('Retry restore')),
                      ]))));
    }
    final match = ref.watch(liveMatchProvider);
    final umpirePrefs = ref.watch(umpirePreferencesProvider);
    final target = match.targetPoints;
    final isSetPointA = match.teamAScore >= (target - 1) &&
        (match.teamAScore - match.teamBScore) >= 1;
    final isSetPointB = match.teamBScore >= (target - 1) &&
        (match.teamBScore - match.teamAScore) >= 1;
    final isDeuce =
        match.teamAScore >= (target - 1) && match.teamBScore >= (target - 1);

    final serverScore =
        match.servingTeam == 'A' ? match.teamAScore : match.teamBScore;
    final isRightCourt = BwfScoringRules.isRightServiceCourt(serverScore);

    final isIntervalPoint = (target / 2).ceil();
    final isAtInterval = (match.teamAScore == isIntervalPoint ||
            match.teamBScore == isIntervalPoint) &&
        !match.hasIntervalTriggered &&
        (match.teamAScore <= isIntervalPoint &&
            match.teamBScore <= isIntervalPoint);

    if (isAtInterval && !_intervalDialogOpen && !match.isMatchCompleted) {
      _intervalDialogOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(liveMatchProvider.notifier).markIntervalAcknowledged();
          _showIntervalBreakDialog(context, isIntervalPoint);
        }
        _intervalDialogOpen = false;
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDarker,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.limeNeon.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppTheme.limeNeon.withValues(alpha: 0.4)),
              ),
              child: Text(
                'SET ${match.currentSet} OF ${match.bestOfSets}',
                style: AppTheme.jetBrainsMono(
                  color: AppTheme.limeNeon,
                  size: 11,
                  weight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: match.undoStack.isEmpty && widget.externalMatchId == null
                  ? () => _showCustomizePointsDialog(context)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.cardMid,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  children: [
                    Text(
                      '${match.targetPoints} PTS',
                      style: AppTheme.jetBrainsMono(
                          size: 10.5,
                          color: AppTheme.mintTeal,
                          weight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 11, color: AppTheme.mintTeal),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.comment_outlined, color: AppTheme.limeNeon),
            tooltip: 'Commentary & Timeline',
            onPressed: () => _showCommentaryLogSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: AppTheme.textMuted),
            tooltip: 'Umpire preferences',
            onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const UmpirePreferencesSheet()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status Strip (Deuce / Set Point / Interval)
            if (match.isDoubles)
              Padding(
                  padding: const EdgeInsets.all(8),
                  child: GlassPanel(
                      padding: const EdgeInsets.all(12),
                      child: Column(children: [
                        Text('${match.serverName} → ${match.receiverName}',
                            style: AppTheme.bodyMd,
                            textAlign: TextAlign.center),
                        Text('${isRightCourt ? 'RIGHT' : 'LEFT'} SERVICE COURT',
                            style: AppTheme.labelCaps
                                .copyWith(color: AppTheme.mintTeal)),
                        const SizedBox(height: 8),
                        Row(children: [
                          for (final team in ['A', 'B'])
                            Expanded(
                                child: Column(children: [
                              Text('TEAM $team', style: AppTheme.labelCaps),
                              Text(
                                  'L: ${match.playerAt(team, (team == 'A' ? match.doublesPositions.aFirstRight : match.doublesPositions.bFirstRight) ? 1 : 0)}',
                                  style: AppTheme.bodySm,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                  'R: ${match.playerAt(team, (team == 'A' ? match.doublesPositions.aFirstRight : match.doublesPositions.bFirstRight) ? 0 : 1)}',
                                  style: AppTheme.bodySm,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ]))
                        ]),
                      ]))),
            if (umpirePrefs.gestures)
              GestureDetector(
                  onDoubleTap: () =>
                      ref.read(liveMatchProvider.notifier).undoLastPoint(),
                  child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      color: AppTheme.cardMid,
                      child: Text('SWIPE UP TO SCORE · DOUBLE-TAP HERE TO UNDO',
                          style: AppTheme.labelCaps.copyWith(fontSize: 8),
                          textAlign: TextAlign.center))),
            if (isDeuce || isSetPointA || isSetPointB)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: isDeuce ? const Color(0xFFF59E0B) : AppTheme.limeNeon,
                child: Center(
                  child: Text(
                    isDeuce
                        ? 'DEUCE (2-POINT LEAD REQUIRED)'
                        : isSetPointA
                            ? 'MATCH / SET POINT — ${match.teamAPlayer1Name.toUpperCase()}'
                            : 'MATCH / SET POINT — ${match.teamBPlayer1Name.toUpperCase()}',
                    style: AppTheme.jetBrainsMono(
                      size: 11,
                      weight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

            // Top Completed Sets Summary
            if (match.completedSets.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: AppTheme.bgDarker,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('COMPLETED SETS: ',
                        style: AppTheme.jetBrainsMono(
                            size: 10, color: AppTheme.textMuted)),
                    ...match.completedSets.map((s) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVar,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${s['a']}-${s['b']}',
                            style: AppTheme.jetBrainsMono(
                                size: 11,
                                weight: FontWeight.bold,
                                color: AppTheme.limeNeon),
                          ),
                        )),
                  ],
                ),
              ),

            // Main Score Touch Panels
            Expanded(
              flex: 12,
              child: Row(
                children: [
                  // Team A (Left Touch Zone)
                  Expanded(
                    child: _buildScoreTouchPad(
                      teamLabel: 'TEAM A',
                      playerName: match.teamAPlayer1Name,
                      partnerName: match.teamAPlayer2Name,
                      score: match.teamAScore,
                      isServing: match.servingTeam == 'A',
                      isRightCourt: isRightCourt,
                      accentColor: AppTheme.limeNeon,
                      onTap: () => ref
                          .read(liveMatchProvider.notifier)
                          .addPointTeamA(tag: 'Point Scored'),
                    ),
                  ),

                  // Center Divider Court Line
                  umpirePrefs.gestures
                      ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onDoubleTap: () => ref
                              .read(liveMatchProvider.notifier)
                              .undoLastPoint(),
                          child: Container(
                              width: 30,
                              color: AppTheme.cardMid,
                              alignment: Alignment.center,
                              child: const Icon(Icons.undo,
                                  size: 18, color: AppTheme.textMuted)),
                        )
                      : Container(width: 2, color: AppTheme.borderDark),

                  // Team B (Right Touch Zone)
                  Expanded(
                    child: _buildScoreTouchPad(
                      teamLabel: 'TEAM B',
                      playerName: match.teamBPlayer1Name,
                      partnerName: match.teamBPlayer2Name,
                      score: match.teamBScore,
                      isServing: match.servingTeam == 'B',
                      isRightCourt: isRightCourt,
                      accentColor: AppTheme.mintTeal,
                      onTap: () => ref
                          .read(liveMatchProvider.notifier)
                          .addPointTeamB(tag: 'Point Scored'),
                    ),
                  ),
                ],
              ),
            ),

            // Quick Tactical Commentary Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: AppTheme.bgDarker,
              child: Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.add_comment_outlined,
                        size: 14, color: AppTheme.limeNeon),
                    label: Text(
                      'Comment Point',
                      style: AppTheme.jetBrainsMono(
                          size: 10.5,
                          color: AppTheme.limeNeon,
                          weight: FontWeight.bold),
                    ),
                    backgroundColor: AppTheme.cardDark,
                    side: const BorderSide(color: AppTheme.borderDark),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    onPressed: () => _showCommentDialog(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _quickTacticalTags.take(4).map((tag) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(tag,
                                  style: AppTheme.jetBrainsMono(
                                      size: 10, color: AppTheme.textMuted)),
                              backgroundColor: AppTheme.cardDark,
                              side:
                                  const BorderSide(color: AppTheme.borderDark),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                              onPressed: () {
                                ref
                                    .read(liveMatchProvider.notifier)
                                    .updateLastPointComment('', tag: tag);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Tagged last point: $tag'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Control Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppTheme.cardDark,
                border: Border(top: BorderSide(color: AppTheme.borderDark)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Undo Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textWhite,
                      side: const BorderSide(color: AppTheme.borderDark),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.undo, size: 16),
                    label: Text('UNDO POINT',
                        style: AppTheme.jetBrainsMono(
                            size: 11, weight: FontWeight.bold)),
                    onPressed: match.undoStack.isNotEmpty
                        ? () =>
                            ref.read(liveMatchProvider.notifier).undoLastPoint()
                        : null,
                  ),

                  // Finish / Save Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: match.isMatchCompleted
                          ? AppTheme.limeNeon
                          : AppTheme.surfaceVar,
                      foregroundColor: match.isMatchCompleted
                          ? const Color(0xFF283500)
                          : AppTheme.textWhite,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isSavingMatch
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.save_outlined, size: 16),
                    label: Text(
                      match.isMatchCompleted
                          ? 'SAVE OFFICIAL MATCH'
                          : 'PLAY TO FINISH',
                      style:
                          AppTheme.chivo(size: 11.5, weight: FontWeight.w900),
                    ),
                    onPressed: _isSavingMatch || !match.isMatchCompleted
                        ? null
                        : () => _handleSaveMatch(context, match),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreTouchPad({
    required String teamLabel,
    required String playerName,
    required String? partnerName,
    required int score,
    required bool isServing,
    required bool isRightCourt,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final gestures = ref.watch(umpirePreferencesProvider).gestures;
    double swipeDistance = 0;
    return GestureDetector(
        onVerticalDragStart: gestures ? (_) => swipeDistance = 0 : null,
        onVerticalDragUpdate:
            gestures ? (details) => swipeDistance += details.delta.dy : null,
        onVerticalDragEnd: gestures
            ? (_) {
                if (swipeDistance < -36 && !_isSavingMatch) onTap();
              }
            : null,
        child: PressScale(
            child: InkWell(
          onTap: gestures
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onTap();
                },
          splashColor: accentColor.withValues(alpha: 0.15),
          child: AnimatedContainer(
            duration: AppMotion.durationOf(context),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                  accentColor.withValues(alpha: isServing ? .13 : .025),
                  Colors.transparent
                ])),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header Info
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isServing) ...[
                          const Icon(Icons.sports_tennis,
                              size: 14, color: AppTheme.limeNeon),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          teamLabel,
                          style: AppTheme.jetBrainsMono(
                            size: 11,
                            weight: FontWeight.w800,
                            color: isServing ? accentColor : AppTheme.textMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      playerName,
                      textAlign: TextAlign.center,
                      style: AppTheme.chivo(
                          size: 16,
                          weight: FontWeight.w900,
                          color: AppTheme.textWhite),
                    ),
                    if (partnerName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '& $partnerName',
                        style: AppTheme.spaceGrotesk(
                            size: 12, color: AppTheme.textMuted),
                      ),
                    ],
                    if (isServing) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isRightCourt ? 'RIGHT COURT' : 'LEFT COURT',
                          style: AppTheme.jetBrainsMono(
                              size: 9,
                              weight: FontWeight.w800,
                              color: accentColor),
                        ),
                      ),
                    ],
                  ],
                ),

                // Giant Point Number
                Flexible(
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AnimatedSwitcher(
                            duration: AppMotion.durationOf(context),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                        scale: animation
                                            .drive(Tween(begin: .86, end: 1.0)),
                                        child: child)),
                            child: Text(
                              '$score',
                              key: ValueKey(score),
                              style: AppTheme.chivo(
                                size: 104,
                                weight: FontWeight.w900,
                                color: isServing
                                    ? accentColor
                                    : AppTheme.textWhite,
                              ),
                            )))),

                // Tap hint
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.cardMid,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app,
                          size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        '+1 POINT',
                        style: AppTheme.jetBrainsMono(
                            size: 10,
                            weight: FontWeight.w700,
                            color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )));
  }

  void _showIntervalBreakDialog(BuildContext context, int intervalPoint) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.limeNeon)),
        title: Row(
          children: [
            const Icon(Icons.timer_outlined, color: AppTheme.limeNeon),
            const SizedBox(width: 8),
            Text('$intervalPoint-PT INTERVAL BREAK',
                style: AppTheme.chivo(size: 16, color: AppTheme.textWhite)),
          ],
        ),
        content: Text(
          'Take a 60-second interval. Change ends at this interval only in the deciding set. Resume when ready.',
          style: AppTheme.spaceGrotesk(size: 13, color: AppTheme.textMuted),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.limeNeon,
                foregroundColor: const Color(0xFF283500)),
            onPressed: () {
              ref.read(liveMatchProvider.notifier).markIntervalAcknowledged();
              Navigator.pop(ctx);
            },
            child: const Text('RESUME PLAY'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSaveMatch(
      BuildContext context, LiveMatchState match) async {
    if (_isSavingMatch || !match.isMatchCompleted) return;
    setState(() => _isSavingMatch = true);
    try {
      final result = await ref.read(matchRepositoryProvider).saveCompletedMatch(
            existingMatchId: match.matchId,
            targetPoints: match.targetPoints,
            bestOfSets: match.bestOfSets,
            matchType: match.matchType,
            category: match.category,
            teamA1Id: match.teamA1Id,
            teamA2Id: match.teamA2Id,
            teamB1Id: match.teamB1Id,
            teamB2Id: match.teamB2Id,
            winnerTeam: match.matchWinner ??
                (match.teamAScore > match.teamBScore ? 'A' : 'B'),
            sets: match.completedSets.isNotEmpty
                ? match.completedSets
                : [
                    {'a': match.teamAScore, 'b': match.teamBScore}
                  ],
            isRatingEligible: match.isRatingEligible,
            umpireId: ref.read(currentUserProvider)?.id,
          );

      await widget.onCompleted?.call(match);
      if (widget.externalMatchId != null)
        await _drafts.remove(widget.externalMatchId!);

      if (!context.mounted) return;
      ref.invalidate(ladderStandingsProvider);
      ref.invalidate(squadTrumpCardsProvider);
      ref.invalidate(pendingOfflineCountProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppTheme.cardMid,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Could not save the match. Your score is still here; please try again.'),
            backgroundColor: AppTheme.cardMid),
      );
    } finally {
      if (mounted) setState(() => _isSavingMatch = false);
    }
  }
}
