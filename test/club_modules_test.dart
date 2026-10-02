import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smashdeck/core/services/audio_umpire_service.dart';
import 'package:smashdeck/features/tournament/models/tournament_model.dart';
import 'package:smashdeck/features/tournament/providers/tournament_state.dart';
import 'package:smashdeck/features/court_queue/models/court_session_model.dart';
import 'package:smashdeck/features/court_queue/providers/court_queue_state.dart';
import 'package:smashdeck/features/attendance/attendance_repository.dart';
import 'package:smashdeck/features/doubles/models/doubles_pair_model.dart';
import 'package:smashdeck/features/trump_card/trump_card_model.dart';
import 'package:smashdeck/features/treasury/models/treasury_model.dart';
import 'package:smashdeck/features/treasury/providers/treasury_state.dart';
import 'package:smashdeck/features/match_engine/match_engine_state.dart';
import 'package:smashdeck/features/match_engine/live_match_draft.dart';

List<ClubPlayer> players(int count) => List.generate(
    count,
    (i) => ClubPlayer(
        id: 'p$i', name: 'Player $i', ovr: 90 - i, elo: 1500 - i * 10));
List<Map<String, int>> score(int target) => [
      {'a': target, 'b': 5},
      {'a': target, 'b': 8}
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  SupabaseClient localClient() =>
      SupabaseClient('https://modules.example.test', 'key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((r) async => http.Response(
              jsonEncode(
                  {'code': '42P01', 'message': 'Cloud module not installed'}),
              404,
              request: r,
              headers: {'content-type': 'application/json'})));

  for (final count in [2, 3, 5, 8, 16, 20]) {
    test(
        'knockout with $count entrants advances byes and awards a real champion',
        () {
      final cup = Tournament.create(
          name: 'Cup',
          format: 'knockout',
          doubles: false,
          pointCap: 21,
          players: players(count));
      var played = 0;
      while (!cup.completed) {
        final ready = cup.matches.where((m) => m.playable).toList();
        expect(ready, isNotEmpty);
        for (final match in ready) {
          cup.completeMatch(match.id, score(21));
          played++;
        }
        expect(played, lessThanOrEqualTo(count));
      }
      expect(cup.champion, isNotNull);
      expect(
          cup.matches
              .where((m) => !m.thirdPlace && m.status == 'completed')
              .length,
          count - 1);
      expect(cup.rounds.last.name, count > 2 ? '3rd place' : 'Final');
      expect(
          Tournament.fromJson(jsonDecode(jsonEncode(cup.toJson())))
              .champion!
              .id,
          cup.champion!.id);
    });
  }
  test('standard seeding separates the top seeds until the final', () {
    final cup = Tournament.create(
        name: 'Cup',
        format: 'knockout',
        doubles: false,
        pointCap: 21,
        players: players(8));
    final opening = cup.rounds.first.matches;
    expect(
        opening
            .map((m) => [cup.side(m.sideA)!.seed, cup.side(m.sideB)!.seed])
            .toList(),
        [
          [1, 8],
          [4, 5],
          [2, 7],
          [3, 6]
        ]);
  });
  test(
      'scores reject unfinished and post-victory sets; identical retries are harmless',
      () {
    final cup = Tournament.create(
        name: 'Cup',
        format: 'knockout',
        doubles: false,
        pointCap: 11,
        players: players(2));
    final id = cup.matches.first.id;
    expect(
        () => cup.completeMatch(id, [
              {'a': 10, 'b': 8}
            ]),
        throwsArgumentError);
    expect(
        () => cup.completeMatch(id, [
              ...score(11),
              {'a': 11, 'b': 3}
            ]),
        throwsArgumentError);
    cup.completeMatch(id, score(11));
    cup.completeMatch(id, score(11));
    expect(cup.matches.first.sets.length, 2);
    expect(
        () => cup.completeMatch(id, [
              {'a': 0, 'b': 11},
              {'a': 1, 'b': 11}
            ]),
        throwsStateError);
  });
  test(
      'round robin schedules each pair once with no double booking on a matchday',
      () {
    for (final count in [3, 4, 7, 20]) {
      final cup = Tournament.create(
          name: 'League',
          format: 'league',
          doubles: false,
          pointCap: 15,
          players: players(count));
      expect(cup.matches.length, count * (count - 1) ~/ 2);
      final pairs = cup.matches.map((m) {
        final ids = [m.sideA!, m.sideB!]..sort();
        return ids.join(':');
      }).toSet();
      expect(pairs.length, cup.matches.length);
      for (final round in cup.rounds) {
        final ids = round.matches.expand((m) => [m.sideA, m.sideB]).toList();
        expect(ids.toSet().length, ids.length);
      }
    }
  });
  test('league table applies head-to-head before overall point difference', () {
    final cup = Tournament.create(
        name: 'League',
        format: 'league',
        doubles: false,
        pointCap: 21,
        players: players(4));
    final a = cup.sides[0].id,
        b = cup.sides[1].id,
        c = cup.sides[2].id,
        d = cup.sides[3].id;
    for (final m in cup.matches) {
      String winner;
      if ({m.sideA, m.sideB}.contains(a) && {m.sideA, m.sideB}.contains(b)) {
        winner = b;
      } else if ({m.sideA, m.sideB}.contains(a)) {
        winner = a;
      } else if ({m.sideA, m.sideB}.contains(b) &&
          {m.sideA, m.sideB}.contains(c)) {
        winner = c;
      } else if ({m.sideA, m.sideB}.contains(b)) {
        winner = b;
      } else {
        winner = d;
      }
      cup.completeMatch(
          m.id,
          winner == m.sideA
              ? score(21)
              : [
                  {'a': 5, 'b': 21},
                  {'a': 8, 'b': 21}
                ]);
    }
    final table = cup.standings;
    for (final entry in table) {
      expect(entry.played, 3);
      expect(entry.won + entry.lost, 3);
      expect(entry.points, entry.won * 2);
    }
    expect(table.firstWhere((r) => r.side.id == a).points,
        table.firstWhere((r) => r.side.id == b).points);
    expect(table.indexWhere((r) => r.side.id == b),
        lessThan(table.indexWhere((r) => r.side.id == a)));
  });
  test('doubles draw pairs every player once and rejects duplicate entrants',
      () {
    final list = players(8);
    final cup = Tournament.create(
        name: 'Doubles',
        format: 'knockout',
        doubles: true,
        pointCap: 21,
        players: list,
        randomDraw: true,
        random: Random(42));
    expect(cup.sides.length, 4);
    expect(
        cup.sides.expand((s) => s.players).map((p) => p.id).toSet().length, 8);
    expect(
        () => Tournament.create(
            name: 'Bad',
            format: 'league',
            doubles: true,
            pointCap: 21,
            players: players(5)),
        throwsArgumentError);
    expect(
        () => Tournament.create(
            name: 'Bad',
            format: 'league',
            doubles: false,
            pointCap: 21,
            players: [list.first, list.first]),
        throwsArgumentError);
  });
  test(
      'fair queue prioritizes fewer games then waiting time, and balances the first four',
      () {
    final now = DateTime(2026, 9, 18, 12), list = players(5);
    final queue = CourtQueueData(date: '2026-09-18', members: [
      for (var i = 0; i < 5; i++)
        QueuePlayer(
            player: list[i],
            waitingSince: now.add(Duration(minutes: i)),
            played: i == 0 ? 1 : 0)
    ]);
    expect(queue.waiting(now).map((p) => p.player.id),
        ['p1', 'p2', 'p3', 'p4', 'p0']);
    final teams = CourtQueueData.balanceDoubles(queue.waiting(now));
    final sumA = teams.$1.fold<int>(0, (n, p) => n + p.player.ovr),
        sumB = teams.$2.fold<int>(0, (n, p) => n + p.player.ovr);
    expect(sumA, sumB);
    expect([...teams.$1, ...teams.$2].map((p) => p.player.id).toSet(),
        {'p1', 'p2', 'p3', 'p4'});
  });
  test('court timer uses wall time and warm-up does not burn session time', () {
    final now = DateTime(2026, 9, 18, 12),
        session = CourtSession(id: 's', court: 1, teamA: ['a'], teamB: ['b']);
    expect(session.remaining(now), 900);
    session.startedAt = now;
    expect(session.remaining(now.add(const Duration(minutes: 14, seconds: 50))),
        10);
    expect(session.remaining(now.add(const Duration(hours: 1))), 0);
  });
  test(
      'doubles receive-side win does not swap positions; undo restores all four',
      () {
    final engine = LiveMatchNotifier();
    addTearDown(engine.dispose);
    engine.initMatch(
        matchType: 'doubles',
        teamA1Id: 'a1',
        teamA1Name: 'A1',
        teamA2Id: 'a2',
        teamA2Name: 'A2',
        teamB1Id: 'b1',
        teamB1Name: 'B1',
        teamB2Id: 'b2',
        teamB2Name: 'B2');
    expect(engine.state.serverName, 'A1');
    expect(engine.state.receiverName, 'B1');
    engine.addPointTeamA();
    expect(engine.state.serverName, 'A1');
    expect(engine.state.doublesPositions.aFirstRight, isFalse);
    engine.addPointTeamB();
    expect(engine.state.serverName, 'B2');
    expect(engine.state.receiverName, 'A1');
    expect(engine.state.doublesPositions.bFirstRight, isTrue);
    engine.addPointTeamB();
    expect(engine.state.serverName, 'B2');
    expect(engine.state.doublesPositions.bFirstRight, isFalse);
    engine.undoLastPoint();
    expect(engine.state.serverName, 'B2');
    expect(engine.state.doublesPositions.bFirstRight, isTrue);
    engine.undoLastPoint();
    expect(engine.state.servingTeam, 'A');
    expect(engine.state.serverName, 'A1');
  });
  test(
      'live drafts preserve doubles service, commentary and undo across reopen',
      () async {
    final engine = LiveMatchNotifier();
    addTearDown(engine.dispose);
    engine.initMatch(
        matchId: 'draft',
        matchType: 'doubles',
        teamA1Id: 'a1',
        teamA1Name: 'A1',
        teamA2Id: 'a2',
        teamA2Name: 'A2',
        teamB1Id: 'b1',
        teamB1Name: 'B1',
        teamB2Id: 'b2',
        teamB2Name: 'B2');
    engine.addPointTeamA();
    engine.addPointTeamB();
    engine.addPointTeamB();
    final repo = LiveMatchDraftRepository();
    await repo.save(engine.state);
    final saved = await LiveMatchDraftRepository().load('draft');
    expect(saved!.serverName, 'B2');
    expect(saved.teamBScore, 2);
    engine.restoreMatch(saved);
    engine.undoLastPoint();
    expect(engine.state.teamBScore, 1);
    expect(engine.state.doublesPositions.bFirstRight, isTrue);
    expect(engine.state.pointEvents.length, 2);
    await repo.remove('draft');
    expect(await repo.load('draft'), isNull);
  });
  test('voice calls service over, game point and match point from actual state',
      () {
    const before = LiveMatchState(
        teamAPlayer1Name: 'A',
        teamBPlayer1Name: 'B',
        teamAScore: 18,
        teamBScore: 19,
        servingTeam: 'A');
    final after = before.copyWith(teamBScore: 20, servingTeam: 'B');
    expect(AudioUmpireService.callout(before, after),
        'Service over. 20, 18. Game point.');
    expect(
        AudioUmpireService.callout(
            before,
            after.copyWith(completedSets: [
              {'a': 5, 'b': 21}
            ])),
        'Service over. 20, 18. Match point.');
  });
  test('pair win streak only includes completed matches played together', () {
    final a = fallbackSquadCards[0], b = fallbackSquadCards[1];
    final history = List.generate(
        7,
        (i) => {
              'status': 'completed',
              'created_at': '2026-09-${(20 - i).toString().padLeft(2, '0')}',
              'team_a_player1_id': a.playerId,
              'team_a_player2_id': b.playerId,
              'team_b_player1_id': 'other1',
              'team_b_player2_id': 'other2',
              'winner_team': i == 6 ? 'B' : 'A'
            });
    final pair = DoublesPair.fromHistory(a, b, history);
    expect(pair.consecutiveWins, 6);
    expect(pair.matches, 7);
    expect(pair.wins, 6);
    final base = DoublesPair(first: a, second: b).chemistry;
    expect(pair.chemistry, (base + 2).clamp(0, 100));
    expect(DoublesPair.fromHistory(b, a, history).chemistry, pair.chemistry);
  });
  test(
      'money remains integer minor units and CSV neutralizes spreadsheet formulas',
      () {
    expect(parseMoney('500.25'), 50025);
    expect(parseMoney('0.01'), 1);
    expect(() => parseMoney('5.123'), throwsArgumentError);
    expect(() => parseMoney('-2'), throwsArgumentError);
    final ledger = TreasuryData(fees: [
      MembershipFee(
          playerId: 'x',
          name: '=IMPORTXML("bad")',
          month: '2026-09',
          amountMinor: 50000,
          status: 'paid',
          paidAt: DateTime(2026, 9, 3))
    ], logs: [
      InventoryLog(
          id: '1',
          type: 'expense',
          date: DateTime(2026, 9, 4),
          note: 'Courts',
          amountMinor: 15000)
    ]);
    expect(ledger.balance('2026-09').remainingMinor, 35000);
    expect(ledger.csv('2026-09'), contains("'=IMPORTXML"));
    expect(ledger.balance('2026-10').openingMinor, 35000);
  });
  test(
      'inventory and dues persist, never go negative, and concurrent writes survive',
      () async {
    final client = localClient();
    addTearDown(client.dispose);
    final store = TreasuryNotifier(client);
    addTearDown(store.dispose);
    await store.ready;
    await store.purchase('Yonex', 'AS30', 2, 240000, 12);
    final id = store.state.requireValue.stocks.first.id;
    await store.openTube(id);
    expect(store.state.requireValue.stocks.first.fullTubes, 1);
    expect(store.state.requireValue.stocks.first.loose, 12);
    await store.consume(id, 3, 2);
    expect(store.state.requireValue.stocks.first.remaining, 21);
    await expectLater(store.consume(id, 10, 1), throwsArgumentError);
    expect(store.state.requireValue.stocks.first.loose, 9);
    await Future.wait(
        [store.expense('Court 1', 10000), store.expense('Court 2', 12000)]);
    await store.createDues('2026-09', players(2), 50000, 'INR');
    await store.createDues('2026-09', players(2), 50000, 'INR');
    expect(store.state.requireValue.fees.length, 2);
    await store.payment(
        'p0', '2026-09', 'paid', 'UPI', 'ref', DateTime(2026, 9, 1));
    final restored = TreasuryNotifier(client);
    addTearDown(restored.dispose);
    await restored.ready;
    expect(restored.state.requireValue.stocks.first.remaining, 21);
    expect(
        restored.state.requireValue.logs
            .where((l) => l.type == 'expense')
            .length,
        2);
  });
  test('court allocation prevents double booking and duplicate rotations',
      () async {
    final client = localClient();
    addTearDown(client.dispose);
    final store = CourtQueueNotifier(client);
    addTearDown(store.dispose);
    await store.ready;
    final now = DateTime.now();
    final logs = players(4)
        .map((p) => AttendanceRecord(
            id: p.id,
            playerId: p.id,
            sessionDate: courtDay(),
            checkInTime: now,
            verifiedByAdmin: true))
        .toList();
    await store.importAttendance(logs, players(4));
    await store.allocate(1, ['p0'], ['p1']);
    await expectLater(store.allocate(2, ['p0'], ['p2']), throwsStateError);
    final id = store.state.requireValue.courts.first.id;
    await store.start(id);
    await store.finish(id);
    await store.finish(id);
    expect(store.state.requireValue.members.first.played, 1);
    expect(store.state.requireValue.resting(DateTime.now()).length, 2);
  });
  test(
      'remote revision conflict preserves local edits and blocks blind overwrites',
      () async {
    final client = SupabaseClient('https://conflict.example.test', 'key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
      if (r.url.path.contains('/rpc/'))
        return http.Response(
            jsonEncode({'code': '40001', 'message': 'Conflict'}), 409,
            request: r, headers: {'content-type': 'application/json'});
      return http.Response('[]', 200,
          request: r, headers: {'content-type': 'application/json'});
    }));
    addTearDown(client.dispose);
    final store = TournamentNotifier(client);
    addTearDown(store.dispose);
    await store.ready;
    await store.create(Tournament.create(
        name: 'Local cup',
        format: 'knockout',
        doubles: false,
        pointCap: 21,
        players: players(2)));
    expect(store.hasConflict, isTrue, reason: store.status.value);
    expect(store.state.requireValue.cups.single.name, 'Local cup');
    await expectLater(
        store.create(Tournament.create(
            name: 'Another',
            format: 'knockout',
            doubles: false,
            pointCap: 21,
            players: players(2))),
        throwsStateError);
  });
}
