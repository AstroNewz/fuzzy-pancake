import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smashdeck/features/training/training_history.dart';
import 'package:smashdeck/features/training/training_session.dart';
import 'package:smashdeck/core/theme/appearance_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('intervals switch at boundaries without adding a final rest', () {
    final session = TrainingSession(TrainingPlan.presets.first)..start();
    session.advance(const Duration(seconds: 30));
    expect(session.resting, isTrue);
    expect(session.round, 1);
    expect(session.remainingSeconds, 15);
    session.advance(const Duration(seconds: 15));
    expect(session.resting, isFalse);
    expect(session.round, 2);
    expect(session.remainingSeconds, 30);
    session.advance(const Duration(seconds: 209));
    expect(session.completed, isFalse);
    expect(session.round, 6);
    expect(session.remainingSeconds, 1);
    session.advance(const Duration(seconds: 1));
    expect(session.completed, isTrue);
    expect(session.running, isFalse);
    expect(session.elapsed.inSeconds, 255);
  });

  test('pause freezes progress and delayed ticks preserve the correct phase',
      () {
    final session = TrainingSession(TrainingPlan.presets.first)..start();
    session.advance(const Duration(milliseconds: 72500));
    expect(session.round, 2);
    expect(session.resting, isFalse);
    expect(session.remainingSeconds, 2.5);
    session.pause();
    session.advance(const Duration(minutes: 5));
    expect(session.remainingSeconds, 2.5);
    session.start();
    session.advance(const Duration(milliseconds: 3000));
    expect(session.resting, isTrue);
    expect(session.remainingSeconds, 14.5);
    session.advance(const Duration(seconds: -5));
    expect(session.remainingSeconds, 14.5);
    session.advance(const Duration(hours: 1));
    expect(session.completed, isTrue);
    expect(session.elapsed, const Duration(seconds: 255));
    session.start();
    expect(session.running, isFalse);
  });

  test('workout saves survive reload, isolate users and deduplicate retries',
      () async {
    final repository = TrainingHistoryRepository();
    final first = TrainingRecord(
        id: 'a',
        name: 'Footwork',
        completedAt: DateTime(2026, 9, 18),
        seconds: 255,
        rounds: 6);
    final second = TrainingRecord(
        id: 'b',
        name: 'Endurance',
        completedAt: DateTime(2026, 9, 19),
        seconds: 870,
        rounds: 10);
    await Future.wait([
      repository.save('player-a', first),
      repository.save('player-a', first),
      repository.save('player-a', second)
    ]);
    final restored = await TrainingHistoryRepository().read('player-a');
    expect(restored.map((r) => r.id), ['b', 'a']);
    expect(restored.last.rounds, 6);
    expect(await repository.read('player-b'), isEmpty);
  });

  test('appearance changes preserve both preferences during concurrent writes',
      () async {
    final controller = AppearanceController();
    addTearDown(controller.dispose);
    await Future.wait(
        [controller.update(grain: 1), controller.update(reduceMotion: true)]);
    expect(controller.state.grain, 1);
    expect(controller.state.reduceMotion, isTrue);
    final restored = AppearanceController();
    addTearDown(restored.dispose);
    await restored.update();
    expect(restored.state.grain, 1);
    expect(restored.state.reduceMotion, isTrue);
  });
}
