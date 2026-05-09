import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum StaffTaskStatus { pending, inProgress, done, cancelled }

extension StaffTaskStatusExt on StaffTaskStatus {
  String get apiValue => switch (this) {
        StaffTaskStatus.pending => 'pending',
        StaffTaskStatus.inProgress => 'inProgress',
        StaffTaskStatus.done => 'done',
        StaffTaskStatus.cancelled => 'cancelled',
      };

  String get label => switch (this) {
        StaffTaskStatus.pending => 'À faire',
        StaffTaskStatus.inProgress => 'En cours',
        StaffTaskStatus.done => 'Fait',
        StaffTaskStatus.cancelled => 'Annulé',
      };

  Color get color => switch (this) {
        StaffTaskStatus.pending => AppColors.warning,
        StaffTaskStatus.inProgress => AppColors.primary,
        StaffTaskStatus.done => AppColors.success,
        StaffTaskStatus.cancelled => AppColors.textHint,
      };

  static StaffTaskStatus fromApi(String v) => switch (v) {
        'inProgress' => StaffTaskStatus.inProgress,
        'done' => StaffTaskStatus.done,
        'cancelled' => StaffTaskStatus.cancelled,
        _ => StaffTaskStatus.pending,
      };
}

class StaffTaskModel {
  final int id;
  final int recoveryCaseId;
  final String patientName;
  final String? patientPhone;
  final String title;
  final String? description;
  final StaffTaskStatus status;
  final String priority;
  final DateTime dueDate;
  final DateTime? completedAt;
  final String? caseType;

  bool get isOverdue =>
      status == StaffTaskStatus.pending && dueDate.isBefore(DateTime.now());

  const StaffTaskModel({
    required this.id,
    required this.recoveryCaseId,
    required this.patientName,
    this.patientPhone,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    this.completedAt,
    this.caseType,
  });

  factory StaffTaskModel.fromJson(Map<String, dynamic> json) {
    final d = json['attributes'] as Map<String, dynamic>? ?? json;
    return StaffTaskModel(
      id: (json['id'] as num?)?.toInt() ?? (d['id'] as num?)?.toInt() ?? 0,
      recoveryCaseId: (d['recoveryCaseId'] as num?)?.toInt() ?? 0,
      patientName: d['patientName'] as String? ?? 'Patient',
      patientPhone: d['patientPhone'] as String?,
      title: d['title'] as String? ?? '',
      description: d['description'] as String?,
      status: StaffTaskStatusExt.fromApi(d['status'] as String? ?? ''),
      priority: d['priority'] as String? ?? 'medium',
      dueDate: DateTime.tryParse(d['dueDate'] as String? ?? '') ?? DateTime.now(),
      completedAt: d['completedAt'] != null
          ? DateTime.tryParse(d['completedAt'] as String)
          : null,
      caseType: d['caseType'] as String?,
    );
  }
}
