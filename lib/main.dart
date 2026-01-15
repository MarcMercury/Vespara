import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  
  debugPrint('Vespara: Supabase URL = ${Env.supabaseUrl}');
  debugPrint('Vespara: Initializing Supabase...');
  
  // Initialize Supabase with configuration
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    debugPrint('Vespara: Supabase initialized successfully');
  } catch (e) {
    debugPrint('Vespara: Supabase initialization error: $e');
    // Continue anyway - app should still load
  }
  
  debugPrint('Vespara: Running app...');
  
  // Run the application wrapped in ProviderScope
  runApp(
    const ProviderScope(
      child: VesparaApp(),
    ),
  );
}

/// The root Vespara application widget
class VesparaApp extends ConsumerWidget {
  const VesparaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      // ═══════════════════════════════════════════════════════════════════════
      // APP METADATA
      // ═══════════════════════════════════════════════════════════════════════
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      
      // ═══════════════════════════════════════════════════════════════════════
      // THEME CONFIGURATION - THE VESPARA NIGHT
      // ═══════════════════════════════════════════════════════════════════════
      theme: VesparaTheme.dark,
      darkTheme: VesparaTheme.dark,
      themeMode: ThemeMode.dark, // Always dark - Vespara is nocturnal
      
      // ═══════════════════════════════════════════════════════════════════════
      // NAVIGATION
      // ═══════════════════════════════════════════════════════════════════════
      routerConfig: router,
    );
  }
}

/// Global Supabase client accessor
SupabaseClient get supabase => Supabase.instance.client;
