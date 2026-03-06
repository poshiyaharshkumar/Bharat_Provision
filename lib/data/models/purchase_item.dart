class PurchaseItem {
  PurchaseItem({
    this.id,
    required this.purchaseId,
    required this.itemId,
    required this.quantity,
    required this.unitCost,
    required this.lineTotal,
  });

  final int? id;
  final int purchaseId;
  final int itemId;
  final double quantity;
  final double unitCost;
  final double lineTotal;

  factory PurchaseItem.fromMap(Map<String, Object?> map) {
    return PurchaseItem(
      id: map['id'] as int?,
      purchaseId: map['purchase_id'] as int,
      itemId: map['item_id'] as int,
      quantity: (map['quantity'] as num).toDouble(),
      unitCost: (map['unit_cost'] as num).toDouble(),
      lineTotal: (map['line_total'] as num).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'item_id': itemId,
      'quantity': quantity,
      'unit_cost': unitCost,
      'line_total': lineTotal,
    };
  }
}

