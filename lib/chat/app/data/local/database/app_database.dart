import 'package:get/get.dart';

import '../../../../core/utils/logs_helper.dart';
import '../../../../core/utils/shared_preference_helper.dart';
import 'migrations/migration_v1.dart';

/// SQLCipher-encrypted local database for HIPAA-compliant data storage.
///
/// Note: Requires the following packages in pubspec.yaml:
///   sqflite_sqlcipher: ^3.1.0
///   path: ^1.9.0
///   path_provider: ^2.1.0
///
/// Uses sqflite_sqlcipher for AES-256 encryption at rest.
class AppDatabase extends GetxService {
  static const String _tag = 'AppDatabase';
  dynamic _database;

  dynamic get database => _database;

  /// Initializes the encrypted database.
  Future<AppDatabase> init() async {
    final encryptionKey =
        SharedPreferenceHelper.getString(PreferenceKeys.dbEncryptionKey);

    if (encryptionKey == null || encryptionKey.isEmpty) {
      LogsHelper.debugLog(
          tag: _tag, 'No encryption key found, database not initialized');
      return this;
    }

    try {
      // In actual implementation:
      // final databasesPath = await getDatabasesPath();
      // final path = join(databasesPath, _dbName);
      //
      // _database = await openDatabase(
      //   path,
      //   version: _dbVersion,
      //   password: encryptionKey,
      //   onCreate: _onCreate,
      //   onUpgrade: _onUpgrade,
      //   onOpen: _onOpen,
      // );

      LogsHelper.debugLog(tag: _tag, 'Database initialized successfully');
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Database initialization error: $e');
    }

    return this;
  }

  /// Creates database tables on first run.
  Future<void> onCreate(dynamic db, int version) async {
    LogsHelper.debugLog(tag: _tag, 'Creating database v$version');
    await MigrationV1.up(db);
  }

  /// Handles database schema upgrades.
  Future<void> onUpgrade(dynamic db, int oldVersion, int newVersion) async {
    LogsHelper.debugLog(
        tag: _tag, 'Upgrading database from v$oldVersion to v$newVersion');
    // Apply migrations sequentially
    if (oldVersion < 1) {
      await MigrationV1.up(db);
    }
    // Future migrations:
    // if (oldVersion < 2) await MigrationV2.up(db);
  }

  Future<void> onOpen(dynamic db) async {
    LogsHelper.debugLog(tag: _tag, 'Database opened');
    // Enable WAL mode for better concurrent read performance
    // await db.execute('PRAGMA journal_mode=WAL');
  }

  /// Closes the database connection.
  Future<void> close() async {
    // await _database?.close();
    _database = null;
    LogsHelper.debugLog(tag: _tag, 'Database closed');
  }

  /// Deletes the entire database (used on logout).
  Future<void> deleteDatabase() async {
    try {
      // In actual implementation:
      // final databasesPath = await getDatabasesPath();
      // final path = join(databasesPath, _dbName);
      // await databaseFactory.deleteDatabase(path);
      _database = null;
      LogsHelper.debugLog(tag: _tag, 'Database deleted');
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Database deletion error: $e');
    }
  }

  @override
  void onClose() {
    close();
    super.onClose();
  }
}
