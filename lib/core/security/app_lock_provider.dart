import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../features/settings/providers/settings_provider.dart';

// ── State ────────────────────────────────────────────────────────────────────

enum AppLockStatus { unlocked, locked }

// ── Notifier ─────────────────────────────────────────────────────────────────

class AppLockNotifier extends StateNotifier<AppLockStatus> {
  final Ref _ref;
  final LocalAuthentication _auth = LocalAuthentication();
  Timer? _lockTimer;

  AppLockNotifier(this._ref) : super(AppLockStatus.unlocked);

  /// Called when app goes to background (paused/inactive)
  void onBackground() {
    final settings = _ref.read(settingsProvider);
    final minutes = settings.autoLockMinutes;
    if (!settings.biometricEnabled || minutes == 0) return;

    _lockTimer?.cancel();
    if (minutes == -1) {
      // Immediate lock
      _lock();
    } else {
      _lockTimer = Timer(Duration(minutes: minutes), _lock);
    }
  }

  /// Called when app comes to foreground (resumed)
  void onForeground() {
    _lockTimer?.cancel();
  }

  void _lock() {
    state = AppLockStatus.locked;
  }

  /// Attempt biometric / device credential authentication.
  /// Returns true if successful and unlocks.
  Future<bool> authenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!canCheck && !isDeviceSupported) {
        // No biometric / PIN available — unlock without auth
        state = AppLockStatus.unlocked;
        return true;
      }

      final authenticated = await _auth.authenticate(
        localizedReason:
            'Identifiez-vous pour accéder à vos données médicales',
        options: const AuthenticationOptions(
          biometricOnly: false, // allow PIN fallback
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        state = AppLockStatus.unlocked;
      }
      return authenticated;
    } catch (_) {
      // local_auth unavailable (e.g. emulator) — unlock gracefully
      state = AppLockStatus.unlocked;
      return true;
    }
  }

  /// Check whether device supports biometrics (for the toggle in settings)
  Future<bool> canUseBiometrics() async {
    try {
      return await _auth.canCheckBiometrics ||
          await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    super.dispose();
  }
}

final appLockProvider =
    StateNotifierProvider<AppLockNotifier, AppLockStatus>((ref) {
  return AppLockNotifier(ref);
});
