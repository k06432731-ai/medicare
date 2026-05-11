import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/features/settings/providers/settings_provider.dart';

void main() {
  group('AppSettings', () {
    test('default values are correct', () {
      const settings = AppSettings();
      expect(settings.notifAppointment, true);
      expect(settings.notifPrescription, true);
      expect(settings.notifInvoice, true);
      expect(settings.biometricEnabled, false);
      expect(settings.autoLockMinutes, 5);
      expect(settings.darkMode, false);
    });

    test('copyWith darkMode toggle', () {
      const settings = AppSettings();
      final dark = settings.copyWith(darkMode: true);
      expect(dark.darkMode, true);
      // Other fields unchanged
      expect(dark.notifAppointment, true);
      expect(dark.autoLockMinutes, 5);
    });

    test('copyWith biometric toggle', () {
      const settings = AppSettings();
      final withBio = settings.copyWith(biometricEnabled: true);
      expect(withBio.biometricEnabled, true);
      expect(withBio.darkMode, false); // unchanged
    });

    test('copyWith notifAppointment false', () {
      const settings = AppSettings();
      final updated = settings.copyWith(notifAppointment: false);
      expect(updated.notifAppointment, false);
      expect(updated.notifPrescription, true); // unchanged
    });

    test('copyWith autoLockMinutes updates correctly', () {
      const settings = AppSettings();
      final updated = settings.copyWith(autoLockMinutes: 15);
      expect(updated.autoLockMinutes, 15);
    });

    test('copyWith with no arguments returns identical settings', () {
      const settings = AppSettings(
        darkMode: true,
        biometricEnabled: true,
        autoLockMinutes: 1,
        notifInvoice: false,
      );
      final copy = settings.copyWith();
      expect(copy.darkMode, settings.darkMode);
      expect(copy.biometricEnabled, settings.biometricEnabled);
      expect(copy.autoLockMinutes, settings.autoLockMinutes);
      expect(copy.notifInvoice, settings.notifInvoice);
    });

    test('copyWith only updates specified fields', () {
      const settings = AppSettings(
        darkMode: true,
        biometricEnabled: true,
        autoLockMinutes: 30,
        notifAppointment: false,
        notifPrescription: false,
        notifInvoice: false,
      );
      final updated = settings.copyWith(darkMode: false);
      expect(updated.darkMode, false);
      // Everything else stays the same
      expect(updated.biometricEnabled, true);
      expect(updated.autoLockMinutes, 30);
      expect(updated.notifAppointment, false);
      expect(updated.notifPrescription, false);
      expect(updated.notifInvoice, false);
    });
  });
}
