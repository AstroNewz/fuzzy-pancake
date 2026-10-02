import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_motion.dart';
import '../../core/widgets/court_panel.dart';
import '../../core/widgets/stitch_background.dart';
import '../auth/current_user_notifier.dart';
import 'training_history.dart';
import 'training_session.dart';

class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key});
  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen>
    with WidgetsBindingObserver {
  int _preset = 0;
  TrainingSession _session = TrainingSession(TrainingPlan.presets.first);
  String _sessionId = const Uuid().v4();
  final _clock = Stopwatch();
  Duration _lastTick = Duration.zero;
  Timer? _timer;
  bool _saving = false;
  bool _saved = false;
  String? _saveError;
  String? _playerId;
  TrainingRecord? _record;

  @override
  void initState() {
    super.initState();
    _playerId = ref.read(currentUserProvider)?.id;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clock.stop();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _session.running) _pause();
  }

  void _tick() {
    final now = _clock.elapsed;
    final resting = _session.resting;
    final round = _session.round;
    setState(() => _session.advance(now - _lastTick));
    _lastTick = now;
    if (resting != _session.resting || round != _session.round) {
      HapticFeedback.mediumImpact();
    }
    if (_session.completed) {
      _timer?.cancel();
      _clock.stop();
      HapticFeedback.heavyImpact();
      _save();
    }
  }

  void _start() {
    if (_session.completed || _session.running) return;
    HapticFeedback.selectionClick();
    setState(_session.start);
    _clock.start();
    _lastTick = _clock.elapsed;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _pause() {
    _tick();
    _timer?.cancel();
    _clock.stop();
    setState(_session.pause);
  }

  void _reset(int preset) {
    _timer?.cancel();
    _clock.stop();
    _clock.reset();
    _lastTick = Duration.zero;
    setState(() {
      _preset = preset;
      _session = TrainingSession(TrainingPlan.presets[preset]);
      _sessionId = const Uuid().v4();
      _record = null;
      _saved = false;
      _saveError = null;
    });
  }

  Future<void> _save() async {
    if (_saving || _saved || !_session.completed) return;
    if (_playerId == null) {
      setState(() => _saveError = 'Sign in to save your training history.');
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    _record ??= TrainingRecord(
        id: _sessionId,
        name: _session.plan.name,
        completedAt: DateTime.now(),
        seconds: _session.plan.totalSeconds,
        rounds: _session.plan.rounds);
    try {
      await ref
          .read(trainingHistoryRepositoryProvider)
          .save(_playerId!, _record!);
      if (!mounted) return;
      ref.invalidate(trainingHistoryProvider(_playerId!));
      setState(() => _saved = true);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _saveError = 'Your workout could not be saved. Tap to retry.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmReset() async {
    if (_saving) return false;
    if (!_session.started || _saved) return true;
    if (_session.running) _pause();
    return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('End this workout?'),
                  content: Text(_session.completed
                      ? 'This completed workout has not been saved yet.'
                      : 'Only completed workouts are added to your history.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Keep workout')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('End workout')),
                  ],
                )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final plan = _session.plan;
    final color = _session.resting ? AppTheme.mintTeal : AppTheme.limeNeon;
    final seconds = _session.remainingSeconds.ceil();
    final time =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return PopScope(
      canPop: !_session.started || _saved,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && await _confirmReset() && context.mounted) {
          _reset(_preset);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.pop(context);
          });
        }
      },
      child: StitchAppBackground(
          child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
            title: const Text('Training lab'),
            backgroundColor: Colors.transparent),
        body: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Reveal(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('PUT IN THE REPS',
                          style: AppTheme.labelCaps
                              .copyWith(color: AppTheme.mintTeal)),
                      const SizedBox(height: 8),
                      Text('Build your next win.', style: AppTheme.headlineXl),
                      const SizedBox(height: 10),
                      Text(
                          'A little practice. A stronger game. Pick a drill and find your rhythm.',
                          style: AppTheme.bodyMd
                              .copyWith(color: AppTheme.textMuted)),
                    ])),
                const SizedBox(height: 22),
                Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                        TrainingPlan.presets.length,
                        (i) => ChoiceChip(
                            label: Text(['Footwork', 'Smash', 'Endurance'][i]),
                            selected: _preset == i,
                            onSelected: _saving
                                ? null
                                : (_) async {
                                    if (i != _preset &&
                                        await _confirmReset() &&
                                        mounted) {
                                      _reset(i);
                                    }
                                  }))),
                const SizedBox(height: 18),
                CourtPanel(
                    accent: color,
                    child: Column(children: [
                      Text(plan.focus,
                          style: AppTheme.labelCaps.copyWith(color: color)),
                      const SizedBox(height: 8),
                      Text(plan.name,
                          style: AppTheme.headlineLg,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 22),
                      Semantics(
                          label:
                              '${_session.resting ? 'Rest' : 'Work'}, $seconds seconds remaining, round ${_session.round} of ${plan.rounds}',
                          child: ExcludeSemantics(
                              child: SizedBox(
                                  width: 230,
                                  height: 230,
                                  child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox.expand(
                                            child: CircularProgressIndicator(
                                                value: _session.phaseProgress,
                                                color: color,
                                                backgroundColor:
                                                    AppTheme.borderDark,
                                                strokeWidth: 5,
                                                strokeCap: StrokeCap.round)),
                                        Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                  _session.completed
                                                      ? 'GREAT WORK'
                                                      : _session.resting
                                                          ? 'BREATHE'
                                                          : _session.running
                                                              ? 'LET’S GO'
                                                              : _session.started
                                                                  ? 'PAUSED'
                                                                  : 'READY?',
                                                  style: AppTheme.labelCaps
                                                      .copyWith(color: color)),
                                              const SizedBox(height: 6),
                                              if (_session.completed)
                                                const Icon(Icons.check_rounded,
                                                    size: 78,
                                                    color: AppTheme.limeNeon)
                                              else
                                                Text(time,
                                                    style:
                                                        AppTheme.jetBrainsMono(
                                                            size: 52,
                                                            weight:
                                                                FontWeight.w800,
                                                            letterSpacing: -3)),
                                              Text(
                                                  'ROUND ${_session.round} / ${plan.rounds}',
                                                  style: AppTheme.labelCaps
                                                      .copyWith(
                                                          color: AppTheme
                                                              .textMuted)),
                                            ]),
                                      ])))),
                      const SizedBox(height: 22),
                      Text(
                          _session.completed
                              ? 'That’s another step toward your best game.'
                              : _session.resting
                                  ? 'Shake it out. Your next round is coming.'
                                  : plan.cue,
                          style: AppTheme.bodyMd
                              .copyWith(color: AppTheme.textMuted),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 20,
                          runSpacing: 8,
                          children: [
                            _detail('${plan.workSeconds}s', 'WORK'),
                            _detail('${plan.restSeconds}s', 'REST'),
                            _detail(
                                '${plan.totalSeconds ~/ 60}:${(plan.totalSeconds % 60).toString().padLeft(2, '0')}',
                                'TOTAL'),
                          ]),
                      const SizedBox(height: 22),
                      if (!_session.completed)
                        SizedBox(
                            width: double.infinity,
                            child: PressScale(
                                child: FilledButton.icon(
                              onPressed: _session.running ? _pause : _start,
                              icon: Icon(_session.running
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded),
                              label: Text(_session.running
                                  ? 'PAUSE WORKOUT'
                                  : _session.started
                                      ? 'RESUME WORKOUT'
                                      : 'START WORKOUT'),
                            )))
                      else if (_saveError != null)
                        TextButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.refresh),
                            label:
                                Text(_saveError!, textAlign: TextAlign.center))
                      else
                        Text(
                            _saving
                                ? 'Saving your workout…'
                                : 'Workout saved on this device',
                            style: AppTheme.bodyMd
                                .copyWith(color: AppTheme.mintTeal)),
                      if (_session.started || _session.completed)
                        TextButton(
                            onPressed: _saving
                                ? null
                                : () async {
                                    if (await _confirmReset() && mounted) {
                                      _reset(_preset);
                                    }
                                  },
                            child: Text(_saved ? 'TRAIN AGAIN' : 'RESET')),
                    ])),
                const SizedBox(height: 28),
                Text('YOUR TRAINING LOG', style: AppTheme.labelCaps),
                const SizedBox(height: 8),
                Text(
                    'Completed workouts stay on this device. Aim for three this week.',
                    style: AppTheme.bodySm.copyWith(color: AppTheme.textMuted)),
                const SizedBox(height: 16),
                if (_playerId != null)
                  ref.watch(trainingHistoryProvider(_playerId!)).when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => TextButton(
                          onPressed: () => ref
                              .invalidate(trainingHistoryProvider(_playerId!)),
                          child: const Text('Retry training history')),
                      data: (records) {
                        final today = DateUtils.dateOnly(DateTime.now());
                        final weekStart =
                            today.subtract(Duration(days: today.weekday - 1));
                        final thisWeek = records
                            .where((r) => !r.completedAt.isBefore(weekStart))
                            .length;
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$thisWeek / 3 workouts this week',
                                  style: AppTheme.headlineMd),
                              const SizedBox(height: 10),
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                      value: (thisWeek / 3).clamp(0, 1),
                                      minHeight: 5,
                                      backgroundColor: AppTheme.cardMid)),
                              const SizedBox(height: 16),
                              if (records.isEmpty)
                                Text(
                                    'Your first session starts above. You’ve got this.',
                                    style: AppTheme.bodyMd
                                        .copyWith(color: AppTheme.textMuted)),
                              for (final record in records.take(10))
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.task_alt,
                                      color: AppTheme.mintTeal),
                                  title:
                                      Text(record.name, style: AppTheme.bodyLg),
                                  subtitle: Text(
                                      '${record.rounds} rounds · ${DateFormat('d MMM, h:mm a').format(record.completedAt.toLocal())}'),
                                  trailing: Text('${record.seconds ~/ 60}m',
                                      style: AppTheme.statBadge),
                                ),
                            ]);
                      }),
              ]),
        )),
      )),
    );
  }

  Widget _detail(String value, String label) => Column(children: [
        Text(value, style: AppTheme.statBadge),
        const SizedBox(height: 4),
        Text(label,
            style: AppTheme.labelCaps.copyWith(color: AppTheme.textMuted)),
      ]);
}
