/// Core Application Constants for SmashDeck
class AppConstants {
  // Application Meta
  static const String appName = 'SmashDeck';
  static const String appTagline = 'College Badminton Club & Trump Card Engine';
  static const String appVersion = '1.0.0';

  // Supabase Configuration
  // Note: Populate with your project credentials from the Supabase Dashboard
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jgfvkllksyriyyibjulg.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpnZnZrbGxrc3lyaXl5aWJqdWxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg1OTM2NDcsImV4cCI6MjEwNDE2OTY0N30.Yz6EJ31KrSwPcbILkK5OqKACSjMYMbYT7mAsqXW9FL8',
  );

  // Table Names
  static const String tablePlayers = 'players';
  static const String tableMatches = 'matches';
  static const String tableMatchSets = 'match_sets';
  static const String tableAttendanceLogs = 'attendance_logs';
  static const String tableLadderPositions = 'ladder_positions';
  static const String tableLadderChallenges = 'ladder_challenges';
  static const String tableGearLogs = 'gear_logs';

  // Dynamic Views
  static const String viewPlayerDynamicOvr = 'v_player_dynamic_ovr';
  static const String viewPlayerMatchStats = 'v_player_match_stats';
  static const String viewLadderStandings = 'v_ladder_standings';
  static const String viewHeadToHeadMatrix = 'v_head_to_head_matrix';
  static const String viewAttendanceSummary = 'v_attendance_summary';

  // BWF Standard Scoring Constants
  static const int bwfStandardPoints = 21;
  static const int bwfDeuceCeiling = 30;
  static const int bwfIntervalPoints = 11;

  // Ladder Rules
  static const int maxLadderChallengeStep =
      2; // Can challenge up to 2 ranks above
}
