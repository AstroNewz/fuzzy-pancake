import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../../core/utils/bwf_scoring_rules.dart';
import '../../trump_card/trump_card_model.dart';

class ClubPlayer {
  const ClubPlayer(
      {required this.id,
      required this.name,
      required this.ovr,
      required this.elo,
      this.avatar});
  final String id, name;
  final int ovr, elo;
  final String? avatar;
  factory ClubPlayer.fromCard(TrumpCardModel card) => ClubPlayer(
      id: card.playerId,
      name: card.fullName,
      ovr: card.ovrRating,
      elo: card.eloRating,
      avatar: card.avatarUrl);
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'ovr': ovr, 'elo': elo, 'avatar': avatar};
  factory ClubPlayer.fromJson(Map<String, dynamic> j) => ClubPlayer(
      id: j['id'],
      name: j['name'],
      ovr: j['ovr'],
      elo: j['elo'],
      avatar: j['avatar']);
}

class TournamentSide {
  TournamentSide({required this.id, required this.players, required this.seed});
  final String id;
  final List<ClubPlayer> players;
  final int seed;
  String get name => players.map((p) => p.name).join(' / ');
  int get ovr =>
      (players.fold<int>(0, (n, p) => n + p.ovr) / players.length).round();
  Map<String, dynamic> toJson() => {
        'id': id,
        'players': players.map((p) => p.toJson()).toList(),
        'seed': seed
      };
  factory TournamentSide.fromJson(Map<String, dynamic> j) => TournamentSide(
      id: j['id'],
      seed: j['seed'],
      players: (j['players'] as List)
          .map((p) => ClubPlayer.fromJson(Map<String, dynamic>.from(p)))
          .toList());
}

class TournamentMatch {
  TournamentMatch(
      {required this.id,
      required this.round,
      required this.index,
      this.sideA,
      this.sideB,
      this.sourceA,
      this.sourceB,
      this.thirdPlace = false,
      this.status = 'scheduled',
      this.winnerId,
      this.sets = const []});
  final String id;
  final int round, index;
  final String? sourceA, sourceB;
  final bool thirdPlace;
  String? sideA, sideB, winnerId;
  String status;
  List<Map<String, int>> sets;
  bool get finished => status == 'completed' || status == 'bye';
  bool get playable => !finished && sideA != null && sideB != null;
  String? get loserId => winnerId == sideA ? sideB : sideA;
  Map<String, dynamic> toJson() => {
        'id': id,
        'round': round,
        'index': index,
        'sourceA': sourceA,
        'sourceB': sourceB,
        'thirdPlace': thirdPlace,
        'sideA': sideA,
        'sideB': sideB,
        'winnerId': winnerId,
        'status': status,
        'sets': sets
      };
  factory TournamentMatch.fromJson(Map<String, dynamic> j) => TournamentMatch(
      id: j['id'],
      round: j['round'],
      index: j['index'],
      sourceA: j['sourceA'],
      sourceB: j['sourceB'],
      thirdPlace: j['thirdPlace'] == true,
      sideA: j['sideA'],
      sideB: j['sideB'],
      winnerId: j['winnerId'],
      status: j['status'],
      sets: (j['sets'] as List).map((s) => Map<String, int>.from(s)).toList());
}

class BracketRound {
  const BracketRound(this.name, this.matches);
  final String name;
  final List<TournamentMatch> matches;
}

class LeagueEntry {
  LeagueEntry(this.side);
  final TournamentSide side;
  int played = 0,
      won = 0,
      lost = 0,
      setsWon = 0,
      setsLost = 0,
      pointsFor = 0,
      pointsAgainst = 0;
  int get points => won * 2;
  int get pointDifference => pointsFor - pointsAgainst;
  int get setDifference => setsWon - setsLost;
}

class Tournament {
  Tournament(
      {required this.id,
      required this.name,
      required this.format,
      required this.doubles,
      required this.pointCap,
      required this.createdAt,
      required this.sides,
      required this.matches});
  final String id, name, format;
  final bool doubles;
  final int pointCap;
  final DateTime createdAt;
  final List<TournamentSide> sides;
  final List<TournamentMatch> matches;
  TournamentSide? side(String? id) =>
      sides.where((s) => s.id == id).firstOrNull;
  bool get completed => matches.isNotEmpty && matches.every((m) => m.finished);
  TournamentMatch? get finalMatch => format == 'league'
      ? null
      : matches.where((m) => !m.thirdPlace).lastOrNull;
  TournamentSide? get champion => format == 'league'
      ? (completed ? standings.first.side : null)
      : side(finalMatch?.winnerId);
  List<BracketRound> get rounds {
    final main = matches.where((m) => !m.thirdPlace).toList();
    final total = main.map((m) => m.round).fold<int>(0, max) + 1;
    return [
      for (var r = 0; r < total; r++)
        BracketRound(
            format == 'league'
                ? 'Matchday ${r + 1}'
                : switch (total - r) {
                    1 => 'Final',
                    2 => 'Semi-finals',
                    3 => 'Quarter-finals',
                    _ => 'Round of ${1 << (total - r)}'
                  },
            main.where((m) => m.round == r).toList()),
      if (matches.any((m) => m.thirdPlace))
        BracketRound('3rd place', matches.where((m) => m.thirdPlace).toList())
    ];
  }

