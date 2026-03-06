class BillItem {
  BillItem({
    this.id,
    required this.billId,
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final int? id;
  final int billId;
  final int itemId;
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  factory BillItem.fromMap(Map<String, Object?> map) {
    return BillItem(
      id: map['id'] as int?,
      billId: map['bill_id'] as int,
      itemId: map['item_id'] as int,
      quantity: (map['quantity'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      lineTotal: (map['line_total'] as num).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'bill_id': billId,
      'item_id': itemId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'line_total': lineTotal,
    };
  }
}

