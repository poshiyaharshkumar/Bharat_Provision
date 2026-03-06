class Category {
  Category({
    this.id,
    required this.nameGu,
    this.colorCode,
  });

  final int? id;
  final String nameGu;
  final String? colorCode;

  factory Category.fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id'] as int?,
      nameGu: map['name_gu'] as String,
      colorCode: map['color_code'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name_gu': nameGu,
      'color_code': colorCode,
    };
  }
}

