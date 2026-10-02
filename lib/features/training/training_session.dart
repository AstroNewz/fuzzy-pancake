class TrainingPlan {
  const TrainingPlan(
      {required this.name,
      required this.focus,
      required this.cue,
      required this.workSeconds,
      required this.restSeconds,
      required this.rounds});
  final String name;
  final String focus;
  final String cue;
  final int workSeconds;
  final int restSeconds;
  final int rounds;
  int get totalSeconds => rounds * workSeconds + (rounds - 1) * restSeconds;

  static const presets = [
    TrainingPlan(
        name: 'Six-corner footwork',
        focus: 'SPEED & AGILITY',
        cue: 'Split step. Reach the corner. Recover to base.',
        workSeconds: 30,
        restSeconds: 15,
        rounds: 6),
    TrainingPlan(
        name: 'Smash & recover',
        focus: 'POWER & CONTROL',
        cue: 'Stay balanced. Contact high. Reset after every shot.',
        workSeconds: 45,
        restSeconds: 20,
        rounds: 8),
    TrainingPlan(
        name: 'Rally endurance',
        focus: 'STAMINA & CONSISTENCY',
        cue: 'Keep your rhythm. Breathe out on contact. Stay light.',
        workSeconds: 60,
        restSeconds: 30,
        rounds: 10),
  ];
}

/// Elapsed-time based intervals avoid drift and handle delayed timer callbacks.
class TrainingSession {
  TrainingSession(this.plan);
  final TrainingPlan plan;
  Duration elapsed = Duration.zero;
  bool running = false;
  bool get completed => elapsed.inMicroseconds >= plan.totalSeconds * 1000000;
  bool get started => elapsed > Duration.zero || running;
  int get round => completed
      ? plan.rounds
      : elapsed.inSeconds ~/ (plan.workSeconds + plan.restSeconds) + 1;
  double get _phaseSeconds =>
      elapsed.inMicroseconds / 1000000 % (plan.workSeconds + plan.restSeconds);
  bool get resting => !completed && _phaseSeconds >= plan.workSeconds;
  double get remainingSeconds => completed
      ? 0
      : resting
          ? plan.workSeconds + plan.restSeconds - _phaseSeconds
          : plan.workSeconds - _phaseSeconds;
  double get phaseProgress => completed
      ? 1
      : 1 - remainingSeconds / (resting ? plan.restSeconds : plan.workSeconds);
  void start() {
    if (!completed) running = true;
  }

  void pause() {
    running = false;
  }

  void advance(Duration delta) {
    if (!running || delta.isNegative) return;
    final next = elapsed + delta;
    final total = Duration(seconds: plan.totalSeconds);
    elapsed = next > total ? total : next;
    if (completed) running = false;
  }
}
