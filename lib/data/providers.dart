import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/large_text_notifier.dart';
import 'db/app_database.dart';
import 'models/customer.dart';
import 'models/item.dart';
import 'models/khata_entry.dart';
import 'repositories/bill_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/customer_repository.dart';
import 'repositories/item_repository.dart';
import 'repositories/khata_repository.dart';
import 'repositories/settings_repository.dart';
import 'repositories/user_repository.dart';

final largeTextProvider =
    StateNotifierProvider<LargeTextNotifier, bool>((ref) {
  return LargeTextNotifier(ref.read(settingsRepositoryProvider));
});

final databaseProvider = FutureProvider((ref) async {
  return AppDatabase.database;
});

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

final billRepositoryProvider = Provider<BillRepository>((ref) {
  return BillRepository();
});

final khataRepositoryProvider = Provider<KhataRepository>((ref) {
  return KhataRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final itemsListProvider =
    FutureProvider.autoDispose.family<List<Item>, String?>((ref, search) async {
  final repo = ref.read(itemRepositoryProvider);
  return repo.getAll(searchQuery: search, lowStockOnly: false);
});

/// List of customers with their current khata balance.
final customersWithBalanceProvider =
    FutureProvider.autoDispose<List<({Customer customer, double balance})>>(
  (ref) async {
    final customerRepo = ref.read(customerRepositoryProvider);
    final khataRepo = ref.read(khataRepositoryProvider);
    final customers = await customerRepo.getAll();
    final result = <({Customer customer, double balance})>[];
    for (final c in customers) {
      if (c.id == null) continue;
      final balance = await khataRepo.getCurrentBalance(c.id!);
      result.add((customer: c, balance: balance));
    }
    return result;
  },
);

final customerBalanceProvider =
    FutureProvider.autoDispose.family<double, int>((ref, customerId) async {
  final repo = ref.read(khataRepositoryProvider);
  return repo.getCurrentBalance(customerId);
});

final customerEntriesProvider =
    FutureProvider.autoDispose.family<List<KhataEntry>, int>(
  (ref, customerId) async {
    final repo = ref.read(khataRepositoryProvider);
    return repo.getEntriesForCustomer(customerId);
  },
);

/// Report summary: (totalSales, billCount) for a date range key: today, week, month.
final reportSummaryProvider =
    FutureProvider.autoDispose.family<({double total, int count}), String>(
  (ref, key) async {
    final repo = ref.read(billRepositoryProvider);
    final now = DateTime.now();
    DateTime start;
    if (key == 'today') {
      start = DateTime(now.year, now.month, now.day);
    } else if (key == 'week') {
      final weekday = now.weekday;
      start = DateTime(now.year, now.month, now.day - (weekday - 1));
    } else {
      start = DateTime(now.year, now.month, 1);
    }
    final end = now;
    final total = await repo.getTotalSalesForDateRange(start, end);
    final count = await repo.getBillCountForDateRange(start, end);
    return (total: total, count: count);
  },
);

