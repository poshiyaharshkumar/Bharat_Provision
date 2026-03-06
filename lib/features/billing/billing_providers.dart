import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/item.dart';
import 'cart_state.dart';

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(Item item, [double quantity = 1]) {
    if (item.id == null) return;
    final existing = state.lines.indexWhere((l) => l.itemId == item.id);
    if (existing >= 0) {
      final line = state.lines[existing];
      updateQuantity(existing, line.quantity + quantity);
      return;
    }
    state = state.copyWith(
      lines: [
        ...state.lines,
        CartLine(
          itemId: item.id!,
          itemName: item.nameGu,
          unitPrice: item.salePrice,
          quantity: quantity,
        ),
      ],
    );
  }

  void updateQuantity(int index, double quantity) {
    if (quantity <= 0) {
      removeAt(index);
      return;
    }
    final updated = state.lines.toList();
    if (index < 0 || index >= updated.length) return;
    updated[index] = updated[index].copyWith(quantity: quantity);
    state = state.copyWith(lines: updated);
  }

  void removeAt(int index) {
    final updated = state.lines.toList();
    if (index < 0 || index >= updated.length) return;
    updated.removeAt(index);
    state = state.copyWith(lines: updated);
  }

  void setDiscount(double amount) {
    state = state.copyWith(discountAmount: amount.clamp(0.0, double.infinity));
  }

  void clear() {
    state = const CartState();
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());
