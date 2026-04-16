import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/services/admin_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart' as auth;
import 'features/home/presentation/home_screen_v2.dart';
import 'features/onboarding/widgets/exclusive_onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: VesparaApp()));
}

class VesparaApp extends StatelessWidget {
  const VesparaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Vespara',
        debugShowCheckedModeBanner: false,
        theme: VesparaTheme.dark,
        home: const AuthGate(),
      );
}

/// Listens to auth state and shows appropriate screen
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  Session? _session;
  String? _error;
  bool? _hasCompletedOnboarding;
  String? _membershipStatus;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initAuth() async {
    try {
      // Get current session
      _session = Supabase.instance.client.auth.currentSession;

      // Check onboarding status if we have a session
      if (_session != null) {
        await _checkOnboardingStatus(_session!.user.id);
      }

      // Set up the ongoing auth listener
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        debugPrint('Vespara Auth: ${data.event} - session: ${data.session != null}');

        if (mounted) {
          final isTokenRefresh = data.event == AuthChangeEvent.tokenRefreshed;
          final hadSession = _session != null;
          final hasSession = data.session != null;
          final sessionChanged = hadSession != hasSession;

          setState(() {
            _session = data.session;
            _isLoading = false;
          });

          // Check onboarding status when session changes OR on token refresh
          if (data.session != null && (sessionChanged || isTokenRefresh)) {
            _checkOnboardingStatus(data.session!.user.id);
            // Track login for admin portal
            if (data.event == AuthChangeEvent.signedIn) {
              AdminService.trackLogin();
            }
          } else if (data.session == null) {
            _hasCompletedOnboarding = null;
            _membershipStatus = null;
          }
        }
      });
    } catch (e) {
      debugPrint('Vespara Auth Error: $e');
      _error = e.toString();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkOnboardingStatus(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('is_verified, onboarding_complete, membership_status')
          .eq('id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _hasCompletedOnboarding = response != null &&
              (response['onboarding_complete'] == true ||
                  response['is_verified'] == true);
          _membershipStatus = response?['membership_status'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Vespara: Error checking onboarding: $e');
      if (mounted) {
        setState(() {
          _hasCompletedOnboarding = false;
          _membershipStatus = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: VesparaColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: VesparaColors.primary),
              SizedBox(height: 16),
              Text('Loading...',
                  style: TextStyle(color: VesparaColors.secondary),),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: VesparaColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: VesparaColors.error, size: 48,),
              const SizedBox(height: 16),
              Text('Error: $_error',
                  style: const TextStyle(color: VesparaColors.error),),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _initAuth();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Not logged in - show login screen
    if (_session == null) {
      return const auth.LoginScreen();
    }

    // Onboarding not yet complete
    if (_hasCompletedOnboarding == false) {
      return const ExclusiveOnboardingScreen();
    }

    // Account pending approval
    if (_membershipStatus == 'pending' || _membershipStatus == null) {
      return PendingApprovalScreen(
        onRefresh: () => _checkOnboardingStatus(_session!.user.id),
        onLogout: () async {
          await Supabase.instance.client.auth.signOut();
        },
      );
    }

    // Account suspended or banned
    if (_membershipStatus == 'suspended' || _membershipStatus == 'banned') {
      return AccountSuspendedScreen(
        status: _membershipStatus!,
        onLogout: () async {
          await Supabase.instance.client.auth.signOut();
        },
      );
    }

    // Fully authenticated, onboarded, and approved
    return const HomeScreen();
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// PENDING APPROVAL SCREEN
/// Shown after onboarding while waiting for admin approval
/// ════════════════════════════════════════════════════════════════════════════

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({
    super.key,
    required this.onRefresh,
    required this.onLogout,
  });

  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo / Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      VesparaColors.glow.withOpacity(0.3),
                      VesparaColors.glow.withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: VesparaColors.glow.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 48,
                  color: VesparaColors.glow,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'AWAITING APPROVAL',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: VesparaColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your profile is being reviewed by our team. '
                'You\'ll get access once approved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: VesparaColors.secondary.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // Refresh button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, color: VesparaColors.background),
                  label: const Text(
                    'Check Status',
                    style: TextStyle(
                      color: VesparaColors.background,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VesparaColors.glow,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Logout
              TextButton(
                onPressed: onLogout,
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: VesparaColors.secondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════════════════
/// ACCOUNT SUSPENDED SCREEN
/// Shown when account has been suspended or banned
/// ════════════════════════════════════════════════════════════════════════════

class AccountSuspendedScreen extends StatelessWidget {
  const AccountSuspendedScreen({
    super.key,
    required this.status,
    required this.onLogout,
  });

  final String status;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final isBanned = status == 'banned';

    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                isBanned ? Icons.block_rounded : Icons.pause_circle_outline,
                size: 64,
                color: VesparaColors.error,
              ),
              const SizedBox(height: 24),
              Text(
                isBanned ? 'ACCOUNT BANNED' : 'ACCOUNT SUSPENDED',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  color: VesparaColors.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isBanned
                    ? 'Your account has been permanently banned.'
                    : 'Your account has been temporarily suspended. Please contact support.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: VesparaColors.secondary.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onLogout,
                child: const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: VesparaColors.secondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
