import '../../features/auth/auth_state.dart';
import '../../features/gear_tracker/gear_model.dart';
import '../../features/ladder/ladder_state.dart';

/// MockSquadData — all arrays cleared.
/// Data is now sourced exclusively from Supabase PostgreSQL.
/// This class is kept as a stub so existing imports compile.
class MockSquadData {
  /// All players now come from the `players` Supabase table.
  static final List<PlayerProfile> players = [];

  /// All ladder positions come from `v_ladder_standings` view.
  static List<LadderEntry> get ladderStandings => [];
  static List<LadderEntry> get ladderEntries => [];

  /// All gear logs come from the `gear_logs` Supabase table.
  static final List<GearLog> gearLogsList = [];
  static List<GearLog> get gearLogs => gearLogsList;
}
