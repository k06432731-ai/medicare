import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum RecoveryCaseType {
  noShow,
  abandonedBooking,
  inactivePatient,
  interruptedChronic,
  incompletePreconsult,
  missedCall,
}

enum RecoveryCaseStatus { open, inProgress, recovered, escalated, closed }

enum RecoveryCasePriority { low, medium, high, critical }

extension RecoveryCaseTypeExt on RecoveryCaseType {
  String get apiValue => switch (this) {
        RecoveryCaseType.noShow => 'noShow',
        RecoveryCaseType.abandonedBooking => 'abandonedBooking',
        RecoveryCaseType.inactivePatient => 'inactivePatient',
        RecoveryCaseType.interruptedChronic => 'interruptedChronic',
        RecoveryCaseType.incompletePreconsult => 'incompletePreconsult',
        RecoveryCaseType.missedCall => 'missedCall',
      };

  String get label => switch (this) {
        RecoveryCaseType.noShow => 'No-show',
        RecoveryCaseType.abandonedBooking => 'Réservation abandonnée',
        RecoveryCaseType.inactivePatient => 'Patient inactif',
        RecoveryCaseType.interruptedChronic => 'Suivi chronique interrompu',
        RecoveryCaseType.incompletePreconsult => 'Pré-consultation incomplète',
        RecoveryCaseType.missedCall => 'Appel manqué',
      };

  IconData get icon => switch (this) {
        RecoveryCaseType.noShow => Icons.event_busy_rounded,
        RecoveryCaseType.abandonedBooking => Icons.cancel_schedule_send_rounded,
        RecoveryCaseType.inactivePatient => Icons.person_off_rounded,
        RecoveryCaseType.interruptedChronic => Icons.medication_liquid_rounded,
        RecoveryCaseType.incompletePreconsult => Icons.assignment_late_rounded,
        RecoveryCaseType.missedCall => Icons.phone_missed_rounded,
      };

  Color get color => switch (this) {
        RecoveryCaseType.noShow => AppColors.error,
        RecoveryCaseType.abandonedBooking => AppColors.warning,
        RecoveryCaseType.inactivePatient => AppColors.textHint,
        RecoveryCaseType.interruptedChronic => AppColors.tertiary,
        RecoveryCaseType.incompletePreconsult => AppColors.primary,
        RecoveryCaseType.missedCall => AppColors.secondary,
      };

  static RecoveryCaseType fromApi(String v) => switch (v) {
        'noShow' => RecoveryCaseType.noShow,
        'abandonedBooking' => RecoveryCaseType.abandonedBooking,
        'inactivePatient' => RecoveryCaseType.inactivePatient,
        'interruptedChronic' => RecoveryCaseType.interruptedChronic,
        'incompletePreconsult' => RecoveryCaseType.incompletePreconsult,
        _ => RecoveryCaseType.missedCall,
      };
}

extension RecoveryCaseStatusExt on RecoveryCaseStatus {
  String get apiValue => switch (this) {
        RecoveryCaseStatus.open => 'open',
        RecoveryCaseStatus.inProgress => 'inProgress',
        RecoveryCaseStatus.recovered => 'recovered',
        RecoveryCaseStatus.escalated => 'escalated',
        RecoveryCaseStatus.closed => 'closed',
      };

  String get label => switch (this) {
        RecoveryCaseStatus.open => 'Ouvert',
        RecoveryCaseStatus.inProgress => 'En cours',
        RecoveryCaseStatus.recovered => 'Récupéré',
        RecoveryCaseStatus.escalated => 'Escaladé',
        RecoveryCaseStatus.closed => 'Clos',
      };

  Color get color => switch (this) {
        RecoveryCaseStatus.open => AppColors.warning,
        RecoveryCaseStatus.inProgress => AppColors.primary,
        RecoveryCaseStatus.recovered => AppColors.success,
        RecoveryCaseStatus.escalated => AppColors.error,
        RecoveryCaseStatus.closed => AppColors.textHint,
      };

  static RecoveryCaseStatus fromApi(String v) => switch (v) {
        'inProgress' => RecoveryCaseStatus.inProgress,
        'recovered' => RecoveryCaseStatus.recovered,
        'escalated' => RecoveryCaseStatus.escalated,
        'closed' => RecoveryCaseStatus.closed,
        _ => RecoveryCaseStatus.open,
      };
}

extension RecoveryCasePriorityExt on RecoveryCasePriority {
  String get apiValue => switch (this) {
        RecoveryCasePriority.low => 'low',
        RecoveryCasePriority.medium => 'medium',
        RecoveryCasePriority.high => 'high',
        RecoveryCasePriority.critical => 'critical',
      };

  Color get color => switch (this) {
        RecoveryCasePriority.low => AppColors.textHint,
        RecoveryCasePriority.medium => AppColors.warning,
        RecoveryCasePriority.high => AppColors.error,
        RecoveryCasePriority.critical => const Color(0xFF7C3AED),
      };

  static RecoveryCasePriority fromApi(String v) => switch (v) {
        'low' => RecoveryCasePriority.low,
        'high' => RecoveryCasePriority.high,
        'critical' => RecoveryCasePriority.critical,
        _ => RecoveryCasePriority.medium,
      };
}

class RecoveryCaseModel {
  final int id;
  final RecoveryCaseType type;
  final RecoveryCaseStatus status;
  final RecoveryCasePriority priority;
  final int attempts;
  final int patientId;
  final String patientName;
  final String? patientPhone;
  final int? appointmentId;
  final DateTime? appointmentDate;
  final String? doctorName;
  final DateTime triggerDate;
  final DateTime? recoveredAt;
  final String? notes;
  final double estimatedValue;

  const RecoveryCaseModel({
    required this.id,
    required this.type,
    required this.status,
    required this.priority,
    required this.attempts,
    required this.patientId,
    required this.patientName,
    this.patientPhone,
    this.appointmentId,
    this.appointmentDate,
    this.doctorName,
    required this.triggerDate,
    this.recoveredAt,
    this.notes,
    this.estimatedValue = 0,
  });

  factory RecoveryCaseModel.fromJson(Map<String, dynamic> json) {
    final d = json['attributes'] as Map<String, dynamic>? ?? json;
    return RecoveryCaseModel(
      id: (json['id'] as num?)?.toInt() ?? (d['id'] as num?)?.toInt() ?? 0,
      type: RecoveryCaseTypeExt.fromApi(d['type'] as String? ?? ''),
      status: RecoveryCaseStatusExt.fromApi(d['status'] as String? ?? ''),
      priority: RecoveryCasePriorityExt.fromApi(d['priority'] as String? ?? ''),
      attempts: (d['attempts'] as num?)?.toInt() ?? 0,
      patientId: (d['patientId'] as num?)?.toInt() ?? 0,
      patientName: d['patientName'] as String? ?? 'Patient',
      patientPhone: d['patientPhone'] as String?,
      appointmentId: (d['appointmentId'] as num?)?.toInt(),
      appointmentDate: d['appointmentDate'] != null
          ? DateTime.tryParse(d['appointmentDate'] as String)
          : null,
      doctorName: d['doctorName'] as String?,
      triggerDate: DateTime.tryParse(d['triggerDate'] as String? ?? '') ?? DateTime.now(),
      recoveredAt: d['recoveredAt'] != null
          ? DateTime.tryParse(d['recoveredAt'] as String)
          : null,
      notes: d['notes'] as String?,
      estimatedValue: (d['estimatedValue'] as num?)?.toDouble() ?? 0,
    );
  }
}
