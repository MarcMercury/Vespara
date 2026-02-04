import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_html/html.dart' as html;

import 'core/config/env.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/onboarding/widgets/exclusive_onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Store OAuth params info BEFORE init (for debugging)
  bool hasOAuthParams = false;
  if (kIsWeb) {
    final uri = Uri.base;
    hasOAuthParams = uri.queryParameters.containsKey('code') ||
        uri.queryParameters.containsKey('access_token') ||
        uri.queryParameters.containsKey('error');
    
    if (hasOAuthParams) {
      debugPrint('Vespara: OAuth callback detected in URL');
    }
  }

  // Initialize Supabase FIRST - it needs to process OAuth tokens from the URL
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  // Clean OAuth params from URL AFTER Supabase has processed them
  if (kIsWeb && hasOAuthParams) {
    debugPrint('Vespara: Cleaning OAuth params from URL');
    final uri = Uri.base;
    html.window.history.replaceState(null, '', uri.path);
  }

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
  String? _currentUserId; // Track the actual user ID, not just session existence
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
      
      // Set up the ongoing auth listener FIRST
      // This ensures we don't miss any auth events
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        debugPrint('Vespara Auth: ${data.event} - session: ${data.session != null}');

        if (mounted) {
          final newUserId = data.session?.user.id;
          final userChanged = _currentUserId != newUserId;
          
          debugPrint('Vespara Auth: Previous user: $_currentUserId, New user: $newUserId, Changed: $userChanged');

          // CRITICAL: Check onboarding BEFORE setState to avoid showing wrong screen briefly
          if (data.session != null && (userChanged || _hasCompletedOnboarding == null)) {
            // Fetch onboarding status first, then update state
            _checkOnboardingStatus(data.session!.user.id).then((_) {
              if (mounted) {
                setState(() {
                  _session = data.session;
                  _currentUserId = newUserId;
                  _isLoading = false;
                });
              }
            });
          } else {
            setState(() {
              _session = data.session;
              _currentUserId = newUserId;
              _isLoading = false;
              if (data.session == null) {
                _hasCompletedOnboarding = null;
              }
            });
          }
        }
      });

      // Get current session AFTER setting up listener
      _session = Supabase.instance.client.auth.currentSession;
      _currentUserId = _session?.user.id;
      debugPrint('Vespara AuthGate: Initial session = ${_session != null}, userId = $_currentUserId');

      // Check onboarding status if we have a session
      if (_session != null) {
        await _checkOnboardingStatus(_session!.user.id);
      }

      debugPrint('Vespara AuthGate: Final session check = ${_session != null}, onboarding complete = $_hasCompletedOnboarding');
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
    debugPrint('Vespara: Checking onboarding status for user: $userId');
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, email, is_verified, onboarding_complete')
          .eq('id', userId)
          .maybeSingle();

      debugPrint('Vespara: Profile response: $response');

      if (mounted) {
        if (response == null) {
          debugPrint('Vespara: No profile found for user $userId - showing onboarding');
          setState(() {
            _hasCompletedOnboarding = false;
          });
        } else {
          final isComplete = response['onboarding_complete'] == true ||
              response['is_verified'] == true;
          debugPrint('Vespara: Profile found! onboarding_complete=${response['onboarding_complete']}, is_verified=${response['is_verified']}, isComplete=$isComplete');
          setState(() {
            _hasCompletedOnboarding = isComplete;
          });
        }
      }
    } catch (e) {
      debugPrint('Vespara: Error checking onboarding: $e');
      // On error, don't assume - let user retry
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
        queryParams: {
          'prompt': 'select_account', // Force Google to show account picker every time
        },
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
    bool isSignUp = false; // Toggle between sign in and sign up
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: VesparaColors.surface,
          title: Text(isSignUp ? 'Create Account' : 'Sign In with Email',
              style: const TextStyle(color: VesparaColors.primary),),
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
                  hintText: isSignUp ? 'Create password (min 6 chars)' : 'Password',
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
              if (!isSignUp)
                Text(
                  'Leave password empty for magic link',
                  style: TextStyle(
                    fontSize: 12,
                    color: VesparaColors.secondary.withOpacity(0.7),
                  ),
                ),
              const SizedBox(height: 12),
              // Toggle between sign in and sign up
              GestureDetector(
                onTap: () => setDialogState(() => isSignUp = !isSignUp),
                child: Text(
                  isSignUp 
                    ? 'Already have an account? Sign In'
                    : 'New user? Create Account',
                  style: TextStyle(
                    fontSize: 13,
                    color: VesparaColors.primary.withOpacity(0.8),
                    decoration: TextDecoration.underline,
                  ),
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
                
                if (isSignUp) {
                  // Sign up flow - requires password
                  await _signUpWithEmailPassword(email, password);
                } else if (password.isNotEmpty) {
                  // Sign in with password
                  await _signInWithEmailPassword(email, password);
                } else {
                  // Magic link
                  await _signInWithMagicLink(email);
                }
              },
              child: Text(isSignUp ? 'Create Account' : 'Sign In',
                  style: const TextStyle(color: VesparaColors.primary),),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signUpWithEmailPassword(String email, String password) async {
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email');
      return;
    }
    if (password.isEmpty || password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {
        if (response.session != null) {
          _showSuccess('Account created! Welcome to Vespara ✨');
        } else {
          // Email confirmation required
          _showSuccess('Check your email to confirm your account ✨');
        }
      }
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        _showError('This email is already registered. Try signing in instead.');
      } else {
        _showError('Sign up failed: ${e.message}');
      }
    } catch (e) {
      _showError('Sign up failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      if (e.message.contains('Invalid login credentials')) {
        _showError('Invalid email or password. Try again or create an account.');
      } else if (e.message.contains('Email not confirmed')) {
        _showError('Please confirm your email before signing in.');
      } else {
        _showError('Login failed: ${e.message}');
      }
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
        shouldCreateUser: true, // Allow new users to sign up via magic link
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
