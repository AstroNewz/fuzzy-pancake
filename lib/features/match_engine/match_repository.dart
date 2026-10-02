import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/offline_sync_service.dart';
import '../../core/network/supabase_service.dart';
import '../../core/utils/bwf_scoring_rules.dart';

/// Result container for Match Save operation
class SaveMatchResult {
  final bool isSuccess;
  final bool isOffline;
  final String matchId;
  final String message;

  const SaveMatchResult({
    required this.isSuccess,
    this.isOffline = false,
    required this.matchId,
    required this.message,
  });
}

/// Match Engine Repository
class MatchRepository {
  final OfflineSyncService _offlineSync;

  MatchRepository(SupabaseClient client, this._offlineSync);

  /// Save completed match and all individual sets to Supabase
  /// Mitigates ISSUE-002 with offline caching & ISSUE-004 with is_rating_eligible
  Future<SaveMatchResult> saveCompletedMatch({
    String? existingMatchId,
    required String matchType, // 'singles' or 'doubles'
    required String category, // 'ladder', 'tournament', 'practice'
    required String teamA1Id,
    String? teamA2Id,
    required String teamB1Id,
    String? teamB2Id,
    required String winnerTeam, // 'A' or 'B'
    required List<Map<String, int>> sets, // [{'a': 21, 'b': 18}, ...]
    String? umpireId,
    bool isRatingEligible = true,
    int targetPoints = 21,
    int bestOfSets = 3,
  }) async {
    final participants = [
      teamA1Id,
      teamB1Id,
      if (teamA2Id != null) teamA2Id,
      if (teamB2Id != null) teamB2Id
    ];
    if (participants.toSet().length != participants.length ||
        participants.any((id) => id.isEmpty) ||
        (matchType == 'doubles' && participants.length != 4) ||
        (matchType == 'singles' && participants.length != 2)) {
      throw ArgumentError('Choose distinct players for every position.');
    }
    if (bestOfSets < 1 || bestOfSets > 5 || bestOfSets.isEven || sets.isEmpty) {
      throw ArgumentError('Invalid match format.');
    }
    final completed = <Map<String, int>>[];
    for (final set in sets) {
      if (BwfScoringRules.getMatchWinner(completed,
                  bestOfSets: bestOfSets, targetPoints: targetPoints) !=
              null ||
          !BwfScoringRules.isSetWon(set['a'] ?? -1, set['b'] ?? -1,
              targetPoints: targetPoints)) {
        throw ArgumentError(
            'Enter valid completed sets, stopping when the match is won.');
      }
      completed.add(set);
    }
    if (BwfScoringRules.getMatchWinner(sets,
            bestOfSets: bestOfSets, targetPoints: targetPoints) !=
        winnerTeam) {
      throw ArgumentError('The winner must match the completed set scores.');
    }
    final matchId = existingMatchId ?? const Uuid().v4();
    final now = DateTime.now();

    final matchData = {
      'id': matchId,
      'match_type': matchType,
      'category': category,
      'status': 'completed',
      'team_a_player1_id': teamA1Id,
      'team_a_player2_id': teamA2Id,
      'team_b_player1_id': teamB1Id,
      'team_b_player2_id': teamB2Id,
      'umpire_id': umpireId,
      'winner_team': winnerTeam,
      'is_rating_eligible':
          category != 'practice' && isRatingEligible && umpireId != null,
      'confirmed_by_team_a': false,
      'confirmed_by_team_b': false,
      'completed_at': now.toIso8601String(),
    };

    final setsData = <Map<String, dynamic>>[];
    for (int i = 0; i < sets.length; i++) {
      final scoreA = sets[i]['a'] ?? 0;
      final scoreB = sets[i]['b'] ?? 0;
      setsData.add({
        'id': const Uuid().v4(),
        'match_id': matchId,
        'set_number': i + 1,
        'team_a_score': scoreA,
        'team_b_score': scoreB,
        'winner_team': scoreA > scoreB ? 'A' : 'B',
      });
    }

    // Persist before sending so interruptions never discard a finished match.
    await _offlineSync.queueMatchResult(
        matchData: matchData, setsData: setsData);
    try {
      await _offlineSync.persistMatch(matchData, setsData);
      await _offlineSync.removeQueuedMatch(matchId);

      debugPrint('[MatchRepo] Successfully saved match $matchId to Supabase');
      return SaveMatchResult(
        isSuccess: true,
        matchId: matchId,
        message: 'Match and set scores saved to the club.',
      );
    } on PostgrestException {
      // Permission/validation errors need correction, not endless offline retry.
      await _offlineSync.removeQueuedMatch(matchId);
      rethrow;
    } catch (e) {
      if (e is! TimeoutException && e is! http.ClientException) rethrow;
      debugPrint('[MatchRepo] Online save failed, buffering offline: $e');

      // Offline-First Fallback (ISSUE-002)

      return SaveMatchResult(
        isSuccess: true,
        isOffline: true,
        matchId: matchId,
        message:
            'Match saved on this device. It will retry syncing while the app is open.',
      );
    }
  }
}

/// Match Repository Provider
final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final offlineSync = ref.watch(offlineSyncServiceProvider);
  return MatchRepository(client, offlineSync);
});
