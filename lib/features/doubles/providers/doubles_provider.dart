import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_service.dart';

final doublesHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final result = <Map<String, dynamic>>[];
  for (var offset = 0;; offset += 500) {
    final page = await client
        .from('matches')
        .select(
            'id,status,created_at,winner_team,team_a_player1_id,team_a_player2_id,team_b_player1_id,team_b_player2_id')
        .eq('match_type', 'doubles')
        .eq('status', 'completed')
        .order('created_at', ascending: false)
        .range(offset, offset + 499)
        .timeout(const Duration(seconds: 10));
    result.addAll(page);
    if (page.length < 500) break;
  }
  return result;
});
