import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_models.dart';
import '../services/pin_storage_service.dart';

// Secure storage provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// PIN storage service provider
final pinStorageProvider = Provider<PinStorageService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return PinStorageService(storage);
});

// Current auth session provider (StateNotifier)
final authSessionProvider =
    StateNotifierProvider<AuthSessionNotifier, AuthSession?>(
      (ref) => AuthSessionNotifier(),
    );

class AuthSessionNotifier extends StateNotifier<AuthSession?> {
  AuthSessionNotifier() : super(null);

  void setSession(
    String role, {
    int timeoutMinutes = 5,
    bool requirePinOnOpen = false,
  }) {
    state = AuthSession(
      role: role,
      loginTime: DateTime.now(),
      sessionTimeoutMinutes: timeoutMinutes,
      requirePinOnOpen: requirePinOnOpen,
    );
  }

  void updateSessionTimeout(int timeoutMinutes) {
    if (state != null) {
      state = state!.copyWith(sessionTimeoutMinutes: timeoutMinutes);
    }
  }

  void updateRequirePinOnOpen(bool value) {
    if (state != null) {
      state = state!.copyWith(requirePinOnOpen: value);
    }
  }

  void logout() {
    state = null;
  }

  bool get isSessionExpired => state == null || state!.isExpired;

  bool get isSessionActive => !isSessionExpired;
}

// PIN attempt tracking provider (StateNotifier)
final pinAttemptProvider =
    StateNotifierProvider<PinAttemptNotifier, PinAttempt>(
      (ref) => PinAttemptNotifier(),
    );

class PinAttemptNotifier extends StateNotifier<PinAttempt> {
  PinAttemptNotifier() : super(PinAttempt());

  void incrementFailure() {
    state = state.incrementFailure();
  }

  void reset() {
    state = state.reset();
  }

  bool get isLocked => state.isLocked;

  int get failureCount => state.failureCount;

  int get remainingLockSeconds => state.remainingLockSeconds;
}

// Validate PIN provider
final validatePinProvider = FutureProvider.family<bool, (String, String)>((
  ref,
  params,
) async {
  final pinStorage = ref.watch(pinStorageProvider);
  final (role, pin) = params;
  return await pinStorage.verifyPin(role, pin);
});

// Check if PIN is set for a role
final pinExistsProvider = FutureProvider.family<bool, String>((
  ref,
  role,
) async {
  final pinStorage = ref.watch(pinStorageProvider);
  return await pinStorage.pinExists(role);
});

// Initialize PINs provider
final initializePinsProvider = FutureProvider<void>((ref) async {
  final pinStorage = ref.watch(pinStorageProvider);
  await pinStorage.initializeDefaults();
});

// Set new PIN provider
final setPinProvider = FutureProvider.family<void, (String, String)>((
  ref,
  params,
) async {
  final pinStorage = ref.watch(pinStorageProvider);
  final (role, pin) = params;
  await pinStorage.setPinHash(role, pin);
});

// Session timeout minutes provider
final sessionTimeoutProvider = StateProvider<int>((ref) => 5);

// Require PIN on app open provider
final requirePinOnOpenProvider = StateProvider<bool>((ref) => false);
