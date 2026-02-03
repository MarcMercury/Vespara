import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base test helpers for Vespara widget tests
///
/// This file provides utilities for testing widgets that depend on:
/// - Riverpod providers
/// - Theme configuration
/// - Navigation

/// Wraps a widget with all necessary providers for testing
Widget createTestableWidget(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: child),
    ),
  );
}

/// Wraps a widget with navigation capabilities for testing
Widget createNavigableTestWidget(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: child,
      routes: {
        '/discover': (context) => const Scaffold(body: Text('Discover')),
        '/nest': (context) => const Scaffold(body: Text('Nest')),
        '/mirror': (context) => const Scaffold(body: Text('Mirror')),
        '/planner': (context) => const Scaffold(body: Text('Planner')),
        '/events': (context) => const Scaffold(body: Text('Events')),
        '/shredder': (context) => const Scaffold(body: Text('Shredder')),
        '/tag': (context) => const Scaffold(body: Text('Tag')),
      },
    ),
  );
}

/// Finds a widget by its semantic label
Finder findBySemanticsLabel(String label) {
  return find.bySemanticsLabel(label);
}

/// Pumps the widget and waits for animations to complete
Future<void> pumpAndSettleWithTimeout(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    timeout,
  );
}
