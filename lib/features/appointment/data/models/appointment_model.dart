import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:medicare/core/constants/app_colors.dart';
import 'package:medicare/features/doctor/data/models/doctor_model.dart';

enum AppointmentStatus { pending, confirmed, cancelled, completed, noShow }

enum AppointmentType { inPerson, teleconsultation }

extension AppointmentStatusExt on AppointmentStatus {
  String get label => switch (this) {
        AppointmentStatus.pending => 'En attente',
        AppointmentStatus.confirmed => 'Confirmé',
        AppointmentStatus.cancelled => 'Annulé',
        AppointmentStatus.completed => 'Terminé',
        AppointmentStatus.noShow => 'Absent',
      };

  String get apiValue => switch (this) {
        AppointmentStatus.pending => 'pending',
        AppointmentStatus.confirmed => 'confirmed',
        AppointmentStatus.cancelled => 'cancelled',
        AppointmentStatus.completed => 'completed',
        AppointmentStatus.noShow => 'no_show',
      };

  Color get color => switch (this) {
        AppointmentStatus.pending => AppColors.warning,
        AppointmentStatus.confirmed => AppColors.doctorColor,
        AppointmentStatus.cancelled => AppColors.error,
        AppointmentStatus.completed => AppColors.success,
        AppointmentStatus.noShow => AppColors.textSecondary,
      };
}

extension AppointmentTypeExt on AppointmentType {
  String get label => switch (this) {
        AppointmentType.inPerson => 'En personne',
        AppointmentType.teleconsultation => 'Téléconsultation',
      };

  String get apiValue => switch (this) {
        AppointmentType.inPerson => 'in_person',
        AppointmentType.teleconsultation => 'teleconsultation',
      };
}

class AppointmentModel extends Equatable {
  final int id;
  final DateTime appointmentDate;
  final DateTime? endTime;
  final AppointmentStatus status;
  final AppointmentType type;
  final String reason;
  final String? notes;
  final DoctorModel? doctor;
  final Map<String, dynamic>? patient;

  const AppointmentModel({
    required this.id,
    required this.appointmentDate,
    this.endTime,
    required this.status,
    required this.type,
    required this.reason,
    this.notes,
    this.doctor,
    this.patient,
  });

  int? get patientId => patient?['id'] as int?;

  String get patientName {
    if (patient == null) return 'Patient inconnu';
    final first = patient!['firstName'] as String? ?? '';
    final last = patient!['lastName'] as String? ?? '';
    if (first.isNotEmpty || last.isNotEmpty) return '$first $last'.trim();
    return patient!['username'] as String? ?? 'Patient';
  }

  bool get isUpcoming =>
      appointmentDate.isAfter(DateTime.now()) &&
      (status == AppointmentStatus.pending ||
          status == AppointmentStatus.confirmed);

  bool get isPast =>
      appointmentDate.isBefore(DateTime.now()) ||
      status == AppointmentStatus.completed ||
      status == AppointmentStatus.cancelled;

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    // Support both Strapi v4 (attributes) and v5 (flat) format
    final data = json['attributes'] as Map<String, dynamic>? ?? json;
    final id = json['id'] as int? ?? 0;

    AppointmentStatus status = AppointmentStatus.pending;
    switch (data['status'] as String? ?? 'pending') {
      case 'confirmed':
        status = AppointmentStatus.confirmed;
      case 'cancelled':
        status = AppointmentStatus.cancelled;
      case 'completed':
        status = AppointmentStatus.completed;
      case 'no_show':
        status = AppointmentStatus.noShow;
    }

    AppointmentType type = AppointmentType.inPerson;
    if (data['type'] == 'teleconsultation') {
      type = AppointmentType.teleconsultation;
    }

    // Parse doctor (supports both nested Strapi v4 and flat v5)
    DoctorModel? doctor;
    final doctorRaw = data['doctor'];
    if (doctorRaw is Map<String, dynamic>) {
      final nested = doctorRaw['data'] as Map<String, dynamic>?;
      if (nested != null) {
        final attrs = nested['attributes'] as Map<String, dynamic>? ?? nested;
        doctor = DoctorModel.fromJson({'id': nested['id'], ...attrs});
      } else if (doctorRaw['id'] != null) {
        doctor = DoctorModel.fromJson(doctorRaw);
      }
    }

    // Parse patient (flat v5)
    Map<String, dynamic>? patient;
    final patientRaw = data['patient'];
    if (patientRaw is Map<String, dynamic>) {
      final nested = patientRaw['data'] as Map<String, dynamic>?;
      if (nested != null) {
        final attrs = nested['attributes'] as Map<String, dynamic>? ?? nested;
        patient = {'id': nested['id'], ...attrs};
      } else if (patientRaw['id'] != null) {
        patient = patientRaw;
      }
    }

    return AppointmentModel(
      id: id,
      appointmentDate: DateTime.parse(data['appointmentDate'] as String),
      endTime: data['endTime'] != null
          ? DateTime.parse(data['endTime'] as String)
          : null,
      status: status,
      type: type,
      reason: data['reason'] as String? ?? '',
      notes: data['notes'] as String?,
      doctor: doctor,
      patient: patient,
    );
  }

  @override
  List<Object?> get props => [id, appointmentDate, status, type, reason];
}
