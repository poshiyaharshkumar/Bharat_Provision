import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_handler.dart';
import '../../data/models/item.dart';
import '../../data/providers.dart';

// Billing search provider
final billingSearchProvider = StateProvider<String>((ref) => '');

// Items provider for billing - fetches from the same items table as inventory
final billingItemsProvider = FutureProvider<List<Item>>((ref) async {
  try {
    final repo = await ref.watch(itemRepositoryFutureProvider.future);
    final query = ref.watch(billingSearchProvider);

    if (query.isEmpty) {
      return repo.getAll();
    }

    return repo.search(query, lowStockOnly: false);
  } catch (e, st) {
    throw ErrorHandler.handle(
      e,
      st,
      context: 'BillingProviders.billingItemsProvider',
    );
  }
});

/// Single line in a bill draft.
class BillLine {
  BillLine({required this.item, required this.qtyGrams, required this.amount});

  final Item item;

  /// Stored in grams for weight-based units, or as "units" for count / litre.
  final double qtyGrams;

  /// Final line amount in ₹.
  final double amount;
}

/// Per-tab draft state – corresponds to one bill tab.
class BillDraft {
  BillDraft({
    this.lines = const [],
    this.discountAmount = 0,
    this.customerId,
    this.customerName,
  });

  final List<BillLine> lines;
  final double discountAmount;
  final int? customerId;
  final String? customerName;

  double get subtotal => lines.fold(0, (s, l) => s + l.amount);
  double get total => subtotal - discountAmount;

  BillDraft copyWith({
    List<BillLine>? lines,
    double? discountAmount,
    int? customerId,
    String? customerName,
  }) {
    return BillDraft(
      lines: lines ?? this.lines,
      discountAmount: discountAmount ?? this.discountAmount,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
    );
  }

  bool get isEmpty =>
      lines.isEmpty && discountAmount == 0 && customerId == null;
}

/// Overall billing tabs state – holds five independent drafts.
class BillingTabsState {
  BillingTabsState({required this.activeIndex, required this.drafts})
    : assert(drafts.length == 5, 'Must always maintain 5 bill drafts');

  final int activeIndex;
  final List<BillDraft> drafts;

  BillDraft get activeDraft => drafts[activeIndex];

  BillingTabsState copyWith({int? activeIndex, List<BillDraft>? drafts}) {
    return BillingTabsState(
      activeIndex: activeIndex ?? this.activeIndex,
      drafts: drafts ?? this.drafts,
    );
  }
}

class BillingTabsNotifier extends StateNotifier<BillingTabsState> {
  BillingTabsNotifier()
    : super(
        BillingTabsState(
          activeIndex: 0,
          drafts: List<BillDraft>.generate(5, (_) => BillDraft()),
        ),
      );

  void switchToTab(int index) {
    if (index < 0 || index >= state.drafts.length) return;
    state = state.copyWith(activeIndex: index);
  }

  void addLineToActive(BillLine line) {
    final drafts = [...state.drafts];
    final current = drafts[state.activeIndex];
    drafts[state.activeIndex] = current.copyWith(
      lines: [...current.lines, line],
    );
    state = state.copyWith(drafts: drafts);
  }

  void updateLineInActive(int index, BillLine updatedLine) {
    final drafts = [...state.drafts];
    final current = drafts[state.activeIndex];
    if (index < 0 || index >= current.lines.length) return;
    final newLines = [...current.lines]..[index] = updatedLine;
    drafts[state.activeIndex] = current.copyWith(lines: newLines);
    state = state.copyWith(drafts: drafts);
  }

  void removeLineFromActive(int index) {
    final drafts = [...state.drafts];
    final current = drafts[state.activeIndex];
    if (index < 0 || index >= current.lines.length) return;
    final newLines = [...current.lines]..removeAt(index);
    drafts[state.activeIndex] = current.copyWith(lines: newLines);
    state = state.copyWith(drafts: drafts);
  }

  void setDiscountForActive(double amount) {
    final drafts = [...state.drafts];
    final current = drafts[state.activeIndex];
    drafts[state.activeIndex] = current.copyWith(discountAmount: amount);
    state = state.copyWith(drafts: drafts);
  }

  void setCustomerForActive({
    required int? customerId,
    required String? customerName,
  }) {
    final drafts = [...state.drafts];
    final current = drafts[state.activeIndex];
    drafts[state.activeIndex] = current.copyWith(
      customerId: customerId,
      customerName: customerName,
    );
    state = state.copyWith(drafts: drafts);
  }

  /// Clears only the currently active tab draft.
  void clearActive() {
    final drafts = [...state.drafts];
    drafts[state.activeIndex] = BillDraft();
    state = state.copyWith(drafts: drafts);
  }

  /// Clears a specific tab (used by "close tab" behaviour).
  void clearTab(int index) {
    if (index < 0 || index >= state.drafts.length) return;
    final drafts = [...state.drafts];
    drafts[index] = BillDraft();
    state = state.copyWith(drafts: drafts);
  }
}

/// Riverpod provider exposing the billing tabs state.
final billingTabsProvider =
    StateNotifierProvider<BillingTabsNotifier, BillingTabsState>((ref) {
      return BillingTabsNotifier();
    });

// Provider for shop details needed for bill display
final shopDetailsForBillingProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  try {
    final repo = await ref.watch(settingsRepositoryFutureProvider.future);
    return {
      'shop_name': await repo.get('shop_name'),
      'shop_address': await repo.get('shop_address'),
      'shop_phone': await repo.get('shop_phone'),
      'gstin': await repo.get('gstin'),
      'bill_footer': await repo.get('bill_footer'),
    };
  } catch (e, st) {
    throw ErrorHandler.handle(
      e,
      st,
      context: 'BillingProviders.shopDetailsForBillingProvider',
    );
  }
});
