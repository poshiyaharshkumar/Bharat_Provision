class SettingEntry {
  SettingEntry({
    required this.key,
    required this.value,
  });

  final String key;
  final String value;

  factory SettingEntry.fromMap(Map<String, Object?> map) {
    return SettingEntry(
      key: map['key'] as String,
      value: map['value'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'key': key,
      'value': value,
    };
  }
}

