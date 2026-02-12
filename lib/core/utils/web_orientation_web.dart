// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Lock screen orientation to landscape using the Web Screen Orientation API.
/// Many mobile browsers require fullscreen mode for orientation lock to work.
Future<void> lockWebLandscape() async {
  try {
    // Request fullscreen first — required by most mobile browsers for
    // the Screen Orientation API lock() to succeed.
    html.document.documentElement?.requestFullscreen();

    // Brief delay to let the fullscreen transition complete
    await Future.delayed(const Duration(milliseconds: 150));

    // Lock to landscape (accepts 'landscape', 'landscape-primary', etc.)
    await html.window.screen?.orientation?.lock('landscape');
  } catch (_) {
    // Orientation lock not supported or permission denied — graceful fallback
  }
}

/// Unlock orientation and exit fullscreen.
Future<void> unlockWebOrientation() async {
  try {
    html.window.screen?.orientation?.unlock();
  } catch (_) {
    // Ignore — unlock may fail if lock was never acquired
  }
  try {
    html.document.exitFullscreen();
  } catch (_) {
    // Ignore — may not be in fullscreen
  }
}
