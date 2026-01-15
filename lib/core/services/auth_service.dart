import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication Service for Vespara
/// Handles Apple Sign-In, Google Sign-In, and Email/Password auth
/// All auth flows return a user or throw [AuthException]
class AuthService {
  final SupabaseClient _supabase;
  
  AuthService(this._supabase);
  
  /// Current authenticated user
  User? get currentUser => _supabase.auth.currentUser;
  
  /// Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  /// Check if user has completed onboarding
  Future<bool> get isOnboardingComplete async {
    final user = currentUser;
    if (user == null) return false;
    
    final profile = await _supabase
        .from('profiles')
        .select('onboarding_complete')
        .eq('id', user.id)
        .maybeSingle();
    
    return profile?['onboarding_complete'] == true;
  }
  
  // ═══════════════════════════════════════════════════════════════
  // APPLE SIGN-IN
  // ═══════════════════════════════════════════════════════════════
  
  /// Generate a cryptographic nonce for Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }
  
  /// SHA256 hash of the nonce
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Sign in with Apple
  /// Returns the authenticated user or throws [AuthException]
  Future<User> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);
      
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      
      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException('Apple Sign-In failed: No identity token received');
      }
      
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
      
      final user = response.user;
      if (user == null) {
        throw const AuthException('Apple Sign-In failed: No user returned');
      }
      
      // Update profile with Apple-provided name if available
      if (credential.givenName != null || credential.familyName != null) {
        await _updateProfileName(
          user.id,
          credential.givenName,
          credential.familyName,
        );
      }
      
      return user;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthException('Sign-in was cancelled');
      }
      throw AuthException('Apple Sign-In failed: ${e.message}');
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // GOOGLE SIGN-IN
  // ═══════════════════════════════════════════════════════════════
  
  /// Sign in with Google
  /// Returns the authenticated user or throws [AuthException]
  Future<User> signInWithGoogle() async {
    try {
      // Web client ID for Google Sign-In
      const webClientId = '798449652396-8s803roe4946ob31cmffrllmqj1bfvr6.apps.googleusercontent.com';
      
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? webClientId : null,
        serverClientId: webClientId,
        scopes: ['email', 'profile'],
      );
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google Sign-In was cancelled');
      }
      
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;
      
      if (accessToken == null || idToken == null) {
        throw const AuthException('Google Sign-In failed: Missing tokens');
      }
      
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      final user = response.user;
      if (user == null) {
        throw const AuthException('Google Sign-In failed: No user returned');
      }
      
      // Update profile with Google-provided name
      final displayName = googleUser.displayName;
      if (displayName != null) {
        final nameParts = displayName.split(' ');
        await _updateProfileName(
          user.id,
          nameParts.isNotEmpty ? nameParts.first : null,
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null,
        );
      }
      
      return user;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Google Sign-In failed: $e');
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // EMAIL SIGN-IN
  // ═══════════════════════════════════════════════════════════════
  
  /// Sign in with email magic link (passwordless)
  Future<void> signInWithEmail(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.vespara://login-callback',
      );
    } catch (e) {
      throw AuthException('Failed to send magic link: $e');
    }
  }
  
  /// Sign up with email and password
  Future<User> signUpWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.vespara://login-callback',
      );
      
      final user = response.user;
      if (user == null) {
        throw const AuthException('Sign up failed: No user returned');
      }
      
      return user;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Sign up failed: $e');
    }
  }
  
  /// Sign in with email and password
  Future<User> signInWithPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      final user = response.user;
      if (user == null) {
        throw const AuthException('Sign in failed: Invalid credentials');
      }
      
      return user;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Sign in failed: $e');
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // SIGN OUT
  // ═══════════════════════════════════════════════════════════════
  
  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw AuthException('Sign out failed: $e');
    }
  }
  
  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════
  
  /// Update profile with name from OAuth provider
  Future<void> _updateProfileName(String userId, String? firstName, String? lastName) async {
    try {
      final updates = <String, dynamic>{};
      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      
      if (updates.isNotEmpty) {
        await _supabase
            .from('profiles')
            .update(updates)
            .eq('id', userId);
      }
    } catch (_) {
      // Silently fail - name update is not critical
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client);
});

/// Provides the current auth state
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Provides the current user (nullable)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});

/// Provides whether onboarding is complete
final isOnboardingCompleteProvider = FutureProvider<bool>((ref) async {
  return ref.watch(authServiceProvider).isOnboardingComplete;
});
