import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_avatars.dart';
import '../../core/network/supabase_service.dart';
import '../../core/theme/card_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ladder Standing Entry backed by `v_ladder_standings`
class LadderEntry {
  final int rank;
  final String playerId;
  final String rollNumber;
  final String fullName;
  final String? avatarUrl;
  final String playstyle;
  final int ovrRating;
  final CardTier cardTier;
  final int eloRating;
  final int? previousRank;
  final int rankChange;
  final double winRatePct;
  final int matchesPlayed;

  const LadderEntry({
    required this.rank,
    required this.playerId,
    required this.rollNumber,
    required this.fullName,
    this.avatarUrl,
    required this.playstyle,
    required this.ovrRating,
    required this.cardTier,
    required this.eloRating,
    this.previousRank,
    required this.rankChange,
    required this.winRatePct,
    required this.matchesPlayed,
  });

  factory LadderEntry.fromMap(Map<String, dynamic> map) {
    return LadderEntry(
      rank: (map['rank'] as num).toInt(),
      playerId: map['player_id'] as String,
      rollNumber: map['roll_number'] as String,
      fullName: map['full_name'] as String,
      avatarUrl: map['avatar_url'] as String?,
      playstyle: (map['playstyle'] as String?) ?? 'All-Rounder',
      ovrRating: (map['ovr_rating'] as num?)?.toInt() ?? 70,
      cardTier: CardTier.fromString(map['card_tier'] as String?),
      eloRating: (map['elo_rating'] as num?)?.toInt() ?? 1200,
      previousRank: (map['previous_rank'] as num?)?.toInt(),
      rankChange: (map['rank_change'] as num?)?.toInt() ?? 0,
      winRatePct: (map['win_rate_pct'] as num?)?.toDouble() ?? 0.0,
      matchesPlayed: (map['matches_played'] as num?)?.toInt() ?? 0,
    );
  }

  /// Whether current user at [myRank] can issue a challenge to this entry
  bool canBeChallengedBy(int myRank) {
    return rank < myRank &&
        (myRank - rank) <= AppConstants.maxLadderChallengeStep;
  }

  /// Convenience aliases for Stitch UI
  String get playerName => fullName;
  int? get wins =>
      matchesPlayed > 0 ? ((winRatePct / 100) * matchesPlayed).round() : null;
  int? get losses => matchesPlayed > 0 ? matchesPlayed - (wins ?? 0) : null;
}

/// Load real standings. Errors remain visible instead of inventing results.
final ladderStandingsProvider = FutureProvider<List<LadderEntry>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final rows = await client
        .from('v_ladder_standings')
        .select()
        .order('rank')
        .timeout(const Duration(seconds: 10));
    if (rows.isNotEmpty) return rows.map(LadderEntry.fromMap).toList();
  } on PostgrestException catch (e) {
    if (e.code != '42P01' && e.code != 'PGRST205') rethrow;
  }
  final rows = await client
      .from('players')
      .select()
      .eq('is_active', true)
      .order('elo_rating', ascending: false)
      .order('id')
      .timeout(const Duration(seconds: 10));
  return rows.asMap().entries.map((entry) {
    final map = entry.value;
    final roll = map['roll_number'] as String? ?? '';
    final rank = entry.key + 1;
    final smash = (map['base_smash'] as num?)?.toInt() ?? 70;
    final agility = (map['base_agility'] as num?)?.toInt() ?? 70;
    final stamina = (map['base_stamina'] as num?)?.toInt() ?? 70;
    final consistency = (map['base_consistency'] as num?)?.toInt() ?? 70;
    return LadderEntry(
        rank: rank,
        playerId: map['id'] as String,
        rollNumber: roll,
        fullName: map['full_name'] as String? ?? 'Club member',
        avatarUrl:
            map['avatar_url'] as String? ?? AppAvatars.getAvatarForRoll(roll),
        playstyle: map['playstyle'] as String? ?? 'All-Rounder',
        ovrRating:
            (smash * .35 + agility * .25 + stamina * .2 + consistency * .2)
                .round(),
        cardTier: CardTier.fromString(map['card_tier'] as String?),
        eloRating: (map['elo_rating'] as num?)?.toInt() ?? 1200,
        rankChange: 0,
        winRatePct: 0,
        matchesPlayed: 0);
  }).toList();
});
