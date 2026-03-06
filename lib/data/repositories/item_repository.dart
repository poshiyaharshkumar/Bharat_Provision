import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/item.dart';

class ItemRepository {
  Future<Database> get _db async => AppDatabase.database;

  Future<List<Item>> getAll({String? searchQuery, bool? lowStockOnly}) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      where.add('name_gu LIKE ?');
      args.add('%$searchQuery%');
    }

    if (lowStockOnly == true) {
      where.add('current_stock <= low_stock_threshold');
    }

    final rows = await db.query(
      'items',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'name_gu COLLATE NOCASE',
    );

    return rows.map(Item.fromMap).toList();
  }

  Future<Item> insert(Item item) async {
    final db = await _db;
    final id = await db.insert('items', item.toMap()..remove('id'));
    return item.copyWith(id: id);
  }

  Future<void> update(Item item) async {
    final db = await _db;
    await db.update(
      'items',
      item.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('items', where: 'id = ?', whereArgs: [id]);
  }
}

