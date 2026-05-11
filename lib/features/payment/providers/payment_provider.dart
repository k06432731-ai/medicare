import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/payment_repository.dart';
import '../data/models/payment_model.dart';

// Expose le repository pour l'utiliser directement depuis le screen
export '../data/repositories/payment_repository.dart'
    show
        PaymentRepository,
        StripeIntentResult,
        DirectPaymentResult,
        KonnectInitResult,
        KonnectVerifyResult;

// ── Konnect state ──────────────────────────────────────────────────────────

enum KonnectStage { idle, loading, awaitingPayment, verifying, success, failed }

class KonnectPaymentState {
  final KonnectStage stage;
  final String? payUrl;
  final String? paymentRef;
  final String? error;

  const KonnectPaymentState({
    this.stage = KonnectStage.idle,
    this.payUrl,
    this.paymentRef,
    this.error,
  });

  KonnectPaymentState copyWith({
    KonnectStage? stage,
    String? payUrl,
    String? paymentRef,
    String? error,
  }) =>
      KonnectPaymentState(
        stage: stage ?? this.stage,
        payUrl: payUrl ?? this.payUrl,
        paymentRef: paymentRef ?? this.paymentRef,
        error: error,
      );
}

class KonnectPaymentNotifier extends StateNotifier<KonnectPaymentState> {
  final PaymentRepository _repo;
  KonnectPaymentNotifier(this._repo) : super(const KonnectPaymentState());

  /// Initie un paiement Konnect et retourne le payUrl (ou null en cas d'erreur).
  Future<KonnectInitResult?> payWithKonnect(int invoiceId) async {
    state = state.copyWith(stage: KonnectStage.loading, error: null);
    try {
      final res = await _repo.initKonnectPayment(invoiceId: invoiceId);
      state = KonnectPaymentState(
        stage: KonnectStage.awaitingPayment,
        payUrl: res.payUrl,
        paymentRef: res.paymentRef,
      );
      return res;
    } catch (e) {
      state = KonnectPaymentState(
        stage: KonnectStage.failed,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Vérifie le statut d'un paiement Konnect.
  Future<KonnectVerifyResult?> verify(String paymentRef) async {
    state = state.copyWith(stage: KonnectStage.verifying);
    try {
      final res = await _repo.verifyKonnectPayment(paymentRef);
      state = state.copyWith(
        stage: res.isCompleted ? KonnectStage.success : KonnectStage.failed,
        error: res.isCompleted ? null : 'Paiement non confirmé (${res.status})',
      );
      return res;
    } catch (e) {
      state = state.copyWith(stage: KonnectStage.failed, error: e.toString());
      return null;
    }
  }

  void reset() => state = const KonnectPaymentState();
}

final konnectPaymentProvider =
    StateNotifierProvider.autoDispose<KonnectPaymentNotifier, KonnectPaymentState>(
        (ref) {
  return KonnectPaymentNotifier(ref.watch(paymentRepositoryProvider));
});

// Statut du dernier paiement d'une facture (pour l'affichage dans la liste)
final paymentStatusProvider =
    FutureProvider.autoDispose.family<PaymentModel?, int>((ref, invoiceId) {
  return ref.watch(paymentRepositoryProvider).getStatus(invoiceId);
});
