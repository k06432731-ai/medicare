import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../models/payment_model.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(dioClientProvider));
});

// ── Résultat du create-intent ──────────────────────────────────────────────────

class StripeIntentResult {
  final String clientSecret;
  final String paymentIntentId;
  final double amount;
  final String currency;

  const StripeIntentResult({
    required this.clientSecret,
    required this.paymentIntentId,
    required this.amount,
    required this.currency,
  });
}

// ── Résultat du init direct (cash / virement / mobile) ───────────────────────

class DirectPaymentResult {
  final String status;
  final String transactionId;

  const DirectPaymentResult({
    required this.status,
    required this.transactionId,
  });
}

// ── Repository ────────────────────────────────────────────────────────────────

class PaymentRepository {
  final Dio _dio;
  PaymentRepository(this._dio);

  // ── Stripe ──────────────────────────────────────────────────────────────────

  /// Crée un PaymentIntent Stripe côté backend.
  /// Retourne le clientSecret à passer au Payment Sheet.
  Future<StripeIntentResult> createStripeIntent(int invoiceId) async {
    try {
      final res = await _dio.post('/stripe-engine/create-intent', data: {
        'invoiceId': invoiceId,
      });
      final data = res.data['data'] as Map<String, dynamic>;
      return StripeIntentResult(
        clientSecret: data['clientSecret'] as String,
        paymentIntentId: data['paymentIntentId'] as String,
        amount: (data['amount'] as num).toDouble(),
        currency: data['currency'] as String? ?? 'eur',
      );
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  /// Confirme côté backend que le PaymentIntent Stripe est bien succeeded.
  /// Le backend re-vérifie directement auprès de l'API Stripe (pas de trust client).
  Future<void> confirmStripePayment({
    required int invoiceId,
    required String paymentIntentId,
  }) async {
    try {
      await _dio.post('/stripe-engine/confirm', data: {
        'invoiceId': invoiceId,
        'paymentIntentId': paymentIntentId,
      });
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── Méthodes directes (cash / virement / mobile) ─────────────────────────

  Future<DirectPaymentResult> initDirectPayment({
    required int invoiceId,
    required String method,
  }) async {
    try {
      final res = await _dio.post('/payment-engine/init', data: {
        'invoiceId': invoiceId,
        'method': method,
      });
      final data = res.data['data'] as Map<String, dynamic>;
      return DirectPaymentResult(
        status: data['status'] as String? ?? 'completed',
        transactionId: data['transactionId'] as String? ?? '',
      );
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  // ── Statut ───────────────────────────────────────────────────────────────

  Future<PaymentModel?> getStatus(int invoiceId) async {
    try {
      final res = await _dio.get('/payment-engine/status/$invoiceId');
      final data = res.data['data'];
      if (data == null) return null;
      return PaymentModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}
