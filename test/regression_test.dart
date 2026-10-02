import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smashdeck/core/network/offline_sync_service.dart';
import 'package:smashdeck/core/utils/bwf_scoring_rules.dart';
import 'package:smashdeck/features/match_engine/match_engine_state.dart';
import 'package:smashdeck/features/match_engine/match_repository.dart';
import 'package:smashdeck/features/attendance/attendance_repository.dart';
import 'package:smashdeck/features/trump_card/trump_card_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  LiveMatchNotifier match({int bestOf = 1}) {
    final notifier = LiveMatchNotifier();
    notifier.initMatch(
        teamA1Id: 'a',
        teamA1Name: 'A',
        teamB1Id: 'b',
        teamB1Name: 'B',
        bestOfSets: bestOf);
    addTearDown(notifier.dispose);
    return notifier;
  }

  test('undoing a winning rally clears the winner and permits continued play',
      () {
    final game = match();
    final id = game.state.matchId;
    for (var i = 0; i < 21; i++) {
      game.addPointTeamA();
    }
    expect(game.state.isMatchCompleted, isTrue);
    expect(game.state.matchWinner, 'A');
    game.undoLastPoint();
    expect(game.state.isMatchCompleted, isFalse);
    expect(game.state.matchWinner, isNull);
    expect(game.state.completedSets, isEmpty);
    expect(game.state.teamAScore, 20);
    game.addPointTeamB();
    expect(game.state.teamBScore, 1);
    expect(game.state.matchId, id);
    expect(id, isNotNull);
  });

  test('undo across a set boundary restores score, server and commentary', () {
    final game = match(bestOf: 3);
    for (var i = 0; i < 21; i++) {
      game.addPointTeamA();
    }
    expect(game.state.currentSet, 2);
    game.undoLastPoint();
    expect(game.state.currentSet, 1);
    expect(game.state.teamAScore, 20);
    expect(game.state.pointEvents.length, 20);
    expect(game.state.servingTeam, 'A');
  });

  test('pause blocks scores and started matches cannot change format', () {
    final game = match();
    game.togglePause();
    game.addPointTeamA();
    game.addPointTeamB();
    expect(game.state.undoStack, isEmpty);
    game.togglePause();
    game.addPointTeamA();
    game.setTargetPoints(11);
    game.setBestOfSets(5);
    expect(game.state.targetPoints, 21);
    expect(game.state.bestOfSets, 1);
  });

  test('interval is acknowledged by the umpire, not before UI can show it', () {
    final game = match();
    for (var i = 0; i < 11; i++) {
      game.addPointTeamA();
    }
    expect(game.state.hasIntervalTriggered, isFalse);
    game.markIntervalAcknowledged();
    expect(game.state.hasIntervalTriggered, isTrue);
  });

  test('invalid, tied, over-ceiling and post-victory scores are rejected', () {
    for (final score in [
      [-1, 21],
      [30, 30],
      [31, 29],
      [22, 10],
      [30, 20],
      [21, 20]
    ]) {
      expect(BwfScoringRules.isSetWon(score[0], score[1]), isFalse,
          reason: score.toString());
    }
    expect(BwfScoringRules.isSetWon(30, 28), isTrue);
    expect(BwfScoringRules.isSetWon(11, 9, targetPoints: 11), isTrue);
  });

  test('malformed attendance dates and tokens are rejected', () {
    for (final payload in [
      'SMASHDECK:2026-02-31:123456',
      'SMASHDECK:today:123456',
      'SMASHDECK:2026-09-17:abc123',
      'SMASHDECK:2026-09-17:'
    ]) {
      expect(AttendanceRepository.parseQrPayload(payload), isNull);
    }
  });

  test('real card identity and rank are not replaced by hard-coded players',
      () {
    final card = TrumpCardModel.fromMap({
      'id': 'p',
      'full_name': 'Marvin Joseph',
      'roll_number': 'SD-0003',
      'ladder_rank': 6
    });
    expect(card.ladderRank, 6);
    expect(card.matchesPlayed, 0);
    expect(card.matchesWon, 0);
  });

  test(
      'concurrent local writes are retained and duplicate match IDs are replaced',
      () async {
    final client = SupabaseClient('https://example.test', 'test-key');
    addTearDown(client.dispose);
    final sync = OfflineSyncService(client);
    await Future.wait(List.generate(
        20,
        (i) => sync
            .queueMatchResult(matchData: {'id': 'match-$i'}, setsData: [])));
    expect(await sync.getPendingRecordsCount(), 20);
    await sync.queueMatchResult(matchData: {'id': 'match-0'}, setsData: []);
    expect(await sync.getPendingRecordsCount(), 20);
    await Future.wait(List.generate(
        4,
        (_) => sync.queueAttendanceCheckIn(
            playerId: 'p',
            sessionDate: '2026-09-17',
            totpToken: '123456',
            checkInTime: DateTime(2026, 9, 17))));
    expect(await sync.getPendingRecordsCount(), 21);
  });

  test('match is staged before sets and only then completed, once per save ID',
      () async {
    final requests = <http.Request>[];
    final client = SupabaseClient('https://example.test', 'test-key',
        httpClient: MockClient((request) async {
      requests.add(request);
      return http.Response('', 204,
          headers: {'content-type': 'application/json'}, request: request);
    }));
    addTearDown(client.dispose);
    final sync = OfflineSyncService(client);
    final repository = MatchRepository(client, sync);
    final result = await repository.saveCompletedMatch(
        existingMatchId: 'match-1',
        matchType: 'singles',
        category: 'practice',
        teamA1Id: 'a',
        teamB1Id: 'b',
        winnerTeam: 'A',
        sets: [
          {'a': 21, 'b': 18},
          {'a': 21, 'b': 15}
        ]);
    expect(result.isOffline, isFalse);
    expect(requests.length, 3);
    expect(jsonDecode(requests[0].body)['status'], 'in_progress');
    expect(requests[0].headers['Prefer'], contains('ignore-duplicates'));
    expect(requests[1].url.path, endsWith('match_sets'));
    expect(requests[2].method, 'PATCH');
    expect(requests[2].url.queryParameters['status'], 'neq.completed');
    expect(jsonDecode(requests[2].body)['status'], 'completed');
    expect(await sync.getPendingRecordsCount(), 0);
  });

  test('network failure leaves a durable result for retry', () async {
    final client = SupabaseClient('https://example.test', 'test-key',
        httpClient:
            MockClient((_) async => throw http.ClientException('offline')));
    addTearDown(client.dispose);
    final sync = OfflineSyncService(client);
    final result = await MatchRepository(client, sync).saveCompletedMatch(
        existingMatchId: 'offline-1',
        matchType: 'singles',
        category: 'practice',
        teamA1Id: 'a',
        teamB1Id: 'b',
        winnerTeam: 'B',
        sets: [
          {'a': 18, 'b': 21}
        ],
        bestOfSets: 1);
    expect(result.isOffline, isTrue);
    expect(await sync.getPendingRecordsCount(), 1);
  });
}
