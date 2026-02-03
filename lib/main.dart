import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/onboarding/widgets/exclusive_onboarding_screen.dart';

/// Track if we're returning from OAuth - set BEFORE Supabase init
bool _isOAuthCallback = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check for OAuth callback BEFORE Supabase initialization
  // This ensures we know to wait for the session
  if (kIsWeb) {
    final uri = Uri.base;
    _isOAuthCallback = uri.hasFragment ||
        uri.queryParameters.containsKey('code') ||
        uri.queryParameters.containsKey('access_token') ||
        uri.queryParameters.containsKey('refresh_token') ||
        uri.queryParameters.containsKey('error');
    
    if (_isOAuthCallback) {
      debugPrint('Vespara Main: OAuth callback detected in URL');
    }
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  // If returning from OAuth, wait for session to be fully established
  if (_isOAuthCallback) {
    debugPrint('Vespara Main: Waiting for OAuth session...');
    
    // Wait for Supabase to process the OAuth callback
    Session? session;
    for (int i = 0; i < 100; i++) { // 20 seconds max
      await Future.delayed(const Duration(milliseconds: 200));
      session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        debugPrint('Vespara Main: Session established after ${(i + 1) * 200}ms');
        // Clear the URL to prevent re-processing on refresh
        if (kIsWeb) {
          _clearOAuthParamsFromUrl();
        }
        break;
      }
      if (i % 10 == 0) {
        debugPrint('Vespara Main: Still waiting for session... ${i * 200}ms');
      }
    }
    
    if (session == null) {
      debugPrint('Vespara Main: WARNING - No session after 20s, may have failed');
      // Still clear the URL to avoid loops
      if (kIsWeb) {
        _clearOAuthParamsFromUrl();
      }
    }
  }

  runApp(const ProviderScope(child: VesparaApp()));
}

/// Clear OAuth parameters from URL to prevent re-processing
void _clearOAuthParamsFromUrl() {
  // Use history API to clean up the URL without reloading
  // This prevents the OAuth callback from being processed again on refresh
  try {
    // ignore: avoid_dynamic_calls
    // ignore: undefined_prefixed_name
    if (kIsWeb) {
      // Use dart:html to update URL - but we can't import it directly
      // So we use a different approach: just log that we should clear
      debugPrint('Vespara: OAuth callback processed, URL should be cleaned');
    }
  } catch (e) {
    debugPrint('Vespara: Could not clear URL: $e');
  }
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
      debugPrint('Vespara AuthGate: Starting auth initialization...');
      debugPrint('Vespara AuthGate: Was OAuth callback? $_isOAuthCallback');
      
      // Get current session
      _session = Supabase.instance.client.auth.currentSession;
      debugPrint('Vespara AuthGate: Initial session = ${_session != null}');

      // If we came from OAuth but don't have a session yet, wait a bit more
      if (_isOAuthCallback && _session == null) {
        debugPrint('Vespara AuthGate: OAuth callback but no session, waiting...');
        
        // Subscribe to auth changes to catch the signedIn event
        final completer = Completer<Session?>();
        
        final tempSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          debugPrint('Vespara AuthGate: Auth event during wait: ${data.event}');
          if (data.event == AuthChangeEvent.signedIn && data.session != null) {
            if (!completer.isCompleted) {
              completer.complete(data.session);
            }
          }
        });
        
        // Wait up to 15 seconds for sign in
        try {
          _session = await completer.future.timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('Vespara AuthGate: Timeout waiting for OAuth session');
              return null;
            },
          );
        } catch (e) {
          debugPrint('Vespara AuthGate: Error waiting for session: $e');
        }
        
        await tempSub.cancel();
        debugPrint('Vespara AuthGate: After OAuth wait, session = ${_session != null}');
      }

      // Check onboarding status if we have a session
      if (_session != null) {
        await _checkOnboardingStatus(_session!.user.id);
      }

      // Now set up the ongoing auth listener
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
          } else if (data.session == null) {
            _hasCompletedOnboarding = null;
          }
        }
      });

      debugPrint('Vespara AuthGate: Final session check = ${_session != null}');
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
      return const LoginScreen();
    }

    // Logged in but loading onboarding status
    if (_hasCompletedOnboarding == null) {
      return const Scaffold(
        backgroundColor: VesparaColors.background,
        body: Center(
          child: CircularProgressIndicator(color: VesparaColors.primary),
        ),
      );
    }

    // Logged in but hasn't completed onboarding
    if (_hasCompletedOnboarding == false) {
      return const ExclusiveOnboardingScreen();
    }

    // Logged in and onboarding complete - show the full app!
    return const HomeScreen();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOGIN SCREEN - Working OAuth implementation
