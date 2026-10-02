import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../home/main_navigation_wrapper.dart';
import 'auth_state.dart';
import 'current_user_notifier.dart';
import 'login_screen.dart';

/// Auth Gate: Listens to Supabase auth state changes and routes accordingly.
///
/// Flow:
///   No session                → LoginScreen (Sign In / Join as New Member)
///   Session + player row      → MainNavigationWrapper (Home)
///   Session + no player row   → LoginScreen (complete profile first)
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Check if active user profile is already set in memory / restored from storage
    final activeUser = ref.watch(currentUserProvider);
    ref.watch(authChangesProvider);

    if (activeUser != null && activeUser.isActive) {
      return const MainNavigationWrapper();
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Show loading spinner while stream initialises
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingSplash();
        }

        final session = snapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;

        if (session == null) {
          // No logged-in user → Stitch login & registration screen
          return const LoginScreen();
        }

        // User is authenticated — fetch their player profile
        return _ProfileGate(authUserId: session.user.id);
      },
    );
  }
}

/// Second gate: checks if this auth user already has a player row in `players`.
class _ProfileGate extends ConsumerWidget {
  final String authUserId;
  const _ProfileGate({required this.authUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentPlayerProfileProvider);

    return profileAsync.when(
      loading: () => const _LoadingSplash(),
      error: (_, __) => const LoginScreen(),
      data: (profile) {
        if (profile == null || !profile.isActive) {
          // Auth user exists but no player row yet — send to login/join screen
          return const LoginScreen();
        }
        // Set the loaded profile in the notifier so all screens can access it
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted &&
              Supabase.instance.client.auth.currentUser?.id == authUserId) {
            ref.read(currentUserProvider.notifier).setPlayer(profile);
          }
        });
        return const MainNavigationWrapper();
      },
    );
  }
}

/// Full-screen loading spinner shown during auth/profile resolution
class _LoadingSplash extends StatelessWidget {
  const _LoadingSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
                color: AppTheme.limeNeon, strokeWidth: 2),
            const SizedBox(height: 16),
            Text(
              'SmashDeck',
              style: AppTheme.chivo(
                color: AppTheme.limeNeon,
                size: 20,
                weight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
