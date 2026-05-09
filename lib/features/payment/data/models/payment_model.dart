enum PaymentStatus { pending, processing, completed, failed }

extension PaymentStatusExt on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.pending => 'En attente',
        PaymentStatus.processing => 'En cours',
        PaymentStatus.completed => 'Complété',
        PaymentStatus.failed => 'Échoué',
      };
}

class PaymentModel {
  final int? id;
  final int invoiceId;
  final int patientId;
  final double amount;
  final String method;
  final PaymentStatus status;
  final String? transactionId;
  final String? paymentUrl;

  const PaymentModel({
    this.id,
    required this.invoiceId,
    required this.patientId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    this.paymentUrl,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final d = json['attributes'] as Map<String, dynamic>? ?? json;
    PaymentStatus status = PaymentStatus.pending;
    switch (d['status'] as String? ?? 'pending') {
      case 'processing': status = PaymentStatus.processing;
      case 'completed': status = PaymentStatus.completed;
      case 'failed': status = PaymentStatus.failed;
    }
    return PaymentModel(
      id: json['id'] as int?,
      invoiceId: (d['invoiceId'] as num?)?.toInt() ?? 0,
      patientId: (d['patientId'] as num?)?.toInt() ?? 0,
      amount: (d['amount'] as num?)?.toDouble() ?? 0,
      method: d['method'] as String? ?? '',
      status: status,
      transactionId: d['transactionId'] as String?,
      paymentUrl: d['paymentUrl'] as String?,
    );
  }
}
