class AppUser {
  AppUser({
    this.id,
    required this.name,
    this.pin,
    required this.role,
    this.isActive = true,
  });

  final int? id;
  final String name;
  final String? pin;
  final String role; // 'owner' or 'staff'
  final bool isActive;

  factory AppUser.fromMap(Map<String, Object?> map) {
    return AppUser(
      id: map['id'] as int?,
      name: map['name'] as String,
      pin: map['pin'] as String?,
      role: map['role'] as String,
      isActive: (map['is_active'] as int) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'pin': pin,
      'role': role,
      'is_active': isActive ? 1 : 0,
    };
  }
}

