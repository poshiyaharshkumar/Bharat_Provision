class Customer {
  Customer({
    this.id,
    required this.name,
    this.phone,
    this.address,
    this.note,
  });

  final int? id;
  final String name;
  final String? phone;
  final String? address;
  final String? note;

  factory Customer.fromMap(Map<String, Object?> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      note: map['note'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'note': note,
    };
  }
}

