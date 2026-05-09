class Medication {
  final String name;
  final String dosage;
  final String frequency;
  final String? duration;
  final String? notes;

  const Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    this.duration,
    this.notes,
  });

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        name: json['name'] as String? ?? '',
        dosage: json['dosage'] as String? ?? '',
        frequency: json['frequency'] as String? ?? '',
        duration: json['duration'] as String?,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        if (duration != null && duration!.isNotEmpty) 'duration': duration,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}

enum PrescriptionStatus { active, expired, cancelled }

extension PrescriptionStatusExt on PrescriptionStatus {
  String get label => switch (this) {
        PrescriptionStatus.active => 'Active',
        PrescriptionStatus.expired => 'Expirée',
        PrescriptionStatus.cancelled => 'Annulée',
      };

  String get apiValue => name;
}

class PrescriptionModel {
  final int id;
  final DateTime issuedDate;
  final DateTime? expiryDate;
  final PrescriptionStatus status;
  final List<Medication> medications;
  final String? instructions;
  final String? diagnosis;
  final Map<String, dynamic>? doctor;
  final Map<String, dynamic>? patient;

  const PrescriptionModel({
    required this.id,
    required this.issuedDate,
    this.expiryDate,
    required this.status,
    required this.medications,
    this.instructions,
    this.diagnosis,
    this.doctor,
    this.patient,
  });

  String get doctorName {
    if (doctor == null) return 'Médecin inconnu';
    final first = doctor!['firstName'] as String? ?? '';
    final last = doctor!['lastName'] as String? ?? '';
    return 'Dr. $first $last'.trim();
  }

  bool get isActive => status == PrescriptionStatus.active;

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'active';
    final status = PrescriptionStatus.values.firstWhere(
      (s) => s.apiValue == statusStr,
      orElse: () => PrescriptionStatus.active,
    );

    final medsRaw = json['medications'];
    List<Medication> meds = [];
    if (medsRaw is List) {
      meds = medsRaw
          .whereType<Map<String, dynamic>>()
          .map(Medication.fromJson)
          .toList();
    }

    return PrescriptionModel(
      id: json['id'] as int,
      issuedDate: DateTime.parse(json['issuedDate'] as String),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      status: status,
      medications: meds,
      instructions: json['instructions'] as String?,
      diagnosis: json['diagnosis'] as String?,
      doctor: json['doctor'] as Map<String, dynamic>?,
      patient: json['patient'] as Map<String, dynamic>?,
    );
  }
}
