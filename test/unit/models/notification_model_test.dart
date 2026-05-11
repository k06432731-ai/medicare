import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/features/notification/data/models/notification_model.dart';

void main() {
  group('NotificationModel.fromJson', () {
    test('parses flat Strapi v5 response', () {
      final json = {
        'id': 1,
        'title': 'Rendez-vous confirmé',
        'body': 'Votre RDV du 15 mars est confirmé.',
        'type': 'appointment',
        'userId': 42,
        'read': false,
        'createdAt': '2025-03-14T09:00:00.000Z',
      };
      final model = NotificationModel.fromJson(json);
      expect(model.id, 1);
      expect(model.title, 'Rendez-vous confirmé');
      expect(model.body, 'Votre RDV du 15 mars est confirmé.');
      expect(model.type, NotificationType.appointment);
      expect(model.userId, 42);
      expect(model.read, false);
    });

    test('parses Strapi v4 attributes-wrapped response', () {
      final json = {
        'id': 2,
        'attributes': {
          'title': 'Nouvelle ordonnance',
          'body': 'Une ordonnance a été créée.',
          'type': 'prescription',
          'userId': 10,
          'read': true,
          'createdAt': '2025-03-14T09:00:00.000Z',
        },
      };
      final model = NotificationModel.fromJson(json);
      expect(model.id, 2);
      expect(model.type, NotificationType.prescription);
      expect(model.read, true);
    });

    test('all type strings map to correct enum values', () {
      final typeMappings = {
        'appointment': NotificationType.appointment,
        'prescription': NotificationType.prescription,
        'invoice': NotificationType.invoice,
        'recovery': NotificationType.recovery,
        'message': NotificationType.message,
        'unknown_future_type': NotificationType.system,
        null: NotificationType.system,
      };
      for (final entry in typeMappings.entries) {
        final result = NotificationTypeX.fromApi(entry.key);
        expect(result, entry.value,
            reason: 'Failed for type="${entry.key}"');
      }
    });

    test('read defaults to false when absent', () {
      final json = {
        'id': 3,
        'title': 'Test',
        'body': 'Body',
        'type': 'system',
        'userId': 1,
        'createdAt': '2025-01-01T00:00:00.000Z',
      };
      final model = NotificationModel.fromJson(json);
      expect(model.read, false);
    });

    test('createdAt parsed correctly', () {
      final json = {
        'id': 4,
        'title': 'T',
        'body': 'B',
        'type': 'system',
        'userId': 1,
        'read': false,
        'createdAt': '2025-06-15T14:30:00.000Z',
      };
      final model = NotificationModel.fromJson(json);
      expect(model.createdAt.year, 2025);
      expect(model.createdAt.month, 6);
      expect(model.createdAt.day, 15);
    });

    test('all types have non-null icons and colors', () {
      for (final t in NotificationType.values) {
        expect(t.icon, isNotNull);
        expect(t.color, isNotNull);
        expect(t.surface, isNotNull);
      }
    });
  });
}
