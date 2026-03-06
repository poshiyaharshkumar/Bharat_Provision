class Bill {
  Bill({
    this.id,
    this.billNumber,
    required this.dateTimeMillis,
    this.customerId,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymentMode,
    this.createdByUserId,
  });

  final int? id;
  final String? billNumber;
  final int dateTimeMillis;
  final int? customerId;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final String paymentMode;
  final int? createdByUserId;

  factory Bill.fromMap(Map<String, Object?> map) {
    return Bill(
      id: map['id'] as int?,
      billNumber: map['bill_number'] as String?,
      dateTimeMillis: map['date_time'] as int,
      customerId: map['customer_id'] as int?,
      subtotal: (map['subtotal'] as num).toDouble(),
      discountAmount: (map['discount_amount'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num).toDouble(),
      paymentMode: map['payment_mode'] as String,
      createdByUserId: map['created_by_user_id'] as int?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'bill_number': billNumber,
      'date_time': dateTimeMillis,
      'customer_id': customerId,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'payment_mode': paymentMode,
      'created_by_user_id': createdByUserId,
    };
  }
}

