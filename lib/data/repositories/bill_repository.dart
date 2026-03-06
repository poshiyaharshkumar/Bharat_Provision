import 'package:sqflite/sqflite.dart';

import '../db/app_database.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';

class BillRepository {
  Future<Database> get _db async => AppDatabase.database;

  static const _billNumberKey = 'bill_number_next';

  /// Creates a bill with line items, deducts stock, and optionally records udhar in khata.
  /// All in one transaction.
  Future<Bill> createBillWithStockAndKhata({
    required List<BillItem> billItems,
    required double discountAmount,
    required double paidAmount,
    required String paymentMode,
    int? customerId,
    int? createdByUserId,
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final subtotal =
        billItems.fold(0.0, (sum, i) => sum + i.lineTotal);
    final totalAmount = (subtotal - discountAmount).clamp(0.0, double.infinity);

    return db.transaction((txn) async {
      // 1. Next bill number
      final nextRows = await txn.query(
        'settings',
        where: 'key = ?',
        whereArgs: [_billNumberKey],
        limit: 1,
      );
      int nextNum = 1;
      if (nextRows.isNotEmpty) {
        nextNum = int.tryParse(nextRows.first['value'] as String? ?? '1') ?? 1;
      }
      final billNumber = '$nextNum';
      await txn.insert(
        'settings',
        {'key': _billNumberKey, 'value': '${nextNum + 1}'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Insert bill
      final bill = Bill(
        billNumber: billNumber,
        dateTimeMillis: now,
        customerId: customerId,
        subtotal: subtotal,
        discountAmount: discountAmount,
        taxAmount: 0,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        paymentMode: paymentMode,
        createdByUserId: createdByUserId,
      );
      final billId = await txn.insert('bills', bill.toMap()..remove('id'));

      // 3. Insert bill_items and deduct stock
      for (final item in billItems) {
        await txn.insert(
          'bill_items',
          {
            'bill_id': billId,
            'item_id': item.itemId,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'line_total': item.lineTotal,
          },
        );
        await txn.rawUpdate(
          'UPDATE items SET current_stock = current_stock - ? WHERE id = ?',
          [item.quantity, item.itemId],
        );
      }

      // 4. If customer and partial/unpaid, add khata debit
      final unpaid = totalAmount - paidAmount;
      if (customerId != null && unpaid > 0) {
        final prevRows = await txn.rawQuery(
          '''
          SELECT balance_after FROM khata_entries
          WHERE customer_id = ? ORDER BY date_time DESC, id DESC LIMIT 1
          ''',
          [customerId],
        );
        final prevBalance =
            prevRows.isEmpty ? 0.0 : (prevRows.first['balance_after'] as num).toDouble();
        final balanceAfter = prevBalance + unpaid;
        await txn.insert('khata_entries', {
          'customer_id': customerId,
          'related_bill_id': billId,
          'date_time': now,
          'type': 'debit',
          'amount': unpaid,
          'note': 'બિલ #$billNumber',
          'balance_after': balanceAfter,
        });
      }

      return Bill(
        id: billId,
        billNumber: billNumber,
        dateTimeMillis: now,
        customerId: customerId,
        subtotal: subtotal,
        discountAmount: discountAmount,
        taxAmount: 0,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        paymentMode: paymentMode,
        createdByUserId: createdByUserId,
      );
    });
  }

  Future<Bill> insertBillWithItems(
    Bill bill,
    List<BillItem> items,
  ) async {
    final db = await _db;

    return db.transaction((txn) async {
      final billId = await txn.insert('bills', bill.toMap()..remove('id'));

      for (final item in items) {
        await txn.insert(
          'bill_items',
          item.toMap()
            ..remove('id')
            ..['bill_id'] = billId,
        );
      }

      final insertedRow = await txn.query(
        'bills',
        where: 'id = ?',
        whereArgs: [billId],
        limit: 1,
      );

      return Bill.fromMap(insertedRow.first);
    });
  }

  Future<double> getTotalSalesForDateRange(
    DateTime from,
    DateTime to,
  ) async {
    final db = await _db;
    final fromMillis = from.millisecondsSinceEpoch;
    final toMillis = to.millisecondsSinceEpoch;

    final rows = await db.rawQuery(
      '''
      SELECT SUM(total_amount) as total
      FROM bills
      WHERE date_time BETWEEN ? AND ?
      ''',
      [fromMillis, toMillis],
    );

    final value = rows.first['total'] as num?;
    return value?.toDouble() ?? 0;
  }

  Future<int> getBillCountForDateRange(
    DateTime from,
    DateTime to,
  ) async {
    final db = await _db;
    final fromMillis = from.millisecondsSinceEpoch;
    final toMillis = to.millisecondsSinceEpoch;

    final rows = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM bills
      WHERE date_time BETWEEN ? AND ?
      ''',
      [fromMillis, toMillis],
    );

    final value = rows.first['count'] as int?;
    return value ?? 0;
  }
}

