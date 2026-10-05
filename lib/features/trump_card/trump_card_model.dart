import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/supabase_service.dart';
import '../../core/theme/app_avatars.dart';
import '../../core/theme/card_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Dynamic Trump Card Model
class TrumpCardModel {
  final String playerId;
  final String rollNumber;
  final String fullName;
  final String? avatarUrl;
  final String playstyle;
  final String dominantHand;
  final String role;
  final int eloRating;
  final int? ladderRank;
  final int smash;
  final int agility;
  final int stamina;
  final int consistency;
  final int ovrRating;
  final CardTier cardTier;
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final double winRatePct;

  const TrumpCardModel({
    required this.playerId,
    required this.rollNumber,
    required this.fullName,
    this.avatarUrl,
    required this.playstyle,
    required this.dominantHand,
    required this.role,
    required this.eloRating,
    this.ladderRank,
    required this.smash,
    required this.agility,
    required this.stamina,
    required this.consistency,
    required this.ovrRating,
    required this.cardTier,
    required this.matchesPlayed,
    required this.matchesWon,
    required this.matchesLost,
    required this.winRatePct,
  });

  factory TrumpCardModel.fromMap(Map<String, dynamic> map, {int? rank}) {
    final smash = (map['base_smash'] ?? map['smash'] as num?)?.toInt() ?? 80;
    final agility =
        (map['base_agility'] ?? map['agility'] as num?)?.toInt() ?? 80;
    final stamina =
        (map['base_stamina'] ?? map['stamina'] as num?)?.toInt() ?? 80;
    final consistency =
        (map['base_consistency'] ?? map['consistency'] as num?)?.toInt() ?? 80;
    final elo = (map['elo_rating'] as num?)?.toInt() ?? 1300;
    final ovr = (map['ovr_rating'] as num?)?.toInt() ??
        ((smash * 0.35 + agility * 0.25 + stamina * 0.20 + consistency * 0.20)
            .round());

    final roll = (map['roll_number'] as String?) ?? 'SD-0001';
    final avatar =
        (map['avatar_url'] as String?) ?? AppAvatars.getAvatarForRoll(roll);

    final name = (map['full_name'] as String?) ?? 'Squad Member';

    final effectiveRank = rank ?? (map['ladder_rank'] as num?)?.toInt();
    CardTier tier;
    if (effectiveRank == 1) {
      // Marvin Joseph / Top player unconditionally gets the Golden Card!
      tier = CardTier.gold;
    } else if (map['card_tier'] != null) {
      tier = CardTier.fromString(map['card_tier'] as String?);
    } else if (effectiveRank == 2 || effectiveRank == 3 || ovr >= 88) {
      tier = CardTier.diamond;
    } else if (effectiveRank != null && effectiveRank <= 6) {
      tier = CardTier.silver;
    } else {
      tier = CardTier.bronze;
    }

    return TrumpCardModel(
      playerId: (map['id'] ?? map['player_id'] ?? roll) as String,
      rollNumber: roll,
      fullName: name,
      avatarUrl: avatar,
      playstyle: (map['playstyle'] as String?) ?? 'All-Rounder',
      dominantHand: (map['dominant_hand'] as String?) ?? 'Right',
      role: (map['role'] as String?) ?? 'player',
      eloRating: elo,
      ladderRank: effectiveRank,
      smash: smash,
      agility: agility,
      stamina: stamina,
      consistency: consistency,
      ovrRating: ovr,
      cardTier: tier,
      matchesPlayed: (map['matches_played'] as num?)?.toInt() ?? 0,
      matchesWon: (map['matches_won'] as num?)?.toInt() ?? 0,
      matchesLost: (map['matches_lost'] as num?)?.toInt() ?? 0,
      winRatePct: (map['win_rate_pct'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Fallback 7 Squad Cards List — Top Player Marvin Joseph holds Rank #1 Golden Card
final List<TrumpCardModel> fallbackSquadCards = [
  // ── Rank 1: Marvin Joseph (GOLDEN CARD) ───────────────────────────────────
  TrumpCardModel(
    playerId: 'SD-0003',
    rollNumber: 'SD-0003',
    fullName: 'Marvin Joseph',
    avatarUrl: AppAvatars.getAvatarForRoll('SD-0003'),
    playstyle: 'Speed Attacker',
    dominantHand: 'Right',
    role: 'player',
    eloRating: 1485,
    ladderRank: 1,
    smash: 92,
    agility: 96,
    stamina: 91,
    consistency: 89,
    ovrRating: 95,
    cardTier: CardTier.gold,
    matchesPlayed: 22,
    matchesWon: 20,
    matchesLost: 2,
    winRatePct: 90.9,
  ),

  // ── Rank 2: Sachin Jyani ──────────────────────────────────────────────────
  TrumpCardModel(
    playerId: 'SD-0001',
    rollNumber: 'SD-0001',
    fullName: 'Sachin Jyani',
    avatarUrl: AppAvatars.getAvatarForRoll('SD-0001'),
    playstyle: 'Aggressive Smasher',
    dominantHand: 'Right',
    role: 'captain',
    eloRating: 1420,
    ladderRank: 2,
    smash: 88,
    agility: 84,
    stamina: 85,
    consistency: 82,
    ovrRating: 91,
    cardTier: CardTier.diamond,
    matchesPlayed: 18,
    matchesWon: 15,
    matchesLost: 3,
    winRatePct: 83.3,
  ),

  // ── Rank 3: Ishan Narayan Shukla (MASTER ADMIN) ───────────────────────────
  TrumpCardModel(
    playerId: 'SD-0002',
    rollNumber: 'SD-0002',
    fullName: 'Ishan Narayan Shukla',
    avatarUrl: AppAvatars.getAvatarForRoll('SD-0002'),
    playstyle: 'All-Rounder',
    dominantHand: 'Right',
    role: 'admin',
    eloRating: 1390,
    ladderRank: 3,
    smash: 84,
    agility: 88,
    stamina: 80,
    consistency: 84,
    ovrRating: 89,
    cardTier: CardTier.diamond,
    matchesPlayed: 16,
    matchesWon: 13,
    matchesLost: 3,
    winRatePct: 81.3,
  ),

  // ── Rank 4: Devang Gupta ──────────────────────────────────────────────────
  TrumpCardModel(
    playerId: 'SD-0007',
    rollNumber: 'SD-0007',
    fullName: 'Devang Gupta',
    avatarUrl: AppAvatars.getAvatarForRoll('SD-0007'),
    playstyle: 'Speed Attacker',
    dominantHand: 'Right',
    role: 'player',
    eloRating: 1360,
    ladderRank: 4,
    smash: 85,
    agility: 82,
    stamina: 84,
    consistency: 80,
    ovrRating: 86,
    cardTier: CardTier.silver,
    matchesPlayed: 13,
    matchesWon: 9,
    matchesLost: 4,
    winRatePct: 69.2,
  ),

  // ── Rank 5: Divyansh Parag ────────────────────────────────────────────────
  TrumpCardModel(
    playerId: 'SD-0004',
    rollNumber: 'SD-0004',
    fullName: 'Divyansh Parag',
    avatarUrl: AppAvatars.getAvatarForRoll('SD-0004'),
    playstyle: 'Net Dominator',
    dominantHand: 'Right',
    role: 'player',
    eloRating: 1330,
    ladderRank: 5,
    smash: 76,
    agility: 88,
    stamina: 82,
    consistency: 84,
    ovrRating: 84,
    cardTier: CardTier.silver,
    matchesPlayed: 12,
    matchesWon: 8,
    matchesLost: 4,
    winRatePct: 66.7,
  ),

  // ── Rank 6: Varenyam Tiwari ───────────────────────────────────────────────
  TrumpCardModel(
    playerId: 'SD-0005',
    rollNumber: 'SD-0005',
    fullName: 'Varenyam Tiwari',
    avatarUrl: AppAvatars.getAvatarForRoll('SD-0005'),
    playstyle: 'Defensive Retriever',
    dominantHand: 'Right',
    role: 'player',
    eloRating: 1305,
    ladderRank: 6,
    smash: 78,
    agility: 80,
    stamina: 86,
    consistency: 80,
    ovrRating: 82,
    cardTier: CardTier.silver,
    matchesPlayed: 11,
    matchesWon: 7,
    matchesLost: 4,
    winRatePct: 63.6,
  ),

  // ── Rank 7: Anshul Yadav ──────────────────────────────────────────────────
  TrumpCardModel(
    playerId: 'SD-0006',
    rollNumber: 'SD-0006',
    fullName: 'Anshul Yadav',
    avatarUrl: AppAvatars.getAvatarForRoll('SD-0006'),
    playstyle: 'Tactical Trickster',
    dominantHand: 'Right',
    role: 'player',
    eloRating: 1280,
    ladderRank: 7,
    smash: 82,
    agility: 76,
    stamina: 84,
    consistency: 78,
    ovrRating: 80,
    cardTier: CardTier.bronze,
    matchesPlayed: 10,
    matchesWon: 6,
    matchesLost: 4,
    winRatePct: 60.0,
  ),

  // ── Rank 8: Kartikey Shankar ──────────────────────────────────────────────
  TrumpCardModel(
    playerId: 'SD-0008',
    rollNumber: 'SD-0008',
    fullName: 'Kartikey Shankar',
    avatarUrl: AppAvatars.getAvatarForRoll('SD-0008'),
    playstyle: 'Aggressive Smasher',
    dominantHand: 'Right',
    role: 'player',
    eloRating: 1260,
    ladderRank: 8,
    smash: 85,
    agility: 80,
    stamina: 81,
    consistency: 78,
    ovrRating: 81,
    cardTier: CardTier.bronze,
    matchesPlayed: 8,
    matchesWon: 5,
    matchesLost: 3,
    winRatePct: 62.5,
  ),

  // ── Rank 9: Shurit Mondal ─────────────────────────────────────────────────
  TrumpCardModel(
    playerId: 'SD-0009',
    rollNumber: 'SD-0009',
    fullName: 'Shurit Mondal',
    avatarUrl: AppAvatars.getAvatarForRoll('SD-0009'),
    playstyle: 'Tactical Trickster',
    dominantHand: 'Right',
    role: 'player',
    eloRating: 1245,
    ladderRank: 9,
    smash: 79,
    agility: 82,
    stamina: 82,
    consistency: 83,
    ovrRating: 81,
    cardTier: CardTier.bronze,
    matchesPlayed: 8,
    matchesWon: 5,
    matchesLost: 3,
    winRatePct: 62.5,
  ),

  // ── Rank 10: Sai ──────────────────────────────────────────────────────────
  TrumpCardModel(
    playerId: 'SD-0010',
    rollNumber: 'SD-0010',
    fullName: 'Sai',
    avatarUrl: AppAvatars.getAvatarForRoll('SD-0010'),
    playstyle: 'Speed Attacker',
    dominantHand: 'Right',
    role: 'player',
    eloRating: 1230,
    ladderRank: 10,
    smash: 81,
    agility: 86,
    stamina: 78,
    consistency: 77,
    ovrRating: 80,
    cardTier: CardTier.bronze,
    matchesPlayed: 7,
    matchesWon: 4,
    matchesLost: 3,
    winRatePct: 57.1,
  ),

  // ── Rank 11: Krishna ──────────────────────────────────────────────────────
  TrumpCardModel(
    playerId: 'SD-0011',
    rollNumber: 'SD-0011',
    fullName: 'Krishna',
    avatarUrl: AppAvatars.getAvatarForRoll('SD-0011'),
    playstyle: 'All-Rounder',
    dominantHand: 'Right',
    role: 'player',
    eloRating: 1215,
    ladderRank: 11,
    smash: 80,
    agility: 80,
    stamina: 84,
    consistency: 81,
    ovrRating: 80,
    cardTier: CardTier.bronze,
    matchesPlayed: 7,
    matchesWon: 4,
    matchesLost: 3,
    winRatePct: 57.1,
  ),

  // ── Rank 12: Shweta Yadav ─────────────────────────────────────────────────
  TrumpCardModel(
    playerId: 'SD-0012',
    rollNumber: 'SD-0012',
    fullName: 'Shweta Yadav',
    avatarUrl: AppAvatars.getAvatarForRoll('SD-0012'),
    playstyle: 'Net Dominator',
    dominantHand: 'Right',
    role: 'player',
    eloRating: 1205,
    ladderRank: 12,
    smash: 76,
    agility: 85,
    stamina: 80,
    consistency: 82,
    ovrRating: 80,
    cardTier: CardTier.bronze,
    matchesPlayed: 6,
    matchesWon: 3,
    matchesLost: 3,
    winRatePct: 50.0,
  ),

  // ── Rank 13: Manisha ──────────────────────────────────────────────────────
  TrumpCardModel(
    playerId: 'SD-0013',
    rollNumber: 'SD-0013',
    fullName: 'Manisha',
    avatarUrl: AppAvatars.getAvatarForRoll('SD-0013'),
    playstyle: 'Defensive Retriever',
    dominantHand: 'Right',
    role: 'player',
    eloRating: 1195,
    ladderRank: 13,
    smash: 74,
    agility: 79,
    stamina: 85,
    consistency: 85,
    ovrRating: 79,
    cardTier: CardTier.bronze,
    matchesPlayed: 6,
    matchesWon: 3,
    matchesLost: 3,
    winRatePct: 50.0,
  ),
];

/// Dynamic Squad Trump Cards Provider with direct players table fetching and resilient fallback
final squadTrumpCardsProvider =
    FutureProvider<List<TrumpCardModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  try {
    final rows = await client
        .from('v_player_dynamic_ovr')
        .select()
        .order('elo_rating', ascending: false)
        .timeout(const Duration(seconds: 10));
    return rows.map((row) => TrumpCardModel.fromMap(row)).toList();
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
  return rows
      .asMap()
      .entries
      .map((e) => TrumpCardModel.fromMap(e.value, rank: e.key + 1))
      .toList();
});
