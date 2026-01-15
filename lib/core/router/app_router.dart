import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/ludus/presentation/tags_screen.dart';
import '../../features/roster/presentation/roster_screen.dart';
import '../../features/wire/presentation/wire_screen.dart';
import '../../features/scope/presentation/scope_screen.dart';
import '../../features/strategist/presentation/strategist_screen.dart';
import '../../features/shredder/presentation/shredder_screen.dart';
import '../../features/core/presentation/core_screen.dart';
import '../../features/mirror/presentation/mirror_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';

/// Auth state notifier for router refresh
class AuthNotifier extends ChangeNotifier {
  bool _initialized = false;
  
  void initialize() {
    if (_initialized) return;
    _initialized = true;
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((event) {
        debugPrint('Auth state changed: ${event.event}');
        notifyListeners();
      });
    } catch (e) {
      debugPrint('AuthNotifier: Could not listen to auth changes: $e');
    }
  }
}

final _authNotifier = AuthNotifier();

/// Router provider for the entire application
final routerProvider = Provider<GoRouter>((ref) {
  // Initialize auth notifier lazily
  _authNotifier.initialize();
  
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      try {
        final session = Supabase.instance.client.auth.currentSession;
        final isLoggedIn = session != null;
        final isLoggingIn = state.matchedLocation == '/login';
        
        debugPrint('Router redirect: location=${state.matchedLocation}, loggedIn=$isLoggedIn');
        
        // Not logged in - redirect to login (except if already there)
        if (!isLoggedIn) {
          return isLoggingIn ? null : '/login';
        }
        
        // Logged in but on login page - go to home
        if (isLoggingIn) {
          return '/home';
        }
        
        return null;
      } catch (e) {
        debugPrint('Router redirect error: $e');
        // On error, go to login
        return state.matchedLocation == '/login' ? null : '/login';
      }
    },
    routes: [
      // ═══════════════════════════════════════════════════════════════════════
      // AUTH ROUTES
      // ═══════════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // MAIN DASHBOARD
      // ═══════════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          // ═══════════════════════════════════════════════════════════════════
          // TILE 1: THE STRATEGIST
          // ═══════════════════════════════════════════════════════════════════
          GoRoute(
            path: 'strategist',
            name: 'strategist',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const StrategistScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          
          // ═══════════════════════════════════════════════════════════════════
          // TILE 2: THE SCOPE
          // ═══════════════════════════════════════════════════════════════════
          GoRoute(
            path: 'scope',
            name: 'scope',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ScopeScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          
          // ═══════════════════════════════════════════════════════════════════
          // TILE 3: THE ROSTER
          // ═══════════════════════════════════════════════════════════════════
          GoRoute(
            path: 'roster',
            name: 'roster',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const RosterScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          
          // ═══════════════════════════════════════════════════════════════════
          // TILE 4: THE WIRE
          // ═══════════════════════════════════════════════════════════════════
          GoRoute(
            path: 'wire',
            name: 'wire',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const WireScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          
          // ═══════════════════════════════════════════════════════════════════
          // TILE 5: THE SHREDDER
          // ═══════════════════════════════════════════════════════════════════
          GoRoute(
            path: 'shredder',
            name: 'shredder',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ShredderScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          
          // ═══════════════════════════════════════════════════════════════════
          // TILE 6: THE LUDUS (TAGS)
          // ═══════════════════════════════════════════════════════════════════
          GoRoute(
            path: 'ludus',
            name: 'ludus',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const TagsScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          
          // ═══════════════════════════════════════════════════════════════════
          // TILE 7: THE CORE
          // ═══════════════════════════════════════════════════════════════════
          GoRoute(
            path: 'core',
            name: 'core',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const CoreScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          
          // ═══════════════════════════════════════════════════════════════════
          // TILE 8: THE MIRROR
          // ═══════════════════════════════════════════════════════════════════
          GoRoute(
            path: 'mirror',
            name: 'mirror',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const MirrorScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});

/// Fade transition for smooth page changes
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
    child: child,
  );
}
