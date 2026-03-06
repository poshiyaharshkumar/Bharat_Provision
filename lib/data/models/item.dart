class Item {
  Item({
    this.id,
    required this.nameGu,
    this.categoryId,
    this.barcode,
    this.unit,
    required this.salePrice,
    this.purchasePrice,
    this.currentStock = 0,
    this.lowStockThreshold = 0,
    this.isActive = true,
  });

  final int? id;
  final String nameGu;
  final int? categoryId;
  final String? barcode;
  final String? unit;
  final double salePrice;
  final double? purchasePrice;
  final double currentStock;
  final double lowStockThreshold;
  final bool isActive;

  bool get isLowStock => currentStock <= lowStockThreshold;

  Item copyWith({
    int? id,
    String? nameGu,
    int? categoryId,
    String? barcode,
    String? unit,
    double? salePrice,
    double? purchasePrice,
    double? currentStock,
    double? lowStockThreshold,
    bool? isActive,
  }) {
    return Item(
      id: id ?? this.id,
      nameGu: nameGu ?? this.nameGu,
      categoryId: categoryId ?? this.categoryId,
      barcode: barcode ?? this.barcode,
      unit: unit ?? this.unit,
      salePrice: salePrice ?? this.salePrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentStock: currentStock ?? this.currentStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      isActive: isActive ?? this.isActive,
    );
  }

  factory Item.fromMap(Map<String, Object?> map) {
    return Item(
      id: map['id'] as int?,
      nameGu: map['name_gu'] as String,
      categoryId: map['category_id'] as int?,
      barcode: map['barcode'] as String?,
      unit: map['unit'] as String?,
      salePrice: (map['sale_price'] as num).toDouble(),
      purchasePrice:
          map['purchase_price'] != null ? (map['purchase_price'] as num).toDouble() : null,
      currentStock: (map['current_stock'] as num).toDouble(),
      lowStockThreshold: (map['low_stock_threshold'] as num).toDouble(),
      isActive: (map['is_active'] as int) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name_gu': nameGu,
      'category_id': categoryId,
      'barcode': barcode,
      'unit': unit,
      'sale_price': salePrice,
      'purchase_price': purchasePrice,
      'current_stock': currentStock,
      'low_stock_threshold': lowStockThreshold,
      'is_active': isActive ? 1 : 0,
    };
  }
}

