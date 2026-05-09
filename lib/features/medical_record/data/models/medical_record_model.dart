import 'package:flutter/material.dart';
import 'package:medicare/core/constants/app_colors.dart';

enum MedicalRecordType { labResult, imaging, consultation, vaccination, surgery, other }

extension MedicalRecordTypeExt on MedicalRecordType {
  String get label => switch (this) {
        MedicalRecordType.labResult => 'Analyse',
        MedicalRecordType.imaging => 'Imagerie',
        MedicalRecordType.consultation => 'Consultation',
        MedicalRecordType.vaccination => 'Vaccination',
        MedicalRecordType.surgery => 'Chirurgie',
        MedicalRecordType.other => 'Autre',
      };

  String get apiValue => switch (this) {
        MedicalRecordType.labResult => 'lab_result',
        MedicalRecordType.imaging => 'imaging',
        MedicalRecordType.consultation => 'consultation',
        MedicalRecordType.vaccination => 'vaccination',
        MedicalRecordType.surgery => 'surgery',
        MedicalRecordType.other => 'other',
      };

  Color get color => switch (this) {
        MedicalRecordType.labResult => AppColors.mrLabResult,
        MedicalRecordType.imaging => AppColors.mrImaging,
        MedicalRecordType.consultation => AppColors.mrConsultation,
        MedicalRecordType.vaccination => AppColors.mrVaccination,
        MedicalRecordType.surgery => AppColors.mrSurgery,
        MedicalRecordType.other => AppColors.mrOther,
      };

  IconData get icon => switch (this) {
        MedicalRecordType.labResult => Icons.science_outlined,
        MedicalRecordType.imaging => Icons.image_outlined,
        MedicalRecordType.consultation => Icons.medical_information_outlined,
        MedicalRecordType.vaccination => Icons.vaccines_outlined,
        MedicalRecordType.surgery => Icons.medical_services_outlined,
        MedicalRecordType.other => Icons.folder_outlined,
      };
}

class MedicalRecordModel {
  final int id;
  final String title;
  final MedicalRecordType type;
  final DateTime date;
  final String? description;
  final dynamic results;
  final bool isPrivate;
  final Map<String, dynamic>? doctor;
  final Map<String, dynamic>? patient;

  const MedicalRecordModel({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    this.description,
    this.results,
    required this.isPrivate,
    this.doctor,
    this.patient,
  });

  String get doctorName {
    if (doctor == null) return 'Médecin inconnu';
    final first = doctor!['firstName'] as String? ?? '';
    final last = doctor!['lastName'] as String? ?? '';
    return 'Dr. $first $last'.trim();
  }

  factory MedicalRecordModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'other';
    final type = MedicalRecordType.values.firstWhere(
      (t) => t.apiValue == typeStr,
      orElse: () => MedicalRecordType.other,
    );

    return MedicalRecordModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      type: type,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
      results: json['results'],
      isPrivate: json['isPrivate'] as bool? ?? false,
      doctor: json['doctor'] as Map<String, dynamic>?,
      patient: json['patient'] as Map<String, dynamic>?,
    );
  }
}
