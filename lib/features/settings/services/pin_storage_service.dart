import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/pin_utils.dart';

/// Secure PIN storage using flutter_secure_storage
class PinStorageService {
  static const String _superadminPinKey = 'pin_superadmin';
  static const String _adminPinKey = 'pin_admin';
  static const String _employeePinKey = 'pin_employee';

  final FlutterSecureStorage _storage;

  const PinStorageService(this._storage);

  // Get stored PIN hash for a role
  Future<String?> getPinHash(String role) async {
    final key = _getPinKey(role);
    return await _storage.read(key: key);
  }

  // Store PIN hash for a role
  Future<void> setPinHash(String role, String pin) async {
    final key = _getPinKey(role);
    final hash = PinUtils.hashPin(pin);
    await _storage.write(key: key, value: hash);
  }

  // Verify PIN for a role
  Future<bool> verifyPin(String role, String pin) async {
    final storedHash = await getPinHash(role);
    if (storedHash == null) return false;
    return PinUtils.verifyPin(pin, storedHash);
  }

  // Check if PIN exists for a role
  Future<bool> pinExists(String role) async {
    final hash = await getPinHash(role);
    return hash != null;
  }

  // Initialize default PINs if not set
  Future<void> initializeDefaults() async {
    if (!await pinExists('superadmin')) {
      await setPinHash('superadmin', '000000');
    }
    if (!await pinExists('admin')) {
      await setPinHash('admin', '0000');
    }
    if (!await pinExists('employee')) {
      await setPinHash('employee', '0000');
    }
  }

  // Delete PIN for a role
  Future<void> deletePin(String role) async {
    final key = _getPinKey(role);
    await _storage.delete(key: key);
  }

  String _getPinKey(String role) {
    switch (role) {
      case 'superadmin':
        return _superadminPinKey;
      case 'admin':
        return _adminPinKey;
      case 'employee':
        return _employeePinKey;
      default:
        throw ArgumentError('Invalid role: $role');
    }
  }
}
