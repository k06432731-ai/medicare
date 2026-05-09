import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/payment_repository.dart';
import '../data/models/payment_model.dart';

// Expose le repository pour l'utiliser directement depuis le screen
export '../data/repositories/payment_repository.dart'
    show PaymentRepository, StripeIntentResult, DirectPaymentResult;

// Statut du dernier paiement d'une facture (pour l'affichage dans la liste)
final paymentStatusProvider =
    FutureProvider.autoDispose.family<PaymentModel?, int>((ref, invoiceId) {
  return ref.watch(paymentRepositoryProvider).getStatus(invoiceId);
});
