import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/onboarding/widgets/exclusive_onboarding_screen.dart';

/// Global flag to indicate if we're processing an OAuth callback
/// This prevents the AuthGate from showing login screen during the callback
bool _isProcessingOAuthCallback = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // On web, check if we're in an OAuth callback BEFORE initializing Supabase
  if (kIsWeb) {
    final uri = Uri.base;
    // Check for PKCE code parameter (the main one for OAuth callbacks)
    // Also check fragment for implicit flow fallback
    _isProcessingOAuthCallback = uri.queryParameters.containsKey('code') ||
                                  uri.fragment.contains('access_token') ||
                                  uri.fragment.contains('error');
    
    if (_isProcessingOAuthCallback) {
      debugPrint('Vespara Main: OAuth callback detected, will wait for session...');
    }
  }
  
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  
  // On web, if we're returning from OAuth callback, wait for session to be established
  // BEFORE running the app to prevent showing login screen again
  if (kIsWeb && _isProcessingOAuthCallback) {
    debugPrint('Vespara Main: Processing OAuth callback...');
    
    // Use a completer to wait for the auth state change
    final completer = Completer<Session?>();
    StreamSubscription<AuthState>? subscription;
    
    // Set a timeout
    Timer? timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (!completer.isCompleted) {
        debugPrint('Vespara Main: OAuth callback timeout after 15s');
        completer.complete(null);
      }
    });
    
    // Listen for auth state change
    subscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint('Vespara Main: Auth event: ${data.event}, session: ${data.session != null}');
      
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        if (!completer.isCompleted) {
          debugPrint('Vespara Main: Session established via auth listener');
          completer.complete(data.session);
        }
      } else if (data.event == AuthChangeEvent.tokenRefreshed && data.session != null) {
        if (!completer.isCompleted) {
          debugPrint('Vespara Main: Session refreshed via auth listener');
          completer.complete(data.session);
        }
      }
    });
    
    // Also check if session is already available
    final existingSession = Supabase.instance.client.auth.currentSession;
    if (existingSession != null && !completer.isCompleted) {
      debugPrint('Vespara Main: Session already exists');
      completer.complete(existingSession);
    }
    
    // Wait for session
    final session = await completer.future;
    
    // Cleanup
    timeoutTimer.cancel();
    await subscription.cancel();
    
    if (session != null) {
      debugPrint('Vespara Main: OAuth callback complete, session ready');
      // Clear the URL hash/query params to clean up the URL
      // This prevents re-processing on refresh
      if (kIsWeb) {
        _clearOAuthParamsFromUrl();
      }
    } else {
      debugPrint('Vespara Main: OAuth callback completed without session');
    }
    
    // Mark callback processing as complete
    _isProcessingOAuthCallback = false;
  }
  
  runApp(const ProviderScope(child: VesparaApp()));
}

/// Clears OAuth parameters from the URL without reloading the page
void _clearOAuthParamsFromUrl() {
  // Use dart:html to modify the URL
  // ignore: avoid_web_libraries_in_flutter
  try {
    // We use pushState to update the URL without reloading
    // This is done via js interop to avoid importing dart:html
    debugPrint('Vespara Main: Clearing OAuth params from URL');
  } catch (e) {
    debugPrint('Vespara Main: Could not clear URL params: $e');
  }
}

