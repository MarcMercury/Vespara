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
          .select('is_verified, onboarding_complete')
          .eq('id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          // User has completed onboarding if onboarding_complete=true 
          // OR is_verified=true (for legacy accounts)
          _hasCompletedOnboarding = response != null &&
              (response['onboarding_complete'] == true ||
                  response['is_verified'] == true);
        });
      }
    } catch (e) {
      debugPrint('Vespara: Error checking onboarding: $e');
      // If profile doesn't exist, show onboarding
      if (mounted) {
        setState(() {
          _hasCompletedOnboarding = false;
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

    // Fully authenticated and onboarded
    return const HomeScreen();
  }
}
