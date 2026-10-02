import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

/// Supabase Client Service Wrapper
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Initialize Supabase with local-first offline awareness
  static Future<void> initialize({
    String? url,
    String? anonKey,
  }) async {
    final supabaseUrl = url ?? AppConstants.supabaseUrl;
    final supabaseAnonKey = anonKey ?? AppConstants.supabaseAnonKey;

    await Supabase.initialize(
      url: supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }
}

/// Global Riverpod Provider for Supabase Client
/// Always returns Supabase.instance.client — no separate state needed
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Current Auth User Provider
final currentAuthUserProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange
      .map((event) => event.session?.user);
});
