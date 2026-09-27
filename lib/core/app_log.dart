import 'package:flutter/foundation.dart';

/// A centralized logging utility handling both Diagnostic Logging (Debug)
/// and Operational Telemetry (Production).
class AppLog {
  AppLog._(); // Private constructor to prevent instantiation

  // ==========================================
  // 1. DIAGNOSTIC LOGGING (DEBUG ONLY)
  // ==========================================
  // These methods are completely stripped from the App Store release build
  // ensuring zero performance impact and total privacy for on-device logic.

  static void debug(String message, {String domain = 'APP'}) {
    if (kDebugMode) {
      debugPrint('[$domain] $message');
    }
  }

  static void info(String message, {String domain = 'APP'}) {
    if (kDebugMode) {
      debugPrint('[$domain] 🔵 $message');
    }
  }

  static void warning(String message, {String domain = 'APP'}) {
    if (kDebugMode) {
      debugPrint('[$domain] 🟠 $message');
    }
  }

  static void error(
    String message, {
    String domain = 'APP',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      debugPrint('[$domain] 🔴 $message');
      if (error != null) {
        debugPrint('[$domain] ERROR: $error');
      }
      if (stackTrace != null) {
        debugPrint('[$domain] STACKTRACE:\n$stackTrace');
      }
    }
  }

  // ==========================================
  // 2. OPERATIONAL TELEMETRY (DEBUG ONLY FOR NOW)
  // ==========================================
  // Despite the name, this currently does NOT survive the release build — like the
  // rest of AppLog, it's gated by kDebugMode below. It's kept as a separate method
  // (rather than folded into info/debug) because it's conceptually a distinct
  // "analytics event" concept, ready to wire into a real SDK later (see TODO below).
  // It is strictly for tracking anonymous events and metadata. NEVER pass user
  // values, balances, or notes here.

  /// Tracks privacy-safe events and metadata.
  /// [eventName] should be a clear action (e.g., 'api_error', 'view_screen').
  /// [metadata] should contain safe context (e.g., duration_ms, status_codes).
  static void insight(String eventName, {Map<String, dynamic>? metadata}) {
    // [EDITED] VERİ SIZINTISI (DATA LEAKAGE) ÖNLENDİ!
    // Artık debugPrint megafonu sadece geliştirme aşamasındayken (kDebugMode) çalışacak.
    // Canlı ortamda (App Store versiyonunda) sistem konsoluna hiçbir şey yazdırılmayacak.
    if (kDebugMode) {
      debugPrint('[TELEMETRY] 📈 EVENT: $eventName | META: $metadata');
    }

    // TODO: Gerçek bir Analytics SDK'sı (Örn: Firebase) kurduğunda, o kodları buraya yazacaksın.
    // Çünkü Firebase kodlarının canlı ortamda çalışmasını İSTİYORUZ.
    // Örnek: Analytics.logEvent(name: eventName, parameters: metadata);
  }
}
