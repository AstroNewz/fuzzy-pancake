import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/supabase_service.dart';
import '../gear_tracker/gear_model.dart';
import '../trump_card/trump_card_model.dart';
import 'auth_state.dart';

/// State notifier for the currently logged-in player profile.
/// Starts as null — set after successful login, quick select, or registration.
class CurrentUserNotifier extends StateNotifier<PlayerProfile?> {
  CurrentUserNotifier({bool restoreSession = true}) : super(null) {
    if (restoreSession) _restoreSavedUser();
  }

  int _sessionRevision = 0;

  Future<void> _restoreSavedUser() async {
    final revision = _sessionRevision;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('active_player_id');
      if (savedId == null) return;

      final client = Supabase.instance.client;
      Map<String, dynamic>? row;
      try {
        row = await client
            .from('players')
            .select()
            .or('id.eq.$savedId,roll_number.eq.$savedId')
            .maybeSingle()
            .timeout(const Duration(seconds: 8));
      } catch (_) {}

      if (row == null) {
        final card = fallbackSquadCards
            .where((c) => c.playerId == savedId || c.rollNumber == savedId);
        if (card.isNotEmpty) {
          final c = card.first;
          row = {
            'id': c.playerId,
            'roll_number': c.rollNumber,
            'full_name': c.fullName,
            'email': '${c.rollNumber.toLowerCase()}@smashclub.in',
            'role': c.role,
            'playstyle': c.playstyle,
            'dominant_hand': c.dominantHand,
            'avatar_url': c.avatarUrl,
            'base_smash': c.smash,
            'base_agility': c.agility,
            'base_stamina': c.stamina,
            'base_consistency': c.consistency,
            'elo_rating': c.eloRating,
            'is_active': true,
          };
        }
      }

      if (mounted && revision == _sessionRevision && row != null) {
        final profile = PlayerProfile.fromMap(row);
        if (profile.isActive) state = profile;
      }
    } catch (_) {}
  }

  /// Set the active user (called by AuthGate after profile fetch)
  void setPlayer(PlayerProfile player) {
    _sessionRevision++;
    state = player;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('active_player_id', player.id);
    });
  }

  /// Local profile selection never grants a new authenticated identity.
  Future<void> quickSignInAs(PlayerProfile player) async {
    if (player.authUserId == null ||
        Supabase.instance.client.auth.currentUser?.id != player.authUserId) {
      throw StateError('Sign in to this account first.');
    }
    setPlayer(player);
  }

  void clearPlayer() {
    _sessionRevision++;
    if (mounted) state = null;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.remove('active_player_id'));
  }

  /// Signs in an existing member with Player ID / email + password.
  /// Validates squad identity and verifies club passcode 'smash2024'.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    final revision = ++_sessionRevision;
    try {
      final input = email.trim();
      final pass = password.trim();

      if (input.isEmpty) return 'Enter your email or player ID.';
      if (pass.isEmpty) return 'Enter your password.';

      final client = Supabase.instance.client;

      // 1. Look up player in Supabase `players` table
      Map<String, dynamic>? playerRow;
      try {
        final orFilter =
            'roll_number.eq.${input.toUpperCase()},email.eq.${input.toLowerCase()},roll_number.ilike.%$input%,full_name.ilike.%$input%';
        playerRow = await client
            .from('players')
            .select()
            .or(orFilter)
            .limit(1)
            .maybeSingle()
            .timeout(const Duration(seconds: 8));
      } catch (_) {}

      // 2. Offline / seed fallback lookup
      if (playerRow == null) {
        final card = fallbackSquadCards.where(
          (c) =>
              c.rollNumber.toUpperCase() == input.toUpperCase() ||
              c.fullName.toLowerCase() == input.toLowerCase() ||
              c.fullName.toLowerCase().contains(input.toLowerCase()),
        );
        if (card.isNotEmpty) {
          final c = card.first;
          playerRow = {
            'id': c.playerId,
            'roll_number': c.rollNumber,
            'full_name': c.fullName,
            'email': '${c.rollNumber.toLowerCase()}@smashclub.in',
            'role': c.role,
            'playstyle': c.playstyle,
            'dominant_hand': c.dominantHand,
            'avatar_url': c.avatarUrl,
            'base_smash': c.smash,
            'base_agility': c.agility,
            'base_stamina': c.stamina,
            'base_consistency': c.consistency,
            'elo_rating': c.eloRating,
            'is_active': true,
          };
        }
      }

      if (playerRow == null) {
        return 'No squad member found matching "$input". Enter your Player ID (e.g. SD-0002) or email.';
      }

      // 3. Password Verification & Supabase Auth Session
      final playerEmail = playerRow['email'] as String?;
      bool authSuccessful = false;

      // Attempt authenticating with the entered password directly in Supabase Auth
      if (playerEmail != null && playerEmail.isNotEmpty) {
        try {
          final authRes = await client.auth.signInWithPassword(
            email: playerEmail,
            password: pass,
          );
          if (authRes.user != null) {
            authSuccessful = true;
          }
        } catch (_) {}
      }

      // Check master club passcodes: smash2024, smash123, smashdeck@123
      final isMasterPass = (pass == 'smash2024' ||
          pass == 'smash123' ||
          pass == 'smashdeck@123');

      if (!authSuccessful && isMasterPass) {
        // Attempt signing in to Supabase with the known seed password 'smash2024'
        if (playerEmail != null && playerEmail.isNotEmpty) {
          try {
            final authRes = await client.auth.signInWithPassword(
              email: playerEmail,
              password: 'smash2024',
            );
            if (authRes.user != null) {
              authSuccessful = true;
            }
          } catch (_) {}
        }
        // Master passcode accepted for club squad
        authSuccessful = true;
      }

      if (!authSuccessful) {
        return 'Incorrect password. Enter the squad passcode: smash2024';
      }

      final profile = PlayerProfile.fromMap(playerRow);
      if (!profile.isActive) {
        return 'This club membership is inactive. Contact your captain.';
      }

      if (!mounted || revision != _sessionRevision) {
        return 'Sign in was cancelled.';
      }

      setPlayer(profile);
      return null;
    } catch (e) {
      return 'Couldn’t connect. Check your internet connection and try again.';
    }
  }

  /// Registers a brand new club member:
  /// 1. Creates Supabase Auth user (email + password)
  /// 2. Inserts player row into `players` table with auth_user_id linked
  /// 3. Inserts initial gear log if racket info provided
  /// 4. Sets state to the new PlayerProfile
  Future<String?> registerPlayer({
    required String fullName,
    required String rollNumber,
    required String email,
    required String password,
    required String playstyle,
    required String dominantHand,
    required UserRole role,
    String? avatarUrl,
    String? racketBrandModel,
    String? stringModel,
    double? tensionLbs,
  }) async {
    try {
      final client = Supabase.instance.client;

      // Step 1: Create Supabase Auth user
      final existing = client.auth.currentUser;
      final authResponse = existing == null
          ? await client.auth.signUp(
              email: email.trim(),
              password: password,
            )
          : null;
      final authUser = existing ?? authResponse?.user;
      if (authUser == null) {
        return 'Sign up failed. Please try again.';
      }

      if (client.auth.currentSession == null) {
        return 'Check your email to confirm your account, then sign in and finish your profile.';
      }
      if (authUser.email?.toLowerCase() != email.trim().toLowerCase()) {
        return 'Use the email of your signed-in account to finish your profile.';
      }

      // Step 2: Insert player row into `players` table
      final playerData = await client
          .from('players')
          .insert({
            'auth_user_id': authUser.id,
            'roll_number': rollNumber.trim(),
            'full_name': fullName.trim(),
            'email': email.trim().toLowerCase(),
            'role': UserRole.player.name,
            'avatar_url': avatarUrl ??
                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
            'playstyle': playstyle,
            'dominant_hand': dominantHand,
            'base_smash': 70,
            'base_agility': 70,
            'base_stamina': 70,
            'base_consistency': 70,
            'elo_rating': 1200,
            'is_active': true,
          })
          .select()
          .single();

      final newProfile = PlayerProfile.fromMap(playerData);

      // Step 3: Insert initial gear log if racket info provided
      if (racketBrandModel != null && racketBrandModel.trim().isNotEmpty) {
        try {
          await client.from('gear_logs').insert({
            'player_id': newProfile.id,
            'racket_brand_model': racketBrandModel.trim(),
            'string_model': (stringModel ?? 'Yonex BG65').trim(),
            'tension_lbs': tensionLbs ?? 26.0,
            'stringing_date': DateTime.now().toIso8601String().split('T').first,
            'expected_restring_date': DateTime.now()
                .add(const Duration(days: 45))
                .toIso8601String()
                .split('T')
                .first,
            'notes': 'Initial setup registered on joining SmashDeck.',
          });
        } catch (_) {/* The profile is created; gear can be added later. */}
      }

      // Step 4: Set state
      setPlayer(newProfile);
      return null; // null = success
    } on AuthException catch (e) {
      return e.message;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return 'Roll number or email already registered. Please sign in.';
      }
      return 'Database error: ${e.message}';
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  /// Signs out the current user from Supabase Auth & clears local state
  Future<void> signOut() async {
    _sessionRevision++;
    if (mounted) state = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_player_id');
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    if (mounted) state = null;
  }
}

/// Global provider for the active logged-in player profile (nullable)
final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, PlayerProfile?>((ref) {
  return CurrentUserNotifier();
});

/// Player gear logs provider — loads from Supabase
class UserGearNotifier extends StateNotifier<List<GearLog>> {
  UserGearNotifier() : super([]);

  void addGear(GearLog gear) {
    state = [gear, ...state];
  }

  void setGears(List<GearLog> gears) {
    state = gears;
  }
}

final userGearLogsProvider =
    StateNotifierProvider<UserGearNotifier, List<GearLog>>((ref) {
  return UserGearNotifier();
});

/// All players from Supabase `players` table — used by Players list, match setup, etc.
final allPlayersProvider = FutureProvider<List<PlayerProfile>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final response = await supabase
      .from('players')
      .select()
      .eq('is_active', true)
      .order('elo_rating', ascending: false);

  return (response as List<dynamic>)
      .map((item) => PlayerProfile.fromMap(item as Map<String, dynamic>))
      .toList();
});
