import 'dart:math';

import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../../core/utils/logs_helper.dart';
import '../../../../core/utils/shared_preference_helper.dart';
import 'migrations/migration_v1.dart';

/// SQLCipher-encrypted local database for HIPAA-compliant data storage.
///
/// Uses sqflite_sqlcipher for AES-256 encryption at rest.
class AppDatabase extends GetxService {
  static const String _tag = 'AppDatabase';
  static const String _dbName = 'chat_app.db';
  static const int _dbVersion = 1;

  Database? _database;

  Database? get database => _database;

  /// Initializes the encrypted database.
  Future<AppDatabase> init() async {
    var encryptionKey =
        SharedPreferenceHelper.getString(PreferenceKeys.dbEncryptionKey);

    if (encryptionKey == null || encryptionKey.isEmpty) {
      encryptionKey = _generateEncryptionKey();
      await SharedPreferenceHelper.setString(
          PreferenceKeys.dbEncryptionKey, encryptionKey);
      LogsHelper.debugLog(
          tag: _tag, 'Generated and saved new database encryption key');
    }

    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _dbName);

      _database = await openDatabase(
        path,
        version: _dbVersion,
        password: encryptionKey,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      );

      LogsHelper.debugLog(tag: _tag, 'Database initialized successfully');
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Database initialization error: $e');
    }

    return this;
  }

  /// Generates a random 32-character hex encryption key.
  String _generateEncryptionKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Creates database tables on first run.
  Future<void> _onCreate(Database db, int version) async {
    LogsHelper.debugLog(tag: _tag, 'Creating database v$version');
    await MigrationV1.up(db);
  }

  /// Handles database schema upgrades.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    LogsHelper.debugLog(
        tag: _tag, 'Upgrading database from v$oldVersion to v$newVersion');
    // Apply migrations sequentially
    if (oldVersion < 1) {
      await MigrationV1.up(db);
    }
    // Future migrations:
    // if (oldVersion < 2) await MigrationV2.up(db);
  }

  Future<void> _onOpen(Database db) async {
    LogsHelper.debugLog(tag: _tag, 'Database opened');
    // Enable WAL mode for better concurrent read performance
    await db.execute('PRAGMA journal_mode=WAL');
  }

  /// Closes the database connection.
  Future<void> close() async {
    await _database?.close();
    _database = null;
    LogsHelper.debugLog(tag: _tag, 'Database closed');
  }

  /// Deletes the entire database (used on logout).
  Future<void> deleteDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _dbName);
      await databaseFactory.deleteDatabase(path);
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
