import 'package:crypto/crypto.dart';
import 'dart:convert';

/// PIN hashing and verification utility
class PinUtils {
  // Hash PIN using SHA-256
  static String hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  // Verify PIN against hash
  static bool verifyPin(String pin, String hash) {
    return hashPin(pin) == hash;
  }

  // Validate PIN format (6 digits for superadmin, 4-6 for others)
  static bool isValidPin(String pin, {bool isSuperadmin = false}) {
    if (pin.isEmpty) return false;
    if (!RegExp(r'^\d+$').hasMatch(pin)) return false;

    if (isSuperadmin) {
      return pin.length == 6;
    }
    return pin.length >= 4 && pin.length <= 6;
  }

  // Generate hash for storing in secure storage
  static String generateSecurePin(String pin) {
    return hashPin(pin);
  }
}
