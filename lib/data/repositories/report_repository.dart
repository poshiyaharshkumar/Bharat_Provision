import 'package:sqflite/sqflite.dart';

import '../models/bill.dart';
import '../models/item.dart';
import '../../shared/models/product_model.dart';

/// Repository powering the reporting/dashboard screens.
///
/// This uses the same database schema as the rest of the application
/// (the `AppDatabase` tables like `bills`, `items`, etc.) and is intended
/// to be used by the dashboard / reports screens.
class ReportRepository {
  ReportRepository(this._db);

  final Database _db;

  /// Returns a summary of sales for a given range, adjusting for returns.
  Future<SalesSummary> getSalesSummary(int startEpoch, int endEpoch) async {
    // Sales from cash/upi/card
    final salesResult = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) as total_sales
      FROM bills
      WHERE date_time >= ? AND date_time <= ?
        AND payment_mode IN ('cash', 'upi', 'card')
      ''',
      [startEpoch, endEpoch],
    );

    // Returns within the same range
    final returnsResult = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_return_value), 0) as total_returns
      FROM returns
      WHERE return_date >= ? AND return_date <= ?
      ''',
      [startEpoch, endEpoch],
    );

    final billCountResult = await _db.rawQuery(
      '''
      SELECT COUNT(*) as bill_count
      FROM bills
      WHERE date_time >= ? AND date_time <= ?
      ''',
      [startEpoch, endEpoch],
    );

    final totalSales =
        (salesResult.first['total_sales'] as num?)?.toDouble() ?? 0;
    final totalReturns =
        (returnsResult.first['total_returns'] as num?)?.toDouble() ?? 0;
    final billCount = (billCountResult.first['bill_count'] as int?) ?? 0;

    return SalesSummary(
      billCount: billCount,
      totalSales: totalSales - totalReturns,
      avgBillValue: billCount > 0 ? (totalSales - totalReturns) / billCount : 0,
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

  Future<double> getTodaysSales() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final startEpoch = start.millisecondsSinceEpoch;
    final endEpoch = end.millisecondsSinceEpoch;

    final result = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_amount), 0) as sales
      FROM bills
      WHERE date_time >= ? AND date_time < ? AND payment_mode IN ('cash', 'upi', 'card')
      ''',
      [startEpoch, endEpoch],
    );
    return (result.first['sales'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTodaysExpenses() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final startEpoch = start.millisecondsSinceEpoch;
    final endEpoch = end.millisecondsSinceEpoch;

    final result = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as expenses
      FROM expenses
      WHERE date >= ? AND date < ?
      ''',
      [startEpoch, endEpoch],
    );
    return (result.first['expenses'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTodaysUdhaarCollected() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final startEpoch = start.millisecondsSinceEpoch;
    final endEpoch = end.millisecondsSinceEpoch;

    final result = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as collected
      FROM udhaar_payments
      WHERE date >= ? AND date < ?
      ''',
      [startEpoch, endEpoch],
    );
    return (result.first['collected'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Product>> getLowStockProducts() async {
    final rows = await _db.query(
      'items',
      where: 'is_active = 1 AND current_stock <= low_stock_threshold',
      orderBy: 'name_gu ASC',
    );
    return rows.map((row) {
      return Product(
        id: row['id'] as int?,
        nameGujarati: row['name_gu'] as String,
        nameEnglish: null,
        transliterationKeys: '',
        categoryId: row['category_id'] as int?,
        unitType: row['unit'] as String? ?? '',
        buyPrice: (row['purchase_price'] as num?)?.toDouble() ?? 0,
        sellPrice: (row['sale_price'] as num?)?.toDouble() ?? 0,
        stockQty: (row['current_stock'] as num?)?.toDouble() ?? 0,
        minStockQty: (row['low_stock_threshold'] as num?)?.toDouble() ?? 0,
        isActive: (row['is_active'] as int? ?? 1) == 1,
        barcode: row['barcode'] as String?,
        createdAt: null,
        updatedAt: null,
      );
    }).toList();
  }

  Future<List<DailySales>> get7DaySales() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 6));
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final startEpoch = startDate.millisecondsSinceEpoch;
    final endEpoch = endDate.millisecondsSinceEpoch;

    final rows = await _db.rawQuery(
      '''
      SELECT date_time, total_amount
      FROM bills
      WHERE date_time >= ? AND date_time < ? AND payment_mode IN ('cash', 'upi', 'card')
      ''',
      [startEpoch, endEpoch],
    );

    final salesMap = <String, double>{};
    for (final row in rows) {
      final epoch = (row['date_time'] as num?)?.toInt() ?? 0;
      final day = DateTime.fromMillisecondsSinceEpoch(epoch);
      final key = DateTime(
        day.year,
        day.month,
        day.day,
      ).toIso8601String().split('T').first;
      salesMap[key] =
          (salesMap[key] ?? 0) + (row['total_amount'] as num?)?.toDouble() ?? 0;
    }

    final out = <DailySales>[];
    for (int i = 0; i < 7; i++) {
      final d = startDate.add(Duration(days: i));
      final key = d.toIso8601String().split('T').first;
      out.add(DailySales(date: d, sales: salesMap[key] ?? 0));
    }
    return out;
  }

  Future<double> getTotalUdhaarOutstanding() async {
    final result = await _db.rawQuery('''
      SELECT COALESCE(SUM(balance_after), 0) as total
      FROM (
        SELECT customer_id, balance_after
        FROM khata_entries
        WHERE (customer_id, date_time, id) IN (
          SELECT customer_id, MAX(date_time), MAX(id)
          FROM khata_entries
          GROUP BY customer_id
        )
      )
      WHERE balance_after > 0
      ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTodaysNetProfit() async {
    final sales = await getTodaysSales();
    final expenses = await getTodaysExpenses();
    final collected = await getTodaysUdhaarCollected();

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final startEpoch = start.millisecondsSinceEpoch;
    final endEpoch = end.millisecondsSinceEpoch;

    final returnsResult = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_return_value), 0) as returns
      FROM returns
      WHERE return_date >= ? AND return_date < ?
      ''',
      [startEpoch, endEpoch],
    );
    final returns = (returnsResult.first['returns'] as num?)?.toDouble() ?? 0;

    return sales + collected - expenses - returns;
  }

  Future<int> getTodaysBillCount() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final startEpoch = start.millisecondsSinceEpoch;
    final endEpoch = end.millisecondsSinceEpoch;

    final result = await _db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM bills
      WHERE date_time >= ? AND date_time < ?
      ''',
      [startEpoch, endEpoch],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<PLSummary> getPLSummary(int startEpoch, int endEpoch) async {
    // Sales by mode
    final salesResult = await _db.rawQuery(
      '''
      SELECT payment_mode, SUM(total_amount) as amount
      FROM bills
      WHERE date_time >= ? AND date_time <= ? AND payment_mode IN ('cash', 'upi', 'card')
      GROUP BY payment_mode
      ''',
      [startEpoch, endEpoch],
    );

    final salesByMode = <String, double>{};
    for (final row in salesResult) {
      salesByMode[row['payment_mode'] as String] =
          (row['amount'] as num?)?.toDouble() ?? 0;
    }

    // Udhaar collected
    final udhaarResult = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as collected
      FROM udhaar_payments
      WHERE date >= ? AND date <= ?
      ''',
      [startEpoch, endEpoch],
    );
    final udhaarCollected =
        (udhaarResult.first['collected'] as num?)?.toDouble() ?? 0;

    // Expenses by account
    final expensesResult = await _db.rawQuery(
      '''
      SELECT ea.name, SUM(e.amount) as amount
      FROM expenses e
      JOIN expense_accounts ea ON e.expense_account_id = ea.id
      WHERE e.date >= ? AND e.date <= ?
      GROUP BY ea.name
      ''',
      [startEpoch, endEpoch],
    );
    final expensesByAccount = <String, double>{};
    for (final row in expensesResult) {
      expensesByAccount[row['name'] as String] =
          (row['amount'] as num?)?.toDouble() ?? 0;
    }

    // Returns
    final returnsResult = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(total_return_value), 0) as returns
      FROM returns
      WHERE return_date >= ? AND return_date <= ?
      ''',
      [startEpoch, endEpoch],
    );
    final returns = (returnsResult.first['returns'] as num?)?.toDouble() ?? 0;

    final totalSales =
        salesByMode.values.fold(0.0, (a, b) => a + b) + udhaarCollected;
    final totalExpenses = expensesByAccount.values.fold(0.0, (a, b) => a + b);
    final netProfit = totalSales - totalExpenses - returns;

    return PLSummary(
      salesByMode: salesByMode,
      udhaarCollected: udhaarCollected,
      expensesByAccount: expensesByAccount,
      returns: returns,
      totalSales: totalSales,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
    );
  }

  Future<List<DailyPL>> getDailyPL(int startEpoch, int endEpoch) async {
    final salesByDay = <String, double>{};
    final udhaarByDay = <String, double>{};
    final expensesByDay = <String, double>{};
    final returnsByDay = <String, double>{};

    final salesRows = await _db.rawQuery(
      '''
      SELECT date_time, total_amount, payment_mode
      FROM bills
      WHERE date_time >= ? AND date_time < ?
      ''',
      [startEpoch, endEpoch],
    );
    for (final row in salesRows) {
      final epoch = (row['date_time'] as num?)?.toInt() ?? 0;
      final day = DateTime.fromMillisecondsSinceEpoch(epoch);
      final key = DateTime(
        day.year,
        day.month,
        day.day,
      ).toIso8601String().split('T').first;
      final amount = (row['total_amount'] as num?)?.toDouble() ?? 0;
      final mode = row['payment_mode'] as String? ?? '';
      if (mode == 'cash' || mode == 'upi' || mode == 'card') {
        salesByDay[key] = (salesByDay[key] ?? 0) + amount;
      }
    }

    final udhaarRows = await _db.rawQuery(
      '''
      SELECT date, amount
      FROM udhaar_payments
      WHERE date >= ? AND date < ?
      ''',
      [startEpoch, endEpoch],
    );
    for (final row in udhaarRows) {
      final epoch = (row['date'] as num?)?.toInt() ?? 0;
      final day = DateTime.fromMillisecondsSinceEpoch(epoch);
      final key = DateTime(
        day.year,
        day.month,
        day.day,
      ).toIso8601String().split('T').first;
      udhaarByDay[key] =
          (udhaarByDay[key] ?? 0) + ((row['amount'] as num?)?.toDouble() ?? 0);
    }

    final expensesRows = await _db.rawQuery(
      '''
      SELECT date, amount
      FROM expenses
      WHERE date >= ? AND date < ?
      ''',
      [startEpoch, endEpoch],
    );
    for (final row in expensesRows) {
      final epoch = (row['date'] as num?)?.toInt() ?? 0;
      final day = DateTime.fromMillisecondsSinceEpoch(epoch);
      final key = DateTime(
        day.year,
        day.month,
        day.day,
      ).toIso8601String().split('T').first;
      expensesByDay[key] =
          (expensesByDay[key] ?? 0) +
          ((row['amount'] as num?)?.toDouble() ?? 0);
    }

    final returnsRows = await _db.rawQuery(
      '''
      SELECT return_date, total_return_value
      FROM returns
      WHERE return_date >= ? AND return_date < ?
      ''',
      [startEpoch, endEpoch],
    );
    for (final row in returnsRows) {
      final epoch = (row['return_date'] as num?)?.toInt() ?? 0;
      final day = DateTime.fromMillisecondsSinceEpoch(epoch);
      final key = DateTime(
        day.year,
        day.month,
        day.day,
      ).toIso8601String().split('T').first;
      returnsByDay[key] =
          (returnsByDay[key] ?? 0) +
          ((row['total_return_value'] as num?)?.toDouble() ?? 0);
    }

    final out = <DailyPL>[];
    final startDate = DateTime.fromMillisecondsSinceEpoch(startEpoch);
    final endDate = DateTime.fromMillisecondsSinceEpoch(endEpoch);
    final days = endDate.difference(startDate).inDays;

    for (int i = 0; i < days; i++) {
      final day = startDate.add(Duration(days: i));
      final key = DateTime(
        day.year,
        day.month,
        day.day,
      ).toIso8601String().split('T').first;
      final sales = salesByDay[key] ?? 0;
      final udhaar = udhaarByDay[key] ?? 0;
      final expenses = expensesByDay[key] ?? 0;
      final returns = returnsByDay[key] ?? 0;
      final net = sales + udhaar - expenses - returns;
      out.add(DailyPL(date: day, netProfit: net));
    }

    return out;
  }

  Future<DailyReportData> getDailyReport(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final startEpoch = start.millisecondsSinceEpoch;
    final endEpoch = end.millisecondsSinceEpoch;

    final billsResult = await _db.query(
      'bills',
      where: 'date_time >= ? AND date_time < ?',
      whereArgs: [startEpoch, endEpoch],
      orderBy: 'date_time DESC',
    );
    final bills = billsResult.map((row) => Bill.fromMap(row)).toList();

    final billCount = bills.length;

    final salesByMode = <String, double>{};
    for (final bill in bills) {
      final mode = bill.paymentMode;
      if (mode != null && mode != 'udhaar') {
        salesByMode[mode] = (salesByMode[mode] ?? 0) + bill.totalAmount;
      }
    }

    final udhaarGiven = bills
        .where((b) => b.paymentMode == 'udhaar')
        .fold(0.0, (sum, b) => sum + b.totalAmount);

    final udhaarResult = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) as collected
      FROM udhaar_payments
      WHERE date >= ? AND date < ?
      ''',
      [startEpoch, endEpoch],
    );
    final udhaarCollected =
        (udhaarResult.first['collected'] as num?)?.toDouble() ?? 0;

    final expensesResult = await _db.rawQuery(
      '''
      SELECT ea.name, SUM(e.amount) as amount
      FROM expenses e
      JOIN expense_accounts ea ON e.expense_account_id = ea.id
      WHERE e.date >= ? AND e.date < ?
      GROUP BY ea.name
      ''',
      [startEpoch, endEpoch],
    );

    final expensesByCategory = <String, double>{};
    for (final row in expensesResult) {
      expensesByCategory[row['name'] as String] =
          (row['amount'] as num?)?.toDouble() ?? 0;
    }

    final totalSales = salesByMode.values.fold(0.0, (a, b) => a + b);
    final totalExpenses = expensesByCategory.values.fold(0.0, (a, b) => a + b);
    final netPL = totalSales + udhaarCollected - totalExpenses;

    return DailyReportData(
      billCount: billCount,
      totalSales: totalSales,
      salesByMode: salesByMode,
      udhaarGiven: udhaarGiven,
      udhaarCollected: udhaarCollected,
      expensesByCategory: expensesByCategory,
      totalExpenses: totalExpenses,
      netPL: netPL,
      bills: bills,
    );
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

class DailySales {
  DailySales({required this.date, required this.sales});
  final DateTime date;
  final double sales;
}

class PLSummary {
  PLSummary({
    required this.salesByMode,
    required this.udhaarCollected,
    required this.expensesByAccount,
    required this.returns,
    required this.totalSales,
    required this.totalExpenses,
    required this.netProfit,
  });
  final Map<String, double> salesByMode;
  final double udhaarCollected;
  final Map<String, double> expensesByAccount;
  final double returns;
  final double totalSales;
  final double totalExpenses;
  final double netProfit;
}

class DailyPL {
  DailyPL({required this.date, required this.netProfit});
  final DateTime date;
  final double netProfit;
}

class DailyReportData {
  DailyReportData({
    required this.billCount,
    required this.totalSales,
    required this.salesByMode,
    required this.udhaarGiven,
    required this.udhaarCollected,
    required this.expensesByCategory,
    required this.totalExpenses,
    required this.netPL,
    required this.bills,
  });
  final int billCount;
  final double totalSales;
  final Map<String, double> salesByMode;
  final double udhaarGiven;
  final double udhaarCollected;
  final Map<String, double> expensesByCategory;
  final double totalExpenses;
  final double netPL;
  final List<Bill> bills;
}
