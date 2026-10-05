import '../../features/auth/auth_state.dart';
import '../../features/gear_tracker/gear_model.dart';
import '../../features/ladder/ladder_state.dart';
import '../../features/trump_card/trump_card_model.dart';

/// MockSquadData — resilient squad data fallback for offline or unseeded states.
class MockSquadData {
  /// All 13 players converted from fallback squad cards
  static List<PlayerProfile> get players => fallbackSquadCards.map((c) {
        return PlayerProfile(
          id: c.playerId,
          rollNumber: c.rollNumber,
          fullName: c.fullName,
          email: '${c.rollNumber.toLowerCase()}@smashclub.in',
          role: c.role == 'captain'
              ? UserRole.captain
              : (c.role == 'admin' ? UserRole.admin : UserRole.player),
          avatarUrl: c.avatarUrl,
          playstyle: c.playstyle,
          dominantHand: c.dominantHand,
          baseSmash: c.smash,
          baseAgility: c.agility,
          baseStamina: c.stamina,
          baseConsistency: c.consistency,
          eloRating: c.eloRating,
          isActive: true,
        );
      }).toList();

  /// Ladder entries
  static List<LadderEntry> get ladderStandings => fallbackSquadCards
      .map((c) => LadderEntry(
            rank: c.ladderRank ?? 1,
            playerId: c.playerId,
            rollNumber: c.rollNumber,
            fullName: c.fullName,
            avatarUrl: c.avatarUrl,
            playstyle: c.playstyle,
            ovrRating: c.ovrRating,
            cardTier: c.cardTier,
            eloRating: c.eloRating,
            previousRank: c.ladderRank,
            rankChange: 0,
            winRatePct: c.winRatePct,
            matchesPlayed: c.matchesPlayed,
          ))
      .toList();

  static List<LadderEntry> get ladderEntries => ladderStandings;

  /// Gear logs
  static final List<GearLog> gearLogsList = [];
  static List<GearLog> get gearLogs => gearLogsList;
}
