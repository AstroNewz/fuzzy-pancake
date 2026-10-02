import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/supabase_service.dart';

/// Ladder Challenge model backed by `ladder_challenges`
class LadderChallenge {
  final String id;
  final String challengerId;
  final String defenderId;
  final String? challengerName;
  final String? defenderName;
  final int challengerRank;
  final int defenderRank;
  final String
      status; // 'pending', 'accepted', 'completed', 'declined', 'expired'
  final String? matchId;
  final String? winnerId;
  final DateTime createdAt;
  final DateTime? completedAt;

  const LadderChallenge({
    required this.id,
    required this.challengerId,
    required this.defenderId,
    this.challengerName,
    this.defenderName,
    required this.challengerRank,
    required this.defenderRank,
    required this.status,
    this.matchId,
    this.winnerId,
    required this.createdAt,
    this.completedAt,
  });

  factory LadderChallenge.fromMap(Map<String, dynamic> map) {
    return LadderChallenge(
      id: map['id'] as String,
      challengerId: map['challenger_id'] as String,
      defenderId: map['defender_id'] as String,
      challengerName: map['challenger_name'] as String?,
      defenderName: map['defender_name'] as String?,
      challengerRank: (map['challenger_rank'] as num).toInt(),
      defenderRank: (map['defender_rank'] as num).toInt(),
      status: (map['status'] as String?) ?? 'pending',
      matchId: map['match_id'] as String?,
      winnerId: map['winner_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'challenger_id': challengerId,
      'defender_id': defenderId,
      'challenger_name': challengerName,
      'defender_name': defenderName,
      'challenger_rank': challengerRank,
      'defender_rank': defenderRank,
      'status': status,
      'match_id': matchId,
      'winner_id': winnerId,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}

/// Ladder Challenge and Auto-Swap Engine
class LadderChallengeEngine {
  /// Strictly verifies if [challengerRank] is allowed to challenge [defenderRank]
  /// Club Rule: Challenger may challenge opponents up to max 2 positions above them
  static bool canChallenge({
    required int challengerRank,
    required int defenderRank,
    int maxSteps = AppConstants.maxLadderChallengeStep,
  }) {
    // Cannot challenge yourself or players ranked below you
    if (challengerRank <= defenderRank) return false;

    // Must be within max allowable step (default: 2 ranks above)
    return (challengerRank - defenderRank) <= maxSteps && defenderRank >= 1;
  }

  /// Calculates ladder displacement array when challenger beats higher-ranked defender
  /// If Challenger at rank C defeats Defender at rank D (C > D):
  /// - Defender and all players in between [D, C - 1] shift down by +1 rank
  /// - Challenger moves to position D
  static List<T> computeLadderSwap<T>({
    required List<T> currentLadder,
    required int challengerRank,
    required int defenderRank,
    required int Function(T item) getRank,
    required T Function(T item, int newRank) copyWithRank,
  }) {
    if (!canChallenge(
        challengerRank: challengerRank, defenderRank: defenderRank)) {
      return List.from(currentLadder);
    }

    final updatedList = <T>[];

    for (final item in currentLadder) {
      final r = getRank(item);

      if (r == challengerRank) {
        // Challenger takes defender's position
        updatedList.add(copyWithRank(item, defenderRank));
      } else if (r >= defenderRank && r < challengerRank) {
        // Defender and intermediate players shift down by 1
        updatedList.add(copyWithRank(item, r + 1));
      } else {
        // Outside range remains unchanged
        updatedList.add(item);
      }
    }

    // Sort by rank ascending
    updatedList.sort((a, b) => getRank(a).compareTo(getRank(b)));
    return updatedList;
  }
}

/// Ladder Challenge Repository with offline persistence & Supabase integration
class LadderChallengeRepository {
  final Ref ref;
  static const String _offlineChallengesKey = 'smashdeck_offline_challenges';

  LadderChallengeRepository(this.ref);

  /// Issues a new challenge
  Future<LadderChallenge?> issueChallenge({
    required String challengerId,
    required String challengerName,
    required int challengerRank,
    required String defenderId,
    required String defenderName,
    required int defenderRank,
  }) async {
    if (!LadderChallengeEngine.canChallenge(
      challengerRank: challengerRank,
      defenderRank: defenderRank,
    )) {
      throw ArgumentError(
          'Invalid challenge: must be 1 or 2 ranks directly above you.');
    }

    final challengeId = const Uuid().v4();
    final challenge = LadderChallenge(
      id: challengeId,
      challengerId: challengerId,
      challengerName: challengerName,
      challengerRank: challengerRank,
      defenderId: defenderId,
      defenderName: defenderName,
      defenderRank: defenderRank,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('ladder_challenges').upsert({
        'id': challengeId,
        'challenger_id': challengerId,
        'defender_id': defenderId,
        'challenger_rank': challengerRank,
        'defender_rank': defenderRank,
        'status': 'pending',
      }).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Challenge could not be sent: $e');
      rethrow;
    }

    await _saveChallengeLocally(challenge);
    return challenge;
  }

  /// Updates challenge status (e.g. accepted, declined, completed)
  Future<void> updateStatus(String challengeId, String status) async {
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase
          .from('ladder_challenges')
          .update({
            'status': status,
            'completed_at':
                status == 'completed' ? DateTime.now().toIso8601String() : null
          })
          .eq('id', challengeId)
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  /// Fetches active challenges for a player
  Future<List<LadderChallenge>> getActiveChallenges(String playerId) async {
    final localList = await _loadLocalChallenges();

    try {
      final supabase = ref.read(supabaseClientProvider);
      final response = await supabase
          .from('ladder_challenges')
          .select()
          .or('challenger_id.eq.$playerId,defender_id.eq.$playerId')
          .inFilter('status', ['pending', 'accepted'])
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 3));

      {
        return (response as List<dynamic>)
            .map(
                (item) => LadderChallenge.fromMap(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    return localList
        .where((c) =>
            (c.challengerId == playerId || c.defenderId == playerId) &&
            (c.status == 'pending' || c.status == 'accepted'))
        .toList();
  }

  Future<void> _saveChallengeLocally(LadderChallenge challenge) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _loadLocalChallenges();
    list.removeWhere((c) => c.id == challenge.id);
    list.insert(0, challenge);
    await prefs.setString(
      _offlineChallengesKey,
      jsonEncode(list.map((c) => c.toMap()).toList()),
    );
  }

  Future<List<LadderChallenge>> _loadLocalChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_offlineChallengesKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => LadderChallenge.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

final ladderChallengeRepositoryProvider = Provider<LadderChallengeRepository>(
    (ref) => LadderChallengeRepository(ref));

final activeChallengesProvider =
    FutureProvider.family<List<LadderChallenge>, String>((ref, playerId) async {
  final repo = ref.watch(ladderChallengeRepositoryProvider);
  return repo.getActiveChallenges(playerId);
});
