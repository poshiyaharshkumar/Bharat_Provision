import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/setting.dart';

class SettingsRepository {
  Future<Database> get _db async => AppDatabase.database;

  Future<SettingEntry?> getByKey(String key) async {
    final db = await _db;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SettingEntry.fromMap(rows.first);
  }

  Future<void> setValue(String key, String value) async {
    final db = await _db;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SettingEntry>> getAll() async {
    final db = await _db;
    final rows = await db.query('settings');
    return rows.map(SettingEntry.fromMap).toList();
  }
}

