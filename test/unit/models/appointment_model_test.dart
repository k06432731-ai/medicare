import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/features/appointment/data/models/appointment_model.dart';

void main() {
  group('AppointmentModel.fromJson', () {
    final futureDate =
        DateTime.now().add(const Duration(days: 3)).toIso8601String();
    final pastDate =
        DateTime.now().subtract(const Duration(days: 3)).toIso8601String();

    test('parses basic fields — Strapi v5 flat', () {
      final json = {
        'id': 7,
        'appointmentDate': futureDate,
        'status': 'confirmed',
        'type': 'in_person',
        'reason': 'Consultation générale',
        'notes': 'Rien à signaler',
      };
      final model = AppointmentModel.fromJson(json);
      expect(model.id, 7);
      expect(model.status, AppointmentStatus.confirmed);
      expect(model.type, AppointmentType.inPerson);
      expect(model.reason, 'Consultation générale');
      expect(model.notes, 'Rien à signaler');
    });

    test('parses teleconsultation type', () {
      final json = {
        'id': 8,
        'appointmentDate': futureDate,
        'status': 'pending',
        'type': 'teleconsultation',
        'reason': 'Suivi à distance',
      };
      final model = AppointmentModel.fromJson(json);
      expect(model.type, AppointmentType.teleconsultation);
    });

    test('isUpcoming for future confirmed appointment', () {
      final json = {
        'id': 9,
        'appointmentDate': futureDate,
        'status': 'confirmed',
        'type': 'in_person',
        'reason': 'Test',
      };
      final model = AppointmentModel.fromJson(json);
      expect(model.isUpcoming, true);
      expect(model.isPast, false);
    });

    test('isPast for past appointment', () {
      final json = {
        'id': 10,
        'appointmentDate': pastDate,
        'status': 'completed',
        'type': 'in_person',
        'reason': 'Test passé',
      };
      final model = AppointmentModel.fromJson(json);
      expect(model.isPast, true);
      expect(model.isUpcoming, false);
    });

    test('isPast for cancelled appointment regardless of date', () {
      final json = {
        'id': 11,
        'appointmentDate': futureDate,
        'status': 'cancelled',
        'type': 'in_person',
        'reason': 'Annulé',
      };
      final model = AppointmentModel.fromJson(json);
      expect(model.isPast, true);
    });

    test('parses all status values correctly', () {
      final statuses = {
        'pending': AppointmentStatus.pending,
        'confirmed': AppointmentStatus.confirmed,
        'cancelled': AppointmentStatus.cancelled,
        'completed': AppointmentStatus.completed,
        'no_show': AppointmentStatus.noShow,
      };
      for (final entry in statuses.entries) {
        final model = AppointmentModel.fromJson({
          'id': 1, 'appointmentDate': futureDate,
          'status': entry.key, 'type': 'in_person', 'reason': 'r',
        });
        expect(model.status, entry.value,
            reason: 'Failed for status=${entry.key}');
      }
    });

    test('patientName from firstName+lastName', () {
      final json = {
        'id': 12,
        'appointmentDate': futureDate,
        'status': 'pending',
        'type': 'in_person',
        'reason': 'Test',
        'patient': {
          'id': 20, 'firstName': 'Sana', 'lastName': 'Trabelsi',
        },
      };
      final model = AppointmentModel.fromJson(json);
      expect(model.patientName, 'Sana Trabelsi');
      expect(model.patientId, 20);
    });

    test('patientName falls back to username', () {
      final json = {
        'id': 13,
        'appointmentDate': futureDate,
        'status': 'pending',
        'type': 'in_person',
        'reason': 'Test',
        'patient': {'id': 21, 'username': 'sana.trb'},
      };
      final model = AppointmentModel.fromJson(json);
      expect(model.patientName, 'sana.trb');
    });

    test('apiValue strings for statuses', () {
      expect(AppointmentStatus.pending.apiValue, 'pending');
      expect(AppointmentStatus.noShow.apiValue, 'no_show');
      expect(AppointmentStatus.confirmed.apiValue, 'confirmed');
      expect(AppointmentType.teleconsultation.apiValue, 'teleconsultation');
    });

    test('equatable — same id means equal models', () {
      final json = {
        'id': 99, 'appointmentDate': futureDate,
        'status': 'pending', 'type': 'in_person', 'reason': 'Eq test',
      };
      final a = AppointmentModel.fromJson(json);
      final b = AppointmentModel.fromJson(json);
      expect(a, equals(b));
    });
  });
}
