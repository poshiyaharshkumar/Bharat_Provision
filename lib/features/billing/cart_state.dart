/// A single line in the billing cart.
class CartLine {
  const CartLine({
    required this.itemId,
    required this.itemName,
    required this.unitPrice,
    required this.quantity,
  });

  final int itemId;
  final String itemName;
  final double unitPrice;
  final double quantity;

  double get lineTotal => unitPrice * quantity;

  CartLine copyWith({
    int? itemId,
    String? itemName,
    double? unitPrice,
    double? quantity,
  }) {
    return CartLine(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Full cart state for billing screen.
class CartState {
  const CartState({
    this.lines = const [],
    this.discountAmount = 0,
  });

  final List<CartLine> lines;
  final double discountAmount;

  double get subtotal =>
      lines.fold(0.0, (sum, line) => sum + line.lineTotal);

  double get totalAmount => (subtotal - discountAmount).clamp(0.0, double.infinity);

  CartState copyWith({
    List<CartLine>? lines,
    double? discountAmount,
  }) {
    return CartState(
      lines: lines ?? this.lines,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }
}
