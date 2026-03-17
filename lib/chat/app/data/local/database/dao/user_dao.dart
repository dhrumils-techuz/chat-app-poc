import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../../../core/utils/logs_helper.dart';
import '../../../model/user_model.dart';
import '../../../types/user_presence.dart';
import '../app_database.dart';

/// Data Access Object for user-related database operations.
class UserDao {
  static const String _tag = 'UserDao';
  static const String _table = 'users';
  final AppDatabase _appDatabase;

  UserDao(this._appDatabase);

  /// Inserts or updates a user.
  Future<void> upsertUser(UserModel user) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      final map = _userToMap(user);
      await db.insert(_table, map, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Upsert user error: $e');
    }
  }

  /// Inserts or updates multiple users in a batch.
  Future<void> upsertUsers(List<UserModel> users) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final user in users) {
          batch.insert(_table, _userToMap(user),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Batch upsert users error: $e');
    }
  }

  /// Gets a user by ID.
  Future<UserModel?> getUserById(String userId) async {
    final db = _appDatabase.database;
    if (db == null) return null;

    try {
      final maps = await db.query(
        _table,
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (maps.isNotEmpty) return _mapToUser(maps.first);
      return null;
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Get user by id error: $e');
      return null;
    }
  }

  /// Gets all users.
  Future<List<UserModel>> getAllUsers() async {
    final db = _appDatabase.database;
    if (db == null) return [];

    try {
      final maps = await db.query(_table, orderBy: 'name ASC');
      return maps.map((map) => _mapToUser(map)).toList();
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Get all users error: $e');
      return [];
    }
  }

  /// Searches users by name or email.
  Future<List<UserModel>> searchUsers(String query) async {
    final db = _appDatabase.database;
    if (db == null) return [];

    try {
      final maps = await db.query(
        _table,
        where: 'name LIKE ? OR email LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'name ASC',
      );
      return maps.map((map) => _mapToUser(map)).toList();
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Search users error: $e');
      return [];
    }
  }

  /// Updates user presence status.
  Future<void> updatePresence(String userId, UserPresence presence) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      final updates = <String, dynamic>{
        'presence': presence.value,
      };
      if (presence == UserPresence.offline) {
        updates['last_seen_at'] = DateTime.now().toIso8601String();
      }
      await db.update(_table, updates, where: 'id = ?', whereArgs: [userId]);
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Update presence error: $e');
    }
  }

  /// Deletes a user.
  Future<void> deleteUser(String userId) async {
    final db = _appDatabase.database;
    if (db == null) return;

    try {
      await db.delete(_table, where: 'id = ?', whereArgs: [userId]);
    } catch (e) {
      LogsHelper.debugLog(tag: _tag, 'Delete user error: $e');
    }
  }

  Map<String, dynamic> _userToMap(UserModel user) {
    return {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'phone_number': user.phoneNumber,
      'avatar_url': user.avatarUrl,
      'designation': user.designation,
      'department': user.department,
      'presence': user.presence.value,
      'last_seen_at': user.lastSeenAt?.toIso8601String(),
      'created_at': user.createdAt?.toIso8601String(),
      'updated_at': user.updatedAt?.toIso8601String(),
    };
  }

  UserModel _mapToUser(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phoneNumber: map['phone_number'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      designation: map['designation'] as String?,
      department: map['department'] as String?,
      presence: UserPresence.fromValue(map['presence'] as String? ?? 'offline'),
      lastSeenAt: map['last_seen_at'] != null
          ? DateTime.parse(map['last_seen_at'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
