import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/customer.dart';

class CustomerRepository {
  Future<Database> get _db async => AppDatabase.database;

  Future<List<Customer>> getAll({String? searchQuery}) async {
    final db = await _db;
    final where = <String>[];
    final args = <Object?>[];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      where.add('name LIKE ?');
      args.add('%$searchQuery%');
    }

    final rows = await db.query(
      'customers',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'name COLLATE NOCASE',
    );

    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer> insert(Customer customer) async {
    final db = await _db;
    final id = await db.insert('customers', customer.toMap()..remove('id'));
    return Customer(
      id: id,
      name: customer.name,
      phone: customer.phone,
      address: customer.address,
      note: customer.note,
    );
  }

  Future<void> update(Customer customer) async {
    final db = await _db;
    await db.update(
      'customers',
      customer.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('khata_entries', where: 'customer_id = ?', whereArgs: [id]);
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
}

