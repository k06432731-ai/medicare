import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/features/ai_assistant/data/models/triage_result_model.dart';

void main() {
  group('TriageResultModel', () {
    group('fromJson', () {
      test('parses high urgency correctly', () {
        final json = {
          'urgency': 'high',
          'specialty': 'Cardiologue',
          'recommendation': 'Consultez un cardiologue en urgence.',
          'disclaimer': 'Ne remplace pas un avis médical.',
        };
        final model = TriageResultModel.fromJson(json);
        expect(model.urgency, TriageUrgency.high);
        expect(model.specialty, 'Cardiologue');
        expect(model.recommendation, 'Consultez un cardiologue en urgence.');
        expect(model.disclaimer, 'Ne remplace pas un avis médical.');
      });

      test('parses medium urgency', () {
        final json = {
          'urgency': 'medium',
          'specialty': 'Médecin généraliste',
          'recommendation': 'Consultez dans les 24h.',
          'disclaimer': 'Avis médical requis.',
        };
        final model = TriageResultModel.fromJson(json);
        expect(model.urgency, TriageUrgency.medium);
      });

      test('parses low urgency (default)', () {
        final json = {
          'urgency': 'low',
          'specialty': 'Généraliste',
          'recommendation': 'Repos et hydratation.',
          'disclaimer': 'Consultez si aggravation.',
        };
        final model = TriageResultModel.fromJson(json);
        expect(model.urgency, TriageUrgency.low);
      });

      test('parses emergency urgency', () {
        final json = {
          'urgency': 'emergency',
          'specialty': 'Urgences',
          'recommendation': 'Appelez le 190 immédiatement.',
          'disclaimer': '',
        };
        final model = TriageResultModel.fromJson(json);
        expect(model.urgency, TriageUrgency.emergency);
      });

      test('defaults to low for unknown urgency string', () {
        final json = {
          'urgency': 'banana',
          'specialty': 'Généraliste',
          'recommendation': 'Repos.',
          'disclaimer': 'Consultez.',
        };
        final model = TriageResultModel.fromJson(json);
        expect(model.urgency, TriageUrgency.low);
      });

      test('defaults specialty when absent', () {
        final model = TriageResultModel.fromJson({
          'urgency': 'low',
          'recommendation': 'Repos.',
          'disclaimer': 'Consultez.',
        });
        expect(model.specialty, 'Médecin généraliste');
      });
    });

    group('tryParse — raw LLM JSON string', () {
      test('parses valid JSON string', () {
        const raw =
            '{"urgency": "medium", "specialty": "ORL", "recommendation": "Consultez un ORL.", "disclaimer": "Avis médical."}';
        final model = TriageResultModel.tryParse(raw);
        expect(model, isNotNull);
        expect(model!.urgency, TriageUrgency.medium);
        expect(model.specialty, 'ORL');
      });

      test('extracts JSON embedded in markdown code block text', () {
        const raw = '''
Voici mon analyse :
{"urgency": "high", "specialty": "Cardio", "recommendation": "Urgence.", "disclaimer": "Avis médical."}
Prenez soin de vous.
''';
        final model = TriageResultModel.tryParse(raw);
        expect(model, isNotNull);
        expect(model!.urgency, TriageUrgency.high);
      });

      test('returns null for non-JSON string', () {
        final model = TriageResultModel.tryParse('Bonjour, je suis un LLM.');
        expect(model, isNull);
      });

      test('returns null for malformed JSON', () {
        final model = TriageResultModel.tryParse('{broken json}');
        expect(model, isNull);
      });
    });

    group('TriageUrgencyX extensions', () {
      test('all labels are non-empty strings', () {
        for (final u in TriageUrgency.values) {
          expect(u.label.isNotEmpty, true, reason: 'Empty label for $u');
        }
      });

      test('emergency label contains SAMU or 190', () {
        expect(TriageUrgency.emergency.label.contains('190'), true);
      });

      test('all icons are non-null', () {
        for (final u in TriageUrgency.values) {
          // Just checking the getter resolves without throwing
          expect(u.icon, isNotNull);
        }
      });

      test('colors have different values for different urgencies', () {
        final colors = TriageUrgency.values.map((u) => u.color).toSet();
        expect(colors.length, greaterThan(1));
      });
    });
  });
}
