class Purchase {
  Purchase({
    this.id,
    required this.dateTimeMillis,
    this.supplierName,
    required this.totalAmount,
  });

  final int? id;
  final int dateTimeMillis;
  final String? supplierName;
  final double totalAmount;

  factory Purchase.fromMap(Map<String, Object?> map) {
    return Purchase(
      id: map['id'] as int?,
      dateTimeMillis: map['date_time'] as int,
      supplierName: map['supplier_name'] as String?,
      totalAmount: (map['total_amount'] as num).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date_time': dateTimeMillis,
      'supplier_name': supplierName,
      'total_amount': totalAmount,
    };
  }
}

