import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository.dart';

const largeTextSettingKey = 'large_text';

class LargeTextNotifier extends StateNotifier<bool> {
  LargeTextNotifier(this._repo) : super(false) {
    _load();
  }

  final SettingsRepository _repo;

  Future<void> _load() async {
    final s = await _repo.getByKey(largeTextSettingKey);
    if (s?.value == 'true') state = true;
  }

  Future<void> setLargeText(bool value) async {
    state = value;
    await _repo.setValue(largeTextSettingKey, value.toString());
  }
}
