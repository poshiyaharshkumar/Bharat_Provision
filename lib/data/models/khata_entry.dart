class KhataEntry {
  KhataEntry({
    this.id,
    required this.customerId,
    this.relatedBillId,
    required this.dateTimeMillis,
    required this.type,
    required this.amount,
    this.note,
    required this.balanceAfter,
  });

  final int? id;
  final int customerId;
  final int? relatedBillId;
  final int dateTimeMillis;
  final String type; // 'debit' or 'credit'
  final double amount;
  final String? note;
  final double balanceAfter;

  KhataEntry copyWith({
    int? id,
    int? customerId,
    int? relatedBillId,
    int? dateTimeMillis,
    String? type,
    double? amount,
    String? note,
    double? balanceAfter,
  }) {
    return KhataEntry(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      relatedBillId: relatedBillId ?? this.relatedBillId,
      dateTimeMillis: dateTimeMillis ?? this.dateTimeMillis,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      balanceAfter: balanceAfter ?? this.balanceAfter,
    );
  }

  factory KhataEntry.fromMap(Map<String, Object?> map) {
    return KhataEntry(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      relatedBillId: map['related_bill_id'] as int?,
      dateTimeMillis: map['date_time'] as int,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      balanceAfter: (map['balance_after'] as num).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'related_bill_id': relatedBillId,
      'date_time': dateTimeMillis,
      'type': type,
      'amount': amount,
      'note': note,
      'balance_after': balanceAfter,
    };
  }
}

