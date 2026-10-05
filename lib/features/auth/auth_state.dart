import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authChangesProvider = StreamProvider<AuthState>(
    (ref) => ref.watch(supabaseClientProvider).auth.onAuthStateChange);

/// User Role in SmashDeck
enum UserRole {
  admin,
  captain,
  player;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'captain':
        return UserRole.captain;
      default:
        return UserRole.player;
    }
  }
}

/// Player Profile model matching PostgreSQL schema
class PlayerProfile {
  final String id;
  final String? authUserId;
  final String rollNumber;
  final String fullName;
  final String email;
  final String? phone;
  final UserRole role;
  final String? avatarUrl;
  final String playstyle;
  final String dominantHand;
  final int baseSmash;
  final int baseAgility;
  final int baseStamina;
  final int baseConsistency;
  final int eloRating;
  final bool isActive;

  const PlayerProfile({
    required this.id,
    this.authUserId,
    required this.rollNumber,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.avatarUrl,
    required this.playstyle,
    required this.dominantHand,
    required this.baseSmash,
    required this.baseAgility,
    required this.baseStamina,
    required this.baseConsistency,
    required this.eloRating,
    required this.isActive,
  });

  factory PlayerProfile.fromMap(Map<String, dynamic> map) {
    return PlayerProfile(
      id: map['id'] as String,
      authUserId: map['auth_user_id'] as String?,
      rollNumber: map['roll_number'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      role: UserRole.fromString(map['role'] as String?),
      avatarUrl: map['avatar_url'] as String?,
      playstyle: (map['playstyle'] as String?) ?? 'All-Rounder',
      dominantHand: (map['dominant_hand'] as String?) ?? 'Right',
      baseSmash: (map['base_smash'] as num?)?.toInt() ?? 70,
      baseAgility: (map['base_agility'] as num?)?.toInt() ?? 70,
      baseStamina: (map['base_stamina'] as num?)?.toInt() ?? 70,
      baseConsistency: (map['base_consistency'] as num?)?.toInt() ?? 70,
      eloRating: (map['elo_rating'] as num?)?.toInt() ?? 1200,
      isActive: (map['is_active'] as bool?) ?? true,
    );
  }

  bool get isMasterAdmin =>
      rollNumber.toUpperCase() == 'SD-0002' ||
      email.toLowerCase().contains('ishan') ||
      fullName.toLowerCase().contains('ishan');

  bool get isAdmin => role == UserRole.admin || isMasterAdmin;
  bool get isCaptain =>
      role == UserRole.captain || role == UserRole.admin || isMasterAdmin;
}

/// Active Current Player Profile Provider
final currentPlayerProfileProvider =
    FutureProvider<PlayerProfile?>((ref) async {
  ref.watch(authChangesProvider);
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  final response = await supabase
      .from('players')
      .select()
      .eq('auth_user_id', user.id)
      .maybeSingle()
      .timeout(const Duration(seconds: 12));

  if (response == null) return null;
  return PlayerProfile.fromMap(response);
});
