import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel.fromJson', () {
    final sampleJson = {
      'id': 1,
      'username': 'patient.test',
      'email': 'patient@medicare.tn',
      'firstName': 'Amel',
      'lastName': 'Ferchichi',
      'phone': '+21698765432',
      'appRole': 'patient',
      'confirmed': true,
      'isAvailable': true,
    };

    test('parses basic patient fields', () {
      final user = UserModel.fromJson(sampleJson);
      expect(user.id, 1);
      expect(user.username, 'patient.test');
      expect(user.email, 'patient@medicare.tn');
      expect(user.firstName, 'Amel');
      expect(user.lastName, 'Ferchichi');
      expect(user.phone, '+21698765432');
      expect(user.role, 'patient');
      expect(user.confirmed, true);
    });

    test('fullName combines first and last name', () {
      final user = UserModel.fromJson(sampleJson);
      expect(user.fullName, 'Amel Ferchichi');
    });

    test('fullName returns firstName only when lastName absent', () {
      final user = UserModel.fromJson({
        ...sampleJson, 'lastName': null,
      });
      expect(user.fullName, 'Amel');
    });

    test('fullName falls back to username', () {
      final user = UserModel.fromJson({
        'id': 2, 'username': 'fallback_user', 'email': 'f@f.com',
        'confirmed': false, 'isAvailable': true,
      });
      expect(user.fullName, 'fallback_user');
    });

    test('initials from first and last name', () {
      final user = UserModel.fromJson(sampleJson);
      expect(user.initials, 'AF');
    });

    test('initials from username first char when names absent', () {
      final user = UserModel.fromJson({
        'id': 3, 'username': 'zara99', 'email': 'z@z.com',
        'confirmed': false, 'isAvailable': true,
      });
      expect(user.initials, 'Z');
    });

    test('role extracted from appRole field', () {
      final doctor = UserModel.fromJson({
        ...sampleJson, 'appRole': 'doctor',
      });
      expect(doctor.role, 'doctor');
    });

    test('role extracted from role.type when appRole absent', () {
      final admin = UserModel.fromJson({
        'id': 4, 'username': 'admin', 'email': 'a@a.com',
        'confirmed': true, 'isAvailable': true,
        'role': {'type': 'admin', 'name': 'Admin'},
      });
      expect(admin.role, 'admin');
    });

    test('role defaults to patient when both absent', () {
      final user = UserModel.fromJson({
        'id': 5, 'username': 'unknown', 'email': 'u@u.com',
        'confirmed': false, 'isAvailable': true,
      });
      expect(user.role, 'patient');
    });

    test('confirmed defaults to false when absent', () {
      final user = UserModel.fromJson({
        'id': 6, 'username': 'unconfirmed', 'email': 'u@u.com',
        'isAvailable': true,
      });
      expect(user.confirmed, false);
    });

    test('avatarUrl extracted from avatar.url', () {
      final user = UserModel.fromJson({
        ...sampleJson,
        'avatar': {'url': 'https://cdn.medicare.tn/avatar.jpg'},
      });
      expect(user.avatarUrl, 'https://cdn.medicare.tn/avatar.jpg');
    });

    test('avatarUrl extracted from avatar.formats.thumbnail', () {
      final user = UserModel.fromJson({
        ...sampleJson,
        'avatar': {
          'url': 'https://cdn.medicare.tn/original.jpg',
          'formats': {
            'thumbnail': {'url': 'https://cdn.medicare.tn/thumb.jpg'},
          },
        },
      });
      expect(user.avatarUrl, 'https://cdn.medicare.tn/thumb.jpg');
    });

    test('copyWith preserves unchanged fields', () {
      final original = UserModel.fromJson(sampleJson);
      final updated = original.copyWith(phone: '+21699999999');
      expect(updated.phone, '+21699999999');
      expect(updated.firstName, 'Amel'); // unchanged
      expect(updated.email, 'patient@medicare.tn'); // unchanged
      expect(updated.role, 'patient'); // unchanged
    });
  });
}
