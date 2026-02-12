/// Conditional export — resolves to web implementation when dart:html
/// is available (Flutter web builds), otherwise falls back to no-op stubs.
export 'web_orientation_stub.dart'
    if (dart.library.html) 'web_orientation_web.dart';
