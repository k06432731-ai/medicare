import 'package:flutter_test/flutter_test.dart';
import 'package:medicare/features/invoice/data/models/invoice_model.dart';

void main() {
  group('InvoiceModel.fromJson', () {
    test('parses flat Strapi v5 response', () {
      final json = {
        'id': 42,
        'amount': 150.0,
        'status': 'paid',
        'type': 'consultation',
        'description': 'Consultation généraliste',
        'paymentMethod': 'card',
        'createdAt': '2025-03-15T10:00:00.000Z',
        'paidAt': '2025-03-15T11:00:00.000Z',
      };
      final model = InvoiceModel.fromJson(json);

      expect(model.id, 42);
      expect(model.amount, 150.0);
      expect(model.status, InvoiceStatus.paid);
      expect(model.type, InvoiceType.consultation);
      expect(model.description, 'Consultation généraliste');
      expect(model.paymentMethod, PaymentMethod.card);
      expect(model.isPaid, true);
      expect(model.isPending, false);
    });

    test('parses lab_test type correctly', () {
      final json = {
        'id': 1,
        'amount': 80.0,
        'status': 'pending',
        'type': 'lab_test',
        'createdAt': '2025-03-15T10:00:00.000Z',
      };
      final model = InvoiceModel.fromJson(json);
      expect(model.type, InvoiceType.labTest);
      expect(model.status, InvoiceStatus.pending);
      expect(model.isPending, true);
    });

    test('parses prescription type correctly', () {
      final json = {
        'id': 2,
        'amount': 35.0,
        'status': 'pending',
        'type': 'prescription',
        'createdAt': '2025-03-15T10:00:00.000Z',
      };
      final model = InvoiceModel.fromJson(json);
      expect(model.type, InvoiceType.prescription);
    });

    test('falls back to consultation for unknown type', () {
      final json = {
        'id': 3,
        'amount': 50.0,
        'status': 'pending',
        'type': 'unknown_future_type',
        'createdAt': '2025-03-15T10:00:00.000Z',
      };
      final model = InvoiceModel.fromJson(json);
      expect(model.type, InvoiceType.consultation);
    });

    test('parses cancelled and refunded statuses', () {
      final cancelled = InvoiceModel.fromJson({
        'id': 4, 'amount': 50.0, 'status': 'cancelled', 'type': 'consultation',
        'createdAt': '2025-03-15T10:00:00.000Z',
      });
      final refunded = InvoiceModel.fromJson({
        'id': 5, 'amount': 50.0, 'status': 'refunded', 'type': 'consultation',
        'createdAt': '2025-03-15T10:00:00.000Z',
      });
      expect(cancelled.status, InvoiceStatus.cancelled);
      expect(refunded.status, InvoiceStatus.refunded);
    });

    test('doctorName builds from first/last name', () {
      final json = {
        'id': 10,
        'amount': 100.0,
        'status': 'paid',
        'type': 'consultation',
        'createdAt': '2025-01-01T00:00:00.000Z',
        'doctor': {
          'id': 5,
          'firstName': 'Ali',
          'lastName': 'Ben Salah',
        },
      };
      final model = InvoiceModel.fromJson(json);
      expect(model.doctorName, 'Dr. Ali Ben Salah');
    });

    test('doctorName returns Inconnu when doctor is null', () {
      final json = {
        'id': 11, 'amount': 0.0, 'status': 'pending', 'type': 'consultation',
        'createdAt': '2025-01-01T00:00:00.000Z',
      };
      final model = InvoiceModel.fromJson(json);
      expect(model.doctorName, 'Inconnu');
    });

    test('cash payment method parsed correctly', () {
      final json = {
        'id': 20, 'amount': 200.0, 'status': 'paid', 'type': 'consultation',
        'paymentMethod': 'cash', 'createdAt': '2025-01-01T00:00:00.000Z',
      };
      final model = InvoiceModel.fromJson(json);
      expect(model.paymentMethod, PaymentMethod.cash);
      expect(model.paymentMethod!.isStripe, false);
    });

    test('card payment method isStripe returns true', () {
      expect(PaymentMethod.card.isStripe, true);
      expect(PaymentMethod.cash.isStripe, false);
      expect(PaymentMethod.bankTransfer.isStripe, false);
    });

    test('apiValue strings are correct', () {
      expect(InvoiceStatus.pending.apiValue, 'pending');
      expect(InvoiceStatus.paid.apiValue, 'paid');
      expect(InvoiceType.labTest.apiValue, 'lab_test');
      expect(InvoiceType.prescription.apiValue, 'prescription');
      expect(PaymentMethod.bankTransfer.apiValue, 'bank_transfer');
    });
  });
}
