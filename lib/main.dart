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
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize Supabase with configuration
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  
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
