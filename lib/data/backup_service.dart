import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'db/app_database.dart';

class BackupService {
  static const _tableOrder = [
    'categories',
    'items',
    'customers',
    'users',
    'settings',
    'bills',
    'bill_items',
    'khata_entries',
    'purchases',
    'purchase_items',
  ];

  /// Exports all tables to a JSON file and returns the file path.
  static Future<String> exportToJson() async {
    final db = await AppDatabase.database;
    final Map<String, List<Map<String, Object?>>> data = {};
    for (final table in _tableOrder) {
      try {
        final rows = await db.query(table);
        data[table] = rows.map((r) => r.map((k, v) => MapEntry(k, v))).toList();
      } catch (_) {
        data[table] = [];
      }
    }
    final jsonStr = jsonEncode(data);
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/bharat_provision_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(path);
    await file.writeAsString(jsonStr);
    return path;
  }

  /// Imports from a JSON file. Replaces existing data. Runs in a transaction.
  static Future<void> importFromJson(String filePath) async {
    final db = await AppDatabase.database;
    final file = File(filePath);
    if (!await file.exists()) throw Exception('ફાઇલ મળી નથી');
    final jsonStr = await file.readAsString();
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    await db.transaction((txn) async {
      for (final table in _tableOrder.reversed) {
        try {
          await txn.delete(table);
        } catch (_) {}
      }
      for (final table in _tableOrder) {
        final list = data[table] as List<dynamic>?;
        if (list == null) continue;
        for (final row in list) {
          final map = row as Map<String, dynamic>;
          final rowMap = map.map((k, v) => MapEntry(k, v as Object?));
          await txn.insert(table, rowMap);
        }
      }
    });
  }
}
