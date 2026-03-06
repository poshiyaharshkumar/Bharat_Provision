import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/user.dart';

class UserRepository {
  Future<Database> get _db async => AppDatabase.database;

  Future<List<AppUser>> getAll() async {
    final db = await _db;
    final rows = await db.query(
      'users',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(AppUser.fromMap).toList();
  }

  Future<AppUser?> getOwner() async {
    final db = await _db;
    final rows = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['owner'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<AppUser> insert(AppUser user) async {
    final db = await _db;
    final id = await db.insert('users', user.toMap()..remove('id'));
    return AppUser(
      id: id,
      name: user.name,
      pin: user.pin,
      role: user.role,
      isActive: user.isActive,
    );
  }

  Future<void> update(AppUser user) async {
    final db = await _db;
    await db.update(
      'users',
      user.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
}

