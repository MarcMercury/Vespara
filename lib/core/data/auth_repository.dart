import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// AUTH REPOSITORY
/// Handles all authentication and profile creation logic
/// ════════════════════════════════════════════════════════════════════════════

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  /// Current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Sign in with Google OAuth
  Future<AuthResponse> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.vespara://login-callback',
    ).then((_) async {
      // Wait for the auth state to update
      await Future.delayed(const Duration(milliseconds: 500));
      final session = _supabase.auth.currentSession;
      return AuthResponse(session: session, user: session?.user);
    });
  }

  /// Sign in with Apple OAuth
  Future<AuthResponse> signInWithApple() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.vespara://login-callback',
    ).then((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      final session = _supabase.auth.currentSession;
      return AuthResponse(session: session, user: session?.user);
    });
  }

  /// Sign in with email magic link
  Future<void> signInWithMagicLink(String email) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      emailRedirectTo: 'io.vespara://login-callback',
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  /// Update user profile
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _supabase
        .from('profiles')
        .update(data)
        .eq('id', userId);
  }

  /// Check if onboarding is complete
  Future<bool> isOnboardingComplete(String userId) async {
    final profile = await getProfile(userId);
    return profile?['onboarding_complete'] == true;
  }
}

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

/// Stream provider for auth state changes
final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Provider for current authenticated user
final authenticatedUserProvider = Provider<User?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser;
});
