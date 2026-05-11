import 'package:flutter/material.dart';
import 'package:medicare/core/constants/app_colors.dart';

enum InvoiceStatus { pending, paid, cancelled, refunded }
enum InvoiceType { consultation, labTest, prescription }
enum PaymentMethod { cash, bankTransfer, mobileMoney, card }

extension InvoiceStatusExt on InvoiceStatus {
  String get label => switch (this) {
        InvoiceStatus.pending => 'En attente',
        InvoiceStatus.paid => 'Payée',
        InvoiceStatus.cancelled => 'Annulée',
        InvoiceStatus.refunded => 'Remboursée',
      };
  String get apiValue => switch (this) {
        InvoiceStatus.pending => 'pending',
        InvoiceStatus.paid => 'paid',
        InvoiceStatus.cancelled => 'cancelled',
        InvoiceStatus.refunded => 'refunded',
      };
  Color get color => switch (this) {
        InvoiceStatus.pending => AppColors.warning,
        InvoiceStatus.paid => AppColors.success,
        InvoiceStatus.cancelled => AppColors.error,
        InvoiceStatus.refunded => AppColors.tertiary,
      };
}

extension InvoiceTypeExt on InvoiceType {
  String get label => switch (this) {
        InvoiceType.consultation => 'Consultation',
        InvoiceType.labTest => 'Analyse / Labo',
        InvoiceType.prescription => 'Ordonnance',
      };
  String get apiValue => switch (this) {
        InvoiceType.consultation => 'consultation',
        InvoiceType.labTest => 'lab_test',
        InvoiceType.prescription => 'prescription',
      };
  IconData get icon => switch (this) {
        InvoiceType.consultation => Icons.medical_services_rounded,
        InvoiceType.labTest => Icons.science_rounded,
        InvoiceType.prescription => Icons.receipt_long_rounded,
      };
  Color get color => switch (this) {
        InvoiceType.consultation => AppColors.doctorColor,
        InvoiceType.labTest => const Color(0xFF06B6D4),
        InvoiceType.prescription => AppColors.secondary,
      };
}

extension PaymentMethodExt on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Espèces',
        PaymentMethod.bankTransfer => 'Virement bancaire',
        PaymentMethod.mobileMoney => 'Mobile Money',
        PaymentMethod.card => 'Carte bancaire',
      };
  String get apiValue => switch (this) {
        PaymentMethod.cash => 'cash',
        PaymentMethod.bankTransfer => 'bank_transfer',
        PaymentMethod.mobileMoney => 'mobile_money',
        PaymentMethod.card => 'card',
      };
  IconData get icon => switch (this) {
        PaymentMethod.cash => Icons.payments_rounded,
        PaymentMethod.bankTransfer => Icons.account_balance_rounded,
        PaymentMethod.mobileMoney => Icons.phone_android_rounded,
        PaymentMethod.card => Icons.credit_card_rounded,
      };
  bool get isStripe => this == PaymentMethod.card;
}

class InvoiceModel {
  final int id;
  final double amount;
  final InvoiceStatus status;
  final InvoiceType type;
  final String? description;
  final PaymentMethod? paymentMethod;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final DateTime createdAt;
  final Map<String, dynamic>? patient;
  final Map<String, dynamic>? doctor;
  final Map<String, dynamic>? appointment;
  final Map<String, dynamic>? labOrder;

  const InvoiceModel({
    required this.id,
    required this.amount,
    required this.status,
    required this.type,
    this.description,
    this.paymentMethod,
    this.dueDate,
    this.paidAt,
    required this.createdAt,
    this.patient,
    this.doctor,
    this.appointment,
    this.labOrder,
  });

  bool get isPending => status == InvoiceStatus.pending;
  bool get isPaid => status == InvoiceStatus.paid;

  String get doctorName {
    if (doctor == null) return 'Inconnu';
    final first = doctor!['firstName'] as String? ?? '';
    final last = doctor!['lastName'] as String? ?? '';
    return 'Dr. $first $last'.trim();
  }

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final data = json['attributes'] as Map<String, dynamic>? ?? json;
    final id = json['id'] as int? ?? 0;

    InvoiceStatus status = InvoiceStatus.pending;
    switch (data['status'] as String? ?? 'pending') {
      case 'paid': status = InvoiceStatus.paid;
      case 'cancelled': status = InvoiceStatus.cancelled;
      case 'refunded': status = InvoiceStatus.refunded;
    }

    InvoiceType type = switch (data['type'] as String? ?? '') {
      'lab_test' => InvoiceType.labTest,
      'prescription' => InvoiceType.prescription,
      _ => InvoiceType.consultation,
    };

    PaymentMethod? paymentMethod;
    switch (data['paymentMethod'] as String? ?? '') {
      case 'bank_transfer': paymentMethod = PaymentMethod.bankTransfer;
      case 'mobile_money': paymentMethod = PaymentMethod.mobileMoney;
      case 'cash': paymentMethod = PaymentMethod.cash;
      case 'card': paymentMethod = PaymentMethod.card;
    }

    Map<String, dynamic>? parseRelation(dynamic raw) {
      if (raw is! Map<String, dynamic>) return null;
      final nested = raw['data'] as Map<String, dynamic>?;
      if (nested != null) {
        final attrs = nested['attributes'] as Map<String, dynamic>? ?? nested;
        return {'id': nested['id'], ...attrs};
      }
      if (raw['id'] != null) return raw;
      return null;
    }

    return InvoiceModel(
      id: id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      status: status,
      type: type,
      description: data['description'] as String?,
      paymentMethod: paymentMethod,
      dueDate: data['dueDate'] != null
          ? DateTime.tryParse(data['dueDate'] as String)
          : null,
      paidAt: data['paidAt'] != null
          ? DateTime.tryParse(data['paidAt'] as String)
          : null,
      createdAt: DateTime.tryParse(
              data['createdAt'] as String? ?? '') ??
          DateTime.now(),
      patient: parseRelation(data['patient']),
      doctor: parseRelation(data['doctor']),
      appointment: parseRelation(data['appointment']),
      labOrder: parseRelation(data['labOrder']),
    );
  }
}
