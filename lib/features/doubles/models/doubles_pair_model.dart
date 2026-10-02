import '../../trump_card/trump_card_model.dart';

class DoublesPair {
  const DoublesPair(
      {required this.first,
      required this.second,
      this.matches = 0,
      this.wins = 0,
      this.consecutiveWins = 0});
  final TrumpCardModel first, second;
  final int matches, wins, consecutiveWins;
  static String role(TrumpCardModel player) {
    final style = player.playstyle.toLowerCase();
    if (style.contains('defen') || style.contains('counter')) return 'defence';
    if (style.contains('net') ||
        style.contains('playmaker') ||
        style.contains('decept') ||
        player.agility > player.smash + 3) {
      return 'front';
    }
    if (style.contains('smash') ||
        style.contains('back') ||
        player.smash >= player.agility) {
      return 'back';
    }
    return 'all-round';
  }

  int get chemistry {
    final a = role(first), b = role(second);
    final base = (a == 'front' && b == 'back' || a == 'back' && b == 'front')
        ? 95
        : a == 'defence' && b == 'defence'
            ? 80
            : a == b
                ? 75
                : 86;
    return (base + consecutiveWins ~/ 3).clamp(0, 100);
  }

  int get ovr => ((first.ovrRating + second.ovrRating) / 2).round();
  String get teamName =>
      '${first.fullName.split(' ').first} × ${second.fullName.split(' ').first}';
  String get badge => role(first) == 'defence' && role(second) == 'defence'
      ? 'Wall of Granite'
      : chemistry >= 95
          ? 'Thunder Duo'
          : 'Court Alchemists';
  List<double> get attributes => [
        (first.smash + second.smash) / 2,
        (first.agility + second.agility) / 2,
        (first.stamina + second.stamina) / 2,
        (first.consistency + second.consistency) / 2
      ];
  factory DoublesPair.fromHistory(
      TrumpCardModel a, TrumpCardModel b, List<Map<String, dynamic>> matches) {
    final outcomes = <bool>[];
    final sorted = List<Map<String, dynamic>>.from(matches)
      ..sort((x, y) => (y['created_at'] as String? ?? '')
          .compareTo(x['created_at'] as String? ?? ''));
    for (final m in sorted) {
      if (m['status'] != 'completed' ||
          !['A', 'B'].contains(m['winner_team'])) {
        continue;
      }
      bool same(String side) {
        final ids = {
          m['team_${side}_player1_id'],
          m['team_${side}_player2_id']
        };
        return ids.length == 2 &&
            ids.contains(a.playerId) &&
            ids.contains(b.playerId);
      }

      if (same('a')) outcomes.add(m['winner_team'] == 'A');
      if (same('b')) outcomes.add(m['winner_team'] == 'B');
    }
    return DoublesPair(
        first: a,
        second: b,
        matches: outcomes.length,
        wins: outcomes.where((w) => w).length,
        consecutiveWins: outcomes.takeWhile((w) => w).length);
  }
}
