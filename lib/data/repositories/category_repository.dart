import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/category.dart';

class CategoryRepository {
  Future<Database> get _db async => AppDatabase.database;

  Future<List<Category>> getAll() async {
    final db = await _db;
    final rows = await db.query(
      'categories',
      orderBy: 'name_gu COLLATE NOCASE',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<Category> insert(Category category) async {
    final db = await _db;
    final id = await db.insert('categories', category.toMap()..remove('id'));
    return Category(
      id: id,
      nameGu: category.nameGu,
      colorCode: category.colorCode,
    );
  }

  Future<void> update(Category category) async {
    final db = await _db;
    await db.update(
      'categories',
      category.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}

