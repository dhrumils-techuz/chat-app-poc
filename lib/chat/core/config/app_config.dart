import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central application configuration.
///
/// Values are loaded from `assets/.env` at runtime via `flutter_dotenv`.
/// No `build_runner` required — just edit `.env` and restart the app.
///
/// For CI / production builds you can still override any value with
/// `--dart-define`:
///   flutter build web --dart-define=API_URL=https://api.prod.example.com
class AppConfig {
  AppConfig._();

  /// Call once in `main()` before accessing any config value.
  static Future<void> load() async {
    await dotenv.load(fileName: 'assets/.env');
  }

  // ── API / Server ─────────────────────────────────────────────────────

  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_URL');
    if (override.isNotEmpty) return override;
    return "https://lloyd-unhacked-alexandria.ngrok-free.dev";
    // return dotenv.env['API_URL'] ?? 'http://localhost:3000';
  }

  static String get socketUrl {
    const override = String.fromEnvironment('SOCKET_URL');
    if (override.isNotEmpty) return override;
    return dotenv.env['SOCKET_URL'] ?? 'http://localhost:3000';
  }

  // ── AWS S3 ───────────────────────────────────────────────────────────

  static String get s3BucketUrl {
    const override = String.fromEnvironment('S3_BUCKET_URL');
    if (override.isNotEmpty) return override;
    return dotenv.env['S3_BUCKET_URL'] ??
        'https://s3.amazonaws.com/skyconnect-chat-poc';
  }

  // ── Firebase ─────────────────────────────────────────────────────────

  static String get firebaseApiKey {
    const override = String.fromEnvironment('FIREBASE_API_KEY');
    if (override.isNotEmpty) return override;
    return dotenv.env['FIREBASE_API_KEY'] ?? '';
  }

  static String get firebaseProjectId {
    const override = String.fromEnvironment('FIREBASE_PROJECT_ID');
    if (override.isNotEmpty) return override;
    return dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  }

  // ── Encryption ─────────────────────────────────────────────────────

  static String get dbEncryptionKey {
    const override = String.fromEnvironment('DB_ENCRYPTION_KEY');
    if (override.isNotEmpty) return override;
    return dotenv.env['DB_ENCRYPTION_KEY'] ??
        'your-32-char-encryption-key-here';
  }

  // ── Debug Helpers ──────────────────────────────────────────────────

  static bool get isDebug => kDebugMode;
}
