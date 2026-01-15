import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

/// Vespara - Social Operating System
/// A luxury relationship management platform with TAGS game engine
Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('Vespara: Starting app initialization...');
  
  // Set system UI overlay style for luxury dark aesthetic
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: VesparaColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Lock to portrait orientation for optimal Bento Grid experience
  // Skip on web as it's not supported
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  
  // Load environment variables (skip on web if using --dart-define)
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Warning: .env file not found, using dart-define values');
    }
  }
  
  // Configure Google Fonts for web - use system fonts as fallback
  GoogleFonts.config.allowRuntimeFetching = true;
  
  debugPrint('Vespara: Supabase URL = ${Env.supabaseUrl}');
  debugPrint('Vespara: Initializing Supabase...');
  
  // Initialize Supabase with configuration
  bool supabaseInitialized = false;
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    supabaseInitialized = true;
    debugPrint('Vespara: Supabase initialized successfully');
  } catch (e) {
    debugPrint('Vespara: Supabase initialization error: $e');
  }
  
  debugPrint('Vespara: Running app...');
  
  // Set up error handling for Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };
  
  // Run the application wrapped in ProviderScope
  runApp(
    ProviderScope(
      child: VesparaApp(supabaseReady: supabaseInitialized),
    ),
  );
}

/// The root Vespara application widget
class VesparaApp extends ConsumerWidget {
  final bool supabaseReady;
  
  const VesparaApp({super.key, required this.supabaseReady});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('VesparaApp.build called, supabaseReady: $supabaseReady');
    
    // If Supabase didn't initialize, show error
    if (!supabaseReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _buildSimpleTheme(),
        home: const _ErrorScreen(message: 'Unable to connect to server'),
      );
    }
    
    // Get router
    GoRouter router;
    try {
      router = ref.watch(routerProvider);
      debugPrint('Router created successfully');
    } catch (e, stack) {
      debugPrint('Router error: $e');
      debugPrint('Stack: $stack');
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _buildSimpleTheme(),
        home: _ErrorScreen(message: 'Router Error: $e'),
      );
    }
    
    // Use simple theme to avoid Google Fonts issues on web
    final theme = _buildSimpleTheme();
    debugPrint('Theme created successfully');
    
    debugPrint('Returning MaterialApp.router');
    
    return MaterialApp.router(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
  
  /// Build a simple theme without Google Fonts to avoid web loading issues
  static ThemeData _buildSimpleTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: VesparaColors.primary,
        onPrimary: VesparaColors.background,
        secondary: VesparaColors.secondary,
        onSecondary: VesparaColors.background,
        surface: VesparaColors.surface,
        onSurface: VesparaColors.primary,
        error: VesparaColors.error,
        onError: VesparaColors.background,
      ),
      scaffoldBackgroundColor: VesparaColors.background,
      canvasColor: VesparaColors.background,
      // Use default fonts instead of Google Fonts
      fontFamily: 'sans-serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: VesparaColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: VesparaColors.primary,
          letterSpacing: 2,
        ),
        iconTheme: IconThemeData(
          color: VesparaColors.primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: VesparaColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(
            color: VesparaColors.border,
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VesparaColors.primary,
          foregroundColor: VesparaColors.background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

/// Simple error screen widget
class _ErrorScreen extends StatelessWidget {
  final String message;
  
  const _ErrorScreen({required this.message});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VesparaColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'VESPARA',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w500,
                color: VesparaColors.primary,
                letterSpacing: 12,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
