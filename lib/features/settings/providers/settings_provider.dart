import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Keys ────────────────────────────────────────────────────────────────────

const _kNotifAppointment = 'notif_appointment';
const _kNotifPrescription = 'notif_prescription';
const _kNotifInvoice = 'notif_invoice';
const _kBiometricEnabled = 'biometric_enabled';
const _kAutoLockMinutes = 'auto_lock_minutes';

// ── SharedPreferences provider (overridden in main.dart) ────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

// ── AppSettings model ────────────────────────────────────────────────────────

class AppSettings {
  final bool notifAppointment;
  final bool notifPrescription;
  final bool notifInvoice;
  final bool biometricEnabled;
  final int autoLockMinutes; // 0 = never, 1, 5, 15, 30

  const AppSettings({
    this.notifAppointment = true,
    this.notifPrescription = true,
    this.notifInvoice = true,
    this.biometricEnabled = false,
    this.autoLockMinutes = 5,
  });

  AppSettings copyWith({
    bool? notifAppointment,
    bool? notifPrescription,
    bool? notifInvoice,
    bool? biometricEnabled,
    int? autoLockMinutes,
  }) {
    return AppSettings(
      notifAppointment: notifAppointment ?? this.notifAppointment,
      notifPrescription: notifPrescription ?? this.notifPrescription,
      notifInvoice: notifInvoice ?? this.notifInvoice,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
    );
  }
}

// ── SettingsNotifier ─────────────────────────────────────────────────────────

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs) : super(_load(_prefs));

  static AppSettings _load(SharedPreferences prefs) {
    return AppSettings(
      notifAppointment: prefs.getBool(_kNotifAppointment) ?? true,
      notifPrescription: prefs.getBool(_kNotifPrescription) ?? true,
      notifInvoice: prefs.getBool(_kNotifInvoice) ?? true,
      biometricEnabled: prefs.getBool(_kBiometricEnabled) ?? false,
      autoLockMinutes: prefs.getInt(_kAutoLockMinutes) ?? 5,
    );
  }

  Future<void> setNotifAppointment(bool v) async {
    await _prefs.setBool(_kNotifAppointment, v);
    state = state.copyWith(notifAppointment: v);
  }

  Future<void> setNotifPrescription(bool v) async {
    await _prefs.setBool(_kNotifPrescription, v);
    state = state.copyWith(notifPrescription: v);
  }

  Future<void> setNotifInvoice(bool v) async {
    await _prefs.setBool(_kNotifInvoice, v);
    state = state.copyWith(notifInvoice: v);
  }

  Future<void> setBiometricEnabled(bool v) async {
    await _prefs.setBool(_kBiometricEnabled, v);
    state = state.copyWith(biometricEnabled: v);
  }

  Future<void> setAutoLockMinutes(int v) async {
    await _prefs.setInt(_kAutoLockMinutes, v);
    state = state.copyWith(autoLockMinutes: v);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});
