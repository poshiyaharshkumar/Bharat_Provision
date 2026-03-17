import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_helper.dart';
import '../../data/repositories/return_repository.dart';

final returnRepositoryProvider = Provider<ReturnRepository>(
  (ref) => ReturnRepository(DatabaseHelper.instance),
);

final returnSearchQueryProvider = StateProvider<String>((ref) => '');

final returnSelectedBillProvider = StateProvider<int?>((ref) => null);

final returnModeProvider = StateProvider<String>((ref) => 'cash_refund');

final returnSelectedItemsProvider = StateProvider<List<int>>((ref) => []);

final replaceSelectedProductProvider = StateProvider<int?>((ref) => null);

// Add other providers as needed for return flow state.
