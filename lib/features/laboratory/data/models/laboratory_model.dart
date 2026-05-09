import 'package:flutter/material.dart';
import 'package:medicare/core/constants/app_colors.dart';

enum LabType { laboratory, clinic, hospital, radiology, other }

extension LabTypeExt on LabType {
  String get label => switch (this) {
        LabType.laboratory => 'Laboratoire',
        LabType.clinic => 'Clinique',
        LabType.hospital => 'Hôpital',
        LabType.radiology => 'Radiologie',
        LabType.other => 'Autre',
      };

  String get apiValue => switch (this) {
        LabType.laboratory => 'laboratory',
        LabType.clinic => 'clinic',
        LabType.hospital => 'hospital',
        LabType.radiology => 'radiology',
        LabType.other => 'other',
      };

  Color get color => switch (this) {
        LabType.laboratory => AppColors.labColor,
        LabType.clinic => AppColors.doctorColor,
        LabType.hospital => AppColors.primaryLight,
        LabType.radiology => AppColors.tertiary,
        LabType.other => AppColors.mrOther,
      };

  IconData get icon => switch (this) {
        LabType.laboratory => Icons.science_rounded,
        LabType.clinic => Icons.local_hospital_rounded,
        LabType.hospital => Icons.business_rounded,
        LabType.radiology => Icons.image_rounded,
        LabType.other => Icons.medical_services_rounded,
      };
}

class LaboratoryModel {
  final int id;
  final String name;
  final LabType type;
  final String? address;
  final String? phone;
  final String? email;
  final String? description;
  final String? openingHours;
  final bool isActive;

  const LaboratoryModel({
    required this.id,
    required this.name,
    required this.type,
    this.address,
    this.phone,
    this.email,
    this.description,
    this.openingHours,
    this.isActive = true,
  });

  factory LaboratoryModel.fromJson(Map<String, dynamic> json) {
    final data = json['attributes'] as Map<String, dynamic>? ?? json;
    final id = json['id'] as int? ?? 0;

    final typeStr = data['type'] as String? ?? 'laboratory';
    final type = LabType.values.firstWhere(
      (t) => t.apiValue == typeStr,
      orElse: () => LabType.laboratory,
    );

    return LaboratoryModel(
      id: id,
      name: data['name'] as String? ?? '',
      type: type,
      address: data['address'] as String?,
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      description: data['description'] as String?,
      openingHours: data['openingHours'] as String?,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.apiValue,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (description != null) 'description': description,
        if (openingHours != null) 'openingHours': openingHours,
        'isActive': isActive,
      };
}
