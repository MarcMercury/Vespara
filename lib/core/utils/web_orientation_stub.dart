/// Stub implementation for non-web platforms.
/// These are no-ops since native uses SystemChrome.setPreferredOrientations.

Future<void> lockWebLandscape() async {
  // No-op on non-web platforms
}

Future<void> unlockWebOrientation() async {
  // No-op on non-web platforms
}