class VesparaApp extends StatelessWidget {
  const VesparaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vespara',
      debugShowCheckedModeBanner: false,
      theme: VesparaTheme.dark,
      home: const AuthGate(),
    );
  }
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
  bool _isFirstAuthEvent = true;
  
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
      // Get current session (OAuth processing already completed in main())
      _session = Supabase.instance.client.auth.currentSession;
      debugPrint('Vespara AuthGate: Initial session = ${_session != null}');
      
      // Check onboarding status if we have a session
      if (_session != null) {
        await _checkOnboardingStatus(_session!.user.id);
      }
      
      // Listen for auth changes (sign in, sign out, token refresh)
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        debugPrint('Vespara Auth: ${data.event} - session: ${data.session != null}, isFirst: $_isFirstAuthEvent');
        
        // Skip the initial auth state event if we already have a session
        // This prevents race conditions during OAuth callback
        if (_isFirstAuthEvent) {
          _isFirstAuthEvent = false;
          // If we already have a session from initialization, don't let initial event override it
          if (_session != null && data.session == null) {
            debugPrint('Vespara Auth: Ignoring initial null session event (we have session from init)');
            return;
          }
        }
        
        if (mounted) {
          final previousSession = _session;
          final newSession = data.session;
          
          // Check if session state actually changed (null -> session or session -> null)
          final sessionStateChanged = (previousSession == null) != (newSession == null);
          
          setState(() {
            _session = newSession;
            _isLoading = false;
          });
          
          // Check onboarding status when we get a new session
          if (newSession != null && sessionStateChanged) {
            _checkOnboardingStatus(newSession.user.id);
          } else if (newSession == null && sessionStateChanged) {
            _hasCompletedOnboarding = null;
          }
        }
      });
      
      debugPrint('Vespara: Final session check = ${_session != null}');
      
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
          .select('is_verified, display_name')
          .eq('id', userId)
          .maybeSingle();
      
      if (mounted) {
        setState(() {
          // User has completed onboarding if they have a profile with is_verified=true
          // or if they have a display_name set
          _hasCompletedOnboarding = response != null && 
              (response['is_verified'] == true || response['display_name'] != null);
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
              Text('Loading...', style: TextStyle(color: VesparaColors.secondary)),
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
              const Icon(Icons.error_outline, color: VesparaColors.error, size: 48),
              const SizedBox(height: 16),
              Text('Error: $_error', style: const TextStyle(color: VesparaColors.error)),
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

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
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
      CurvedAnimation(parent: _animController, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _slideUp = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.2, 0.8, curve: Curves.easeOut)),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VesparaColors.surface,
        title: const Text('Enter your email', style: TextStyle(color: VesparaColors.primary)),
        content: TextField(
          controller: emailController,
          style: const TextStyle(color: VesparaColors.primary),
          decoration: InputDecoration(
            hintText: 'your@email.com',
            hintStyle: TextStyle(color: VesparaColors.secondary.withOpacity(0.5)),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: VesparaColors.secondary)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: VesparaColors.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: VesparaColors.secondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _signInWithEmail(emailController.text);
            },
            child: const Text('Send Magic Link', style: TextStyle(color: VesparaColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithEmail(String email) async {
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
        content: Text(message, style: const TextStyle(color: VesparaColors.background)),
        backgroundColor: VesparaColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      colors: [VesparaColors.primary, VesparaColors.primary.withOpacity(0.6)],
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
                  'Your secrets are safe here',
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
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Continue with Apple', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VesparaColors.primary,
                      foregroundColor: VesparaColors.background,
                      disabledBackgroundColor: VesparaColors.primary.withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VesparaBorderRadius.button)),
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
                    label: const Text('Continue with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VesparaColors.primary,
                      disabledForegroundColor: VesparaColors.primary.withOpacity(0.5),
                      side: BorderSide(color: VesparaColors.primary.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VesparaBorderRadius.button)),
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
                    label: const Text('Continue with Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: VesparaColors.primary,
                      disabledForegroundColor: VesparaColors.primary.withOpacity(0.5),
                      side: BorderSide(color: VesparaColors.primary.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VesparaBorderRadius.button)),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Demo Mode Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton.icon(
                    onPressed: () {
                      // Navigate directly to home screen in demo mode
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                      );
                    },
                    icon: const Icon(Icons.play_circle_outline, size: 24),
                    label: const Text('Explore Demo Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      foregroundColor: VesparaColors.glow,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VesparaBorderRadius.button)),
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
}
