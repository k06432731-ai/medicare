import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/features/doctor/data/models/doctor_model.dart';

void main() {
  group('DoctorModel.fromJson', () {
    final sampleJson = {
      'id': 1,
      'username': 'dr.karim',
      'email': 'karim@medicare.tn',
      'firstName': 'Karim',
      'lastName': 'Mansour',
      'specialty': 'Cardiologie',
      'consultationFee': 120.0,
      'isAvailable': true,
      'phone': '+21612345678',
      'bio': 'Cardiologue depuis 15 ans',
      'licenseNumber': 'MD-0042',
    };

    test('parses all basic fields', () {
      final model = DoctorModel.fromJson(sampleJson);
      expect(model.id, 1);
      expect(model.username, 'dr.karim');
      expect(model.email, 'karim@medicare.tn');
      expect(model.firstName, 'Karim');
      expect(model.lastName, 'Mansour');
      expect(model.specialty, 'Cardiologie');
      expect(model.consultationFee, 120.0);
      expect(model.isAvailable, true);
      expect(model.phone, '+21612345678');
    });

    test('fullName combines first and last name', () {
      final model = DoctorModel.fromJson(sampleJson);
      expect(model.fullName, 'Karim Mansour');
    });

    test('fullName falls back to username when names are null', () {
      final model = DoctorModel.fromJson({
        'id': 2,
        'username': 'dr.anon',
        'email': 'anon@medicare.tn',
        'isAvailable': true,
      });
      expect(model.fullName, 'dr.anon');
    });

    test('initials from first and last name', () {
      final model = DoctorModel.fromJson(sampleJson);
      expect(model.initials, 'KM');
    });

    test('initials from username when names absent', () {
      final model = DoctorModel.fromJson({
        'id': 3, 'username': 'drsmith', 'email': 'e@e.com', 'isAvailable': true,
      });
      expect(model.initials, 'DR');
    });

    test('displaySpecialty falls back to Généraliste', () {
      final model = DoctorModel.fromJson({
        'id': 4, 'username': 'generalist', 'email': 'g@medicare.tn',
        'isAvailable': true,
      });
      expect(model.displaySpecialty, 'Généraliste');
    });

    test('displaySpecialty returns specialty when set', () {
      final model = DoctorModel.fromJson(sampleJson);
      expect(model.displaySpecialty, 'Cardiologie');
    });

    test('isAvailable defaults to true when absent', () {
      final model = DoctorModel.fromJson({
        'id': 5, 'username': 'u', 'email': 'u@u.com',
      });
      expect(model.isAvailable, true);
    });

    test('avatarUrl extracted from avatar.url', () {
      final model = DoctorModel.fromJson({
        ...sampleJson,
        'avatar': {'url': 'https://cdn.medicare.tn/avatar.jpg'},
      });
      expect(model.avatarUrl, 'https://cdn.medicare.tn/avatar.jpg');
    });

    test('equatable props work — same id → equal', () {
      final a = DoctorModel.fromJson(sampleJson);
      final b = DoctorModel.fromJson(sampleJson);
      expect(a, equals(b));
    });

    test('toJson round-trip preserves key fields', () {
      final model = DoctorModel.fromJson(sampleJson);
      final json = model.toJson();
      expect(json['id'], 1);
      expect(json['specialty'], 'Cardiologie');
      expect(json['isAvailable'], true);
    });
  });
}
