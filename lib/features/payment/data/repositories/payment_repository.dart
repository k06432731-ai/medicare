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

// ── Résultat du init Konnect ─────────────────────────────────────────────────

class KonnectInitResult {
  final String payUrl;
  final String paymentRef;

  const KonnectInitResult({
    required this.payUrl,
    required this.paymentRef,
  });
}

class KonnectVerifyResult {
  final String status; // pending | completed | failed | expired
  final String paymentRef;
  final int? invoiceId;

  const KonnectVerifyResult({
    required this.status,
    required this.paymentRef,
    this.invoiceId,
  });

  bool get isCompleted => status == 'completed';
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

  // ── Konnect (Tunisia) ────────────────────────────────────────────────────

  /// Initie un paiement Konnect côté backend.
  /// Retourne le payUrl à ouvrir dans la WebView + le paymentRef.
  Future<KonnectInitResult> initKonnectPayment({required int invoiceId}) async {
    try {
      final res = await _dio.post('/konnect-engine/init-payment', data: {
        'invoiceId': invoiceId,
      });
      final data = res.data['data'] as Map<String, dynamic>;
      return KonnectInitResult(
        payUrl: data['payUrl'] as String,
        paymentRef: data['paymentRef'] as String,
      );
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  /// Vérifie côté backend (qui re-vérifie auprès de Konnect) qu'un paiement
  /// est bien complété. Met à jour la facture si succès.
  Future<KonnectVerifyResult> verifyKonnectPayment(String paymentRef) async {
    try {
      final res = await _dio.get('/konnect-engine/verify/$paymentRef');
      final data = res.data['data'] as Map<String, dynamic>;
      return KonnectVerifyResult(
        status: data['status'] as String? ?? 'pending',
        paymentRef: data['paymentRef'] as String? ?? paymentRef,
        invoiceId: (data['invoiceId'] as num?)?.toInt(),
      );
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

  // ── Vérification Sobflous/D17 ─────────────────────────────────────────────

  /// Vérifie côté backend qu'un paiement Sobflous/D17 a bien été confirmé
  /// après retour du callback. À appeler après le retour de la WebView.
  Future<void> verifyPayment({
    required int invoiceId,
    required String transactionId,
  }) async {
    try {
      await _dio.post('/payment-engine/verify', data: {
        'invoiceId': invoiceId,
        'transactionId': transactionId,
      });
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