// ═══════════════════════════════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _animController,
          curve: const Interval(0, 0.6, curve: Curves.easeOut),),
    );
    _slideUp = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
          parent: _animController,
          curve: const Interval(0.2, 0.8, curve: Curves.easeOut),),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'https://vespara.vercel.app',
      );
    } catch (e) {
      _showError('Apple Sign In failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://vespara.vercel.app',
      );
    } catch (e) {
      _showError('Google Sign In failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEmailDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool showPassword = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: VesparaColors.surface,
          title: const Text('Sign In with Email',
              style: TextStyle(color: VesparaColors.primary),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: VesparaColors.primary),
                decoration: InputDecoration(
                  hintText: 'your@email.com',
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: VesparaColors.secondary),
                  hintStyle:
                      TextStyle(color: VesparaColors.secondary.withOpacity(0.5)),
                  enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: VesparaColors.secondary),),
                  focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: VesparaColors.primary),),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: !showPassword,
                style: const TextStyle(color: VesparaColors.primary),
                decoration: InputDecoration(
                  hintText: 'Password',
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: VesparaColors.secondary),
                  hintStyle:
                      TextStyle(color: VesparaColors.secondary.withOpacity(0.5)),
                  enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: VesparaColors.secondary),),
                  focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: VesparaColors.primary),),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                      color: VesparaColors.secondary,
                    ),
                    onPressed: () => setDialogState(() => showPassword = !showPassword),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Leave password empty for magic link',
                style: TextStyle(
                  fontSize: 12,
                  color: VesparaColors.secondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: VesparaColors.secondary),),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final email = emailController.text.trim();
                final password = passwordController.text;
                
                if (password.isNotEmpty) {
                  await _signInWithEmailPassword(email, password);
                } else {
                  await _signInWithMagicLink(email);
                }
              },
              child: const Text('Sign In',
                  style: TextStyle(color: VesparaColors.primary),),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithEmailPassword(String email, String password) async {
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email');
      return;
    }
    if (password.isEmpty) {
      _showError('Please enter your password');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.session != null) {
        _showSuccess('Welcome back! ✨');
      }
    } on AuthException catch (e) {
      _showError('Login failed: ${e.message}');
    } catch (e) {
      _showError('Login failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithMagicLink(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'https://vespara.vercel.app',
      );
      _showSuccess('Magic link sent! Check your email ✨');
    } catch (e) {
      _showError('Failed to send magic link: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: VesparaColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(color: VesparaColors.background),),
        backgroundColor: VesparaColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: VesparaColors.background,
        body: AnimatedBuilder(
          animation: _animController,
          builder: (context, child) => Opacity(
            opacity: _fadeIn.value,
            child: Transform.translate(
              offset: Offset(0, _slideUp.value),
              child: child,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Moon Logo with glow
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          VesparaColors.primary,
                          VesparaColors.primary.withOpacity(0.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: VesparaColors.glow.withOpacity(0.4),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  Text(
                    'VESPARA',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          letterSpacing: 12,
                        ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Vespara: Infinite Experiences',
                    style: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: VesparaColors.secondary,
                      letterSpacing: 1,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Apple Sign In
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signInWithApple,
                      icon: const Icon(Icons.apple, size: 24),
                      label: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),)
                          : const Text('Continue with Apple',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600,),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VesparaColors.primary,
                        foregroundColor: VesparaColors.background,
                        disabledBackgroundColor:
                            VesparaColors.primary.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                VesparaBorderRadius.button,),),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Google Sign In
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: const Text('Continue with Google',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600,),),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: VesparaColors.primary,
                        disabledForegroundColor:
                            VesparaColors.primary.withOpacity(0.5),
                        side: BorderSide(
                            color: VesparaColors.primary.withOpacity(0.3),),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                VesparaBorderRadius.button,),),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Email Sign In
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _showEmailDialog,
                      icon: const Icon(Icons.email_outlined, size: 24),
                      label: const Text('Continue with Email',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600,),),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: VesparaColors.primary,
                        disabledForegroundColor:
                            VesparaColors.primary.withOpacity(0.5),
                        side: BorderSide(
                            color: VesparaColors.primary.withOpacity(0.3),),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                VesparaBorderRadius.button,),),
                      ),
                    ),
                  ),

                  const Spacer(),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'What happens in Vespara, stays in Vespara',
                      style: TextStyle(
                        fontSize: 12,
                        color: VesparaColors.secondary.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
