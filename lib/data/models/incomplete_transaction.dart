/// Model for tracking incomplete transactions
class IncompleteTransaction {
  final int id;
  final String?
  transactionType; // 'bill_save', 'stock_purchase', 'return', 'expense'
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool recovered;

  IncompleteTransaction({
    required this.id,
    this.transactionType,
    required this.data,
    required this.createdAt,
    this.updatedAt,
    this.recovered = false,
  });

  factory IncompleteTransaction.fromMap(Map<String, dynamic> map) {
    return IncompleteTransaction(
      id: map['id'] as int,
      transactionType: map['transaction_type'] as String?,
      data: map['data'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : null,
      recovered: (map['recovered'] as int?) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_type': transactionType,
      'data': data,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
      'recovered': recovered ? 1 : 0,
    };
  }

  String get description {
    switch (transactionType) {
      case 'bill_save':
        return 'બીલ સેવ - બીલ નંબર: ${data['billNumber']}';
      case 'stock_purchase':
        return 'સ્ટોક ખરીદી - આઇટમ ID: ${data['itemId']}';
      case 'return':
        return 'રીટર્ન - બીલ ID: ${data['billId']}';
      case 'expense':
        return 'ખર્ચ - રકમ: ₹${data['amount']}';
      default:
        return 'અધૂરી ક્રિયા';
    }
  }
}

/// Recovery action result
class RecoveryResult {
  final bool success;
  final String? errorMessage;
  final List<String> recoveredTransactions;
  final List<String> failedTransactions;

  RecoveryResult({
    required this.success,
    this.errorMessage,
    this.recoveredTransactions = const [],
    this.failedTransactions = const [],
  });
}
