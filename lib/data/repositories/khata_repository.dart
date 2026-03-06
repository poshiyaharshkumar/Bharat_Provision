import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/khata_entry.dart';

class KhataRepository {
  Future<Database> get _db async => AppDatabase.database;

  Future<List<KhataEntry>> getEntriesForCustomer(int customerId) async {
    final db = await _db;
    final rows = await db.query(
      'khata_entries',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date_time ASC, id ASC',
    );
    return rows.map(KhataEntry.fromMap).toList();
  }

  Future<double> getCurrentBalance(int customerId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT balance_after
      FROM khata_entries
      WHERE customer_id = ?
      ORDER BY date_time DESC, id DESC
      LIMIT 1
      ''',
      [customerId],
    );
    if (rows.isEmpty) return 0;
    return (rows.first['balance_after'] as num).toDouble();
  }

  Future<KhataEntry> addEntry(KhataEntry entry) async {
    final db = await _db;

    return db.transaction((txn) async {
      final previousRows = await txn.rawQuery(
        '''
        SELECT balance_after
        FROM khata_entries
        WHERE customer_id = ?
        ORDER BY date_time DESC, id DESC
        LIMIT 1
        ''',
        [entry.customerId],
      );

      final previousBalance = previousRows.isEmpty
          ? 0.0
          : (previousRows.first['balance_after'] as num).toDouble();

      final delta = entry.type == 'debit' ? entry.amount : -entry.amount;
      final newBalance = previousBalance + delta;

      final toInsert = entry.copyWith(balanceAfter: newBalance);
      final id = await txn.insert('khata_entries', toInsert.toMap()..remove('id'));

      final insertedRow = await txn.query(
        'khata_entries',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      return KhataEntry.fromMap(insertedRow.first);
    });
  }
}

