import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/strategist/presentation/strategist_screen.dart';
import '../../features/scope/presentation/scope_screen.dart';
import '../../features/roster/presentation/roster_screen.dart';
import '../../features/wire/presentation/wire_screen.dart';
import '../../features/wire/presentation/wire_home_screen.dart';
import '../../features/wire/presentation/wire_chat_screen.dart';
import '../../features/wire/presentation/wire_create_group_screen.dart';
import '../../features/wire/presentation/wire_group_info_screen.dart';
import '../../features/shredder/presentation/shredder_screen.dart';
import '../../features/ludus/presentation/tags_screen.dart';
import '../../features/core/presentation/core_screen.dart';
import '../../features/mirror/presentation/mirror_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/events/presentation/events_home_screen.dart';
import '../../features/events/presentation/event_creation_screen.dart';

/// App Router Provider
/// Uses GoRouter for declarative routing with auth redirects
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,
    
    // Redirect logic based on auth state
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isOnboarding = state.matchedLocation == '/onboarding';
      
      // Not logged in - redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      
      // Logged in but on login page - redirect to home
      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }
      
      return null;
    },
    
    routes: [
      // ═══════════════════════════════════════════════════════════════════════
      // AUTH ROUTES
      // ═══════════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SizedBox(), // Login is handled by AuthGate in main.dart
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      
      // ═══════════════════════════════════════════════════════════════════════
      // MAIN APP ROUTES
      // ═══════════════════════════════════════════════════════════════════════
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
        routes: [
          // ═════════════════════════════════════════════════════════════════════
          // FEATURE ROUTES (nested under /home)
          // ═════════════════════════════════════════════════════════════════════
          
          // Tile 1: The Strategist
          GoRoute(
            path: 'strategist',
            name: 'strategist',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const StrategistScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          
          // Tile 2: The Scope
          GoRoute(
            path: 'scope',
            name: 'scope',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ScopeScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          
          // Tile 3: The Roster
          GoRoute(
            path: 'roster',
            name: 'roster',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const RosterScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          
          // Tile 4: The Wire
          GoRoute(
            path: 'wire',
            name: 'wire',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const WireHomeScreen(),
              transitionsBuilder: _fadeTransition,
            ),
            routes: [
              // Wire chat conversation
              GoRoute(
                path: 'chat/:conversationId',
                name: 'wire-chat',
                pageBuilder: (context, state) {
                  final conversationId = state.pathParameters['conversationId']!;
                  return CustomTransitionPage(
                    key: state.pageKey,
                    child: WireChatScreen(conversationId: conversationId),
                    transitionsBuilder: _slideTransition,
                  );
                },
              ),
              // Create new group
              GoRoute(
                path: 'create-group',
                name: 'wire-create-group',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const WireCreateGroupScreen(),
                  transitionsBuilder: _slideTransition,
                ),
              ),
              // Group info/settings
              GoRoute(
                path: 'group-info/:conversationId',
                name: 'wire-group-info',
                pageBuilder: (context, state) {
                  final conversationId = state.pathParameters['conversationId']!;
                  return CustomTransitionPage(
                    key: state.pageKey,
                    child: WireGroupInfoScreen(conversationId: conversationId),
                    transitionsBuilder: _slideTransition,
                  );
                },
              ),
            ],
          ),
          
          // Tile 5: The Shredder
          GoRoute(
            path: 'shredder',
            name: 'shredder',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ShredderScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          
          // Tile 6: The Ludus (TAGS)
          GoRoute(
            path: 'ludus',
            name: 'ludus',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const TagsScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          
          // Tile 7: The Core
          GoRoute(
            path: 'core',
            name: 'core',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const CoreScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          
          // Tile 8: The Mirror
          GoRoute(
            path: 'mirror',
            name: 'mirror',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const MirrorScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          
          // Events - Partiful-style event management
          GoRoute(
            path: 'events',
            name: 'events',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const EventsHomeScreen(),
              transitionsBuilder: _fadeTransition,
            ),
            routes: [
              GoRoute(
                path: 'create',
                name: 'event-create',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const EventCreationScreen(),
                  transitionsBuilder: _fadeTransition,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Fade transition for all routes
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

/// Slide transition for detail screens
Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    )),
    child: child,
  );
}
