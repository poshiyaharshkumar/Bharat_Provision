import 'package:sqflite/sqflite.dart';

class ReportRepository {
  ReportRepository(this._db);

  final Database _db;

  Future<SalesSummary> getSalesSummary(int startEpoch, int endEpoch) async {
    // Returns should reduce the sales total on the day of return (not original bill date).
    final startIso = DateTime.fromMillisecondsSinceEpoch(
      startEpoch,
    ).toIso8601String();
    final endIso = DateTime.fromMillisecondsSinceEpoch(
      endEpoch,
    ).toIso8601String();

    final result = await _db.rawQuery(
      '''
      SELECT
        COUNT(*) as bill_count,
        COALESCE(SUM(total_amount), 0)
          - COALESCE((
              SELECT SUM(total_return_value) FROM returns
              WHERE return_date >= ? AND return_date <= ?
            ), 0) as total_sales,
        COALESCE(AVG(total_amount), 0) as avg_bill
      FROM bills
      WHERE date_time >= ? AND date_time <= ?
      ''',
      [startIso, endIso, startEpoch, endEpoch],
    );
    final row = result.first;
    return SalesSummary(
      billCount: row['bill_count'] as int? ?? 0,
      totalSales: (row['total_sales'] as num?)?.toDouble() ?? 0,
      avgBillValue: (row['avg_bill'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<List<OutstandingCustomer>> getOutstandingKhata() async {
    final customers = await _db.query('customers');
    final entries = await _db.query(
      'khata_entries',
      orderBy: 'customer_id ASC, date_time DESC, id DESC',
    );
    final latestBalance = <int, double>{};
    for (final row in entries) {
      final cid = row['customer_id'] as int;
      if (!latestBalance.containsKey(cid)) {
        latestBalance[cid] = (row['balance_after'] as num?)?.toDouble() ?? 0;
      }
    }
    final out = <OutstandingCustomer>[];
    for (final c in customers) {
      final id = c['id'] as int;
      final balance = latestBalance[id] ?? 0;
      if (balance > 0) {
        out.add(
          OutstandingCustomer(
            id: id,
            name: c['name'] as String,
            balance: balance,
          ),
        );
      }
    }
    out.sort((a, b) => b.balance.compareTo(a.balance));
    return out;
  }
}

class SalesSummary {
  SalesSummary({
    required this.billCount,
    required this.totalSales,
    required this.avgBillValue,
  });
  final int billCount;
  final double totalSales;
  final double avgBillValue;
}

class OutstandingCustomer {
  OutstandingCustomer({
    required this.id,
    required this.name,
    required this.balance,
  });
  final int id;
  final String name;
  final double balance;
}