  static Tournament create(
      {required String name,
      required String format,
      required bool doubles,
      required int pointCap,
      required List<ClubPlayer> players,
      bool randomDraw = false,
      Random? random}) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Give your tournament a name.');
    }
    if (!['knockout', 'league'].contains(format) ||
        ![11, 15, 21].contains(pointCap)) {
      throw ArgumentError('Choose a supported format and point cap.');
    }
    if (players.map((p) => p.id).toSet().length != players.length) {
      throw ArgumentError('A player cannot enter twice.');
    }
    if (players.length < (doubles ? 4 : 2) ||
        players.length > 32 ||
        (doubles && players.length.isOdd)) {
      throw ArgumentError(
          'Select 2–32 players, or an even number of at least 4 for doubles.');
    }
    final ordered = List<ClubPlayer>.from(players);
    if (randomDraw) {
      ordered.shuffle(random ?? Random.secure());
    } else {
      ordered.sort((a, b) => b.elo.compareTo(a.elo));
    }
    final sides = <TournamentSide>[];
    for (var i = 0; i < ordered.length; i += doubles ? 2 : 1) {
      sides.add(TournamentSide(
          id: const Uuid().v4(),
          players: ordered.sublist(i, i + (doubles ? 2 : 1)),
          seed: sides.length + 1));
    }
    final matches = <TournamentMatch>[];
    if (format == 'league') {
      final rotation = <String?>[
        ...sides.map((s) => s.id),
        if (sides.length.isOdd) null
      ];
      for (var r = 0; r < rotation.length - 1; r++) {
        for (var i = 0; i < rotation.length ~/ 2; i++) {
          final a = rotation[i], b = rotation[rotation.length - 1 - i];
          if (a != null && b != null) {
            matches.add(TournamentMatch(
                id: const Uuid().v4(), round: r, index: i, sideA: a, sideB: b));
          }
        }
        rotation.insert(1, rotation.removeLast());
      }
    } else {
      var size = 2;
      var seeds = [1, 2];
      while (size < sides.length) {
        size *= 2;
        seeds = seeds.expand((s) => [s, size + 1 - s]).toList();
      }
      var previous = <TournamentMatch>[];
      for (var r = 0, count = size ~/ 2; count >= 1; r++, count ~/= 2) {
        final current = <TournamentMatch>[];
        for (var i = 0; i < count; i++) {
          String? seeded(int slot) =>
              seeds[slot] <= sides.length ? sides[seeds[slot] - 1].id : null;
          current.add(TournamentMatch(
              id: const Uuid().v4(),
              round: r,
              index: i,
              sideA: r == 0 ? seeded(i * 2) : null,
              sideB: r == 0 ? seeded(i * 2 + 1) : null,
              sourceA: r == 0 ? null : previous[i * 2].id,
              sourceB: r == 0 ? null : previous[i * 2 + 1].id));
        }
        if (count == 1 && previous.length == 2) {
          matches.add(TournamentMatch(
              id: const Uuid().v4(),
              round: r,
              index: 0,
              sourceA: previous[0].id,
              sourceB: previous[1].id,
              thirdPlace: true));
        }
        matches.addAll(current);
        previous = current;
      }
    }
    final tournament = Tournament(
        id: const Uuid().v4(),
        name: name.trim(),
        format: format,
        doubles: doubles,
        pointCap: pointCap,
        createdAt: DateTime.now(),
        sides: sides,
        matches: matches);
    tournament._advance();
    return tournament;
  }

  void completeMatch(String matchId, List<Map<String, int>> scores) {
    final match = matches.firstWhere((m) => m.id == matchId);
    if (match.finished) {
      if (match.sets.toString() == scores.toString()) return;
      throw StateError(
          'This result is already final. Downstream matches must not be rewritten.');
    }
    if (!match.playable) {
      throw StateError(
          'Both players must qualify before this match can start.');
    }
    var winsA = 0, winsB = 0;
    if (scores.isEmpty || scores.length > 3) {
      throw ArgumentError('Enter two winning sets in a best-of-three match.');
    }
    for (final set in scores) {
      if (winsA == 2 || winsB == 2) {
        throw ArgumentError('Remove sets played after the match was won.');
      }
      final w = BwfScoringRules.getSetWinner(set['a'] ?? -1, set['b'] ?? -1,
          targetPoints: pointCap);
      if (w == null) {
        throw ArgumentError(
            'A set must reach $pointCap with a two-point lead, or the ${pointCap + 9}-point ceiling.');
      }
      if (w == 'A') {
        winsA++;
      } else {
        winsB++;
      }
    }
    if (winsA != 2 && winsB != 2) {
      throw ArgumentError('A best-of-three match needs two winning sets.');
    }
    match.sets = scores.map((s) => Map<String, int>.from(s)).toList();
    match.status = 'completed';
    match.winnerId = winsA == 2 ? match.sideA : match.sideB;
    _advance();
  }

  void _advance() {
    if (format == 'league') return;
    for (final match in matches) {
      if (match.finished) continue;
      bool ready = true;
      if (match.sourceA != null) {
        final a = matches.firstWhere((m) => m.id == match.sourceA),
            b = matches.firstWhere((m) => m.id == match.sourceB);
        ready = a.finished && b.finished;
        match.sideA = match.thirdPlace ? a.loserId : a.winnerId;
        match.sideB = match.thirdPlace ? b.loserId : b.winnerId;
      }
      if (ready && (match.sideA == null || match.sideB == null)) {
        match.status = 'bye';
        match.winnerId = match.sideA ?? match.sideB;
      }
    }
  }

  List<LeagueEntry> get standings {
    final rows = {for (final s in sides) s.id: LeagueEntry(s)};
    void count(Map<String, LeagueEntry> table, TournamentMatch m) {
      final a = table[m.sideA], b = table[m.sideB];
      if (a == null || b == null) return;
      a.played++;
      b.played++;
      if (m.winnerId == a.side.id) {
        a.won++;
        b.lost++;
      } else {
        b.won++;
        a.lost++;
      }
      for (final s in m.sets) {
        final x = s['a']!, y = s['b']!;
        a.pointsFor += x;
        a.pointsAgainst += y;
        b.pointsFor += y;
        b.pointsAgainst += x;
        if (x > y) {
          a.setsWon++;
          b.setsLost++;
        } else {
          b.setsWon++;
          a.setsLost++;
        }
      }
    }

    final finished =
        matches.where((m) => m.status == 'completed' && !m.thirdPlace).toList();
    for (final m in finished) {
      count(rows, m);
    }
    final result = rows.values.toList();
    // Mini-tables for all equal-points groups keep three-way ties transitive.
    final mini = <int, Map<String, LeagueEntry>>{};
    for (final row in result) {
      mini.putIfAbsent(
          row.points,
          () => {
                for (final r in result.where((r) => r.points == row.points))
                  r.side.id: LeagueEntry(r.side)
              });
    }
    for (final table in mini.values) {
      for (final m in finished) {
        count(table, m);
      }
    }
    result.sort((a, b) {
      var n = b.points.compareTo(a.points);
      if (n != 0) return n;
      final table = mini[a.points]!,
          x = table[a.side.id]!,
          y = table[b.side.id]!;
      for (final pair in [
        (y.points, x.points),
        (y.setDifference, x.setDifference),
        (y.pointDifference, x.pointDifference),
        (b.setDifference, a.setDifference),
        (b.pointDifference, a.pointDifference)
      ]) {
        n = pair.$1.compareTo(pair.$2);
        if (n != 0) return n;
      }
      return a.side.seed.compareTo(b.side.seed);
    });
    return result;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'format': format,
        'doubles': doubles,
        'pointCap': pointCap,
        'createdAt': createdAt.toIso8601String(),
        'sides': sides.map((s) => s.toJson()).toList(),
        'matches': matches.map((m) => m.toJson()).toList()
      };
  factory Tournament.fromJson(Map<String, dynamic> j) => Tournament(
      id: j['id'],
      name: j['name'],
      format: j['format'],
      doubles: j['doubles'],
      pointCap: j['pointCap'],
      createdAt: DateTime.parse(j['createdAt']),
      sides: (j['sides'] as List)
          .map((s) => TournamentSide.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      matches: (j['matches'] as List)
          .map((m) => TournamentMatch.fromJson(Map<String, dynamic>.from(m)))
          .toList());
}
