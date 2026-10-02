import '../../tournament/models/tournament_model.dart';

class QueuePlayer {
  QueuePlayer(
      {required this.player,
      required this.waitingSince,
      this.played = 0,
      this.cooldownUntil});
  final ClubPlayer player;
  DateTime waitingSince;
  int played;
  DateTime? cooldownUntil;
  Map<String, dynamic> toJson() => {
        'player': player.toJson(),
        'waitingSince': waitingSince.toIso8601String(),
        'played': played,
        'cooldownUntil': cooldownUntil?.toIso8601String()
      };
  factory QueuePlayer.fromJson(Map<String, dynamic> j) => QueuePlayer(
      player: ClubPlayer.fromJson(Map<String, dynamic>.from(j['player'])),
      waitingSince: DateTime.parse(j['waitingSince']),
      played: j['played'],
      cooldownUntil: j['cooldownUntil'] == null
          ? null
          : DateTime.parse(j['cooldownUntil']));
}

class CourtSession {
  CourtSession(
      {required this.id,
      required this.court,
      required this.teamA,
      required this.teamB,
      this.startedAt,
      this.durationSeconds = 900});
  final String id;
  final int court, durationSeconds;
  final List<String> teamA, teamB;
  DateTime? startedAt;
  String get status => startedAt == null ? 'Warm-up' : 'In Play';
  List<String> get players => [...teamA, ...teamB];
  int remaining(DateTime now) => startedAt == null
      ? durationSeconds
      : (durationSeconds - now.difference(startedAt!).inSeconds)
          .clamp(0, durationSeconds);
  Map<String, dynamic> toJson() => {
        'id': id,
        'court': court,
        'teamA': teamA,
        'teamB': teamB,
        'startedAt': startedAt?.toIso8601String(),
        'durationSeconds': durationSeconds
      };
  factory CourtSession.fromJson(Map<String, dynamic> j) => CourtSession(
      id: j['id'],
      court: j['court'],
      teamA: List<String>.from(j['teamA']),
      teamB: List<String>.from(j['teamB']),
      startedAt: j['startedAt'] == null ? null : DateTime.parse(j['startedAt']),
      durationSeconds: j['durationSeconds']);
}

class CourtQueueData {
  CourtQueueData(
      {required this.date,
      this.courtCount = 2,
      this.manualOrder = false,
      List<QueuePlayer>? members,
      List<CourtSession>? courts})
      : members = members ?? [],
        courts = courts ?? [];
  String date;
  int courtCount;
  bool manualOrder;
  final List<QueuePlayer> members;
  final List<CourtSession> courts;
  bool onCourt(String id) => courts.any((c) => c.players.contains(id));
  List<QueuePlayer> waiting(DateTime now) {
    final result = members
        .where((p) =>
            !onCourt(p.player.id) &&
            (p.cooldownUntil == null || !p.cooldownUntil!.isAfter(now)))
        .toList();
    if (!manualOrder) {
      result.sort((a, b) {
        final n = a.played.compareTo(b.played);
        return n != 0 ? n : a.waitingSince.compareTo(b.waitingSince);
      });
    }
    return result;
  }

  List<QueuePlayer> resting(DateTime now) => members
      .where((p) =>
          !onCourt(p.player.id) &&
          p.cooldownUntil != null &&
          p.cooldownUntil!.isAfter(now))
      .toList();
  static (List<QueuePlayer>, List<QueuePlayer>) balanceDoubles(
      List<QueuePlayer> eligible) {
    if (eligible.length < 4) {
      throw StateError('Four waiting players are needed.');
    }
    final four = eligible.take(4).toList();
    var best = 1, bestDifference = 1000;
    for (var i = 1; i < 4; i++) {
      final a = four[0].player.ovr + four[i].player.ovr;
      final b = four.fold<int>(0, (n, p) => n + p.player.ovr) - a;
      if ((a - b).abs() < bestDifference) {
        bestDifference = (a - b).abs();
        best = i;
      }
    }
    return (
      [four[0], four[best]],
      [
        for (var i = 1; i < 4; i++)
          if (i != best) four[i]
      ]
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'courtCount': courtCount,
        'manualOrder': manualOrder,
        'members': members.map((p) => p.toJson()).toList(),
        'courts': courts.map((c) => c.toJson()).toList()
      };
  factory CourtQueueData.fromJson(Map<String, dynamic> j) => CourtQueueData(
      date: j['date'],
      courtCount: j['courtCount'],
      manualOrder: j['manualOrder'] == true,
      members: (j['members'] as List)
          .map((p) => QueuePlayer.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      courts: (j['courts'] as List)
          .map((c) => CourtSession.fromJson(Map<String, dynamic>.from(c)))
          .toList());
}
