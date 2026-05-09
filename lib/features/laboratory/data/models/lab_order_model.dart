import 'laboratory_model.dart';

enum LabOrderStatus { pending, inProgress, completed, cancelled }

extension LabOrderStatusExt on LabOrderStatus {
  String get label => switch (this) {
        LabOrderStatus.pending => 'En attente',
        LabOrderStatus.inProgress => 'En cours',
        LabOrderStatus.completed => 'Résultats disponibles',
        LabOrderStatus.cancelled => 'Annulée',
      };
  String get apiValue => switch (this) {
        LabOrderStatus.pending => 'pending',
        LabOrderStatus.inProgress => 'in_progress',
        LabOrderStatus.completed => 'completed',
        LabOrderStatus.cancelled => 'cancelled',
      };
}

class LabTest {
  final String name;
  final double price;
  final String? notes;

  const LabTest({required this.name, required this.price, this.notes});

  factory LabTest.fromJson(Map<String, dynamic> json) => LabTest(
        name: json['name'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}

class LabOrderModel {
  final int id;
  final LabOrderStatus status;
  final List<LabTest> tests;
  final double totalAmount;
  final DateTime orderedAt;
  final DateTime? completedAt;
  final String? notes;
  final String? results;
  final LaboratoryModel? laboratory;
  final Map<String, dynamic>? patient;
  final Map<String, dynamic>? doctor;

  const LabOrderModel({
    required this.id,
    required this.status,
    required this.tests,
    required this.totalAmount,
    required this.orderedAt,
    this.completedAt,
    this.notes,
    this.results,
    this.laboratory,
    this.patient,
    this.doctor,
  });

  String get patientName {
    if (patient == null) return 'Patient inconnu';
    final first = patient!['firstName'] as String? ?? '';
    final last = patient!['lastName'] as String? ?? '';
    if (first.isNotEmpty || last.isNotEmpty) return '$first $last'.trim();
    return patient!['username'] as String? ?? 'Patient';
  }

  String get doctorName {
    if (doctor == null) return 'Médecin inconnu';
    final first = doctor!['firstName'] as String? ?? '';
    final last = doctor!['lastName'] as String? ?? '';
    return 'Dr. $first $last'.trim();
  }

  factory LabOrderModel.fromJson(Map<String, dynamic> json) {
    final data = json['attributes'] as Map<String, dynamic>? ?? json;
    final id = json['id'] as int? ?? 0;

    final statusStr = data['status'] as String? ?? 'pending';
    final status = LabOrderStatus.values.firstWhere(
      (s) => s.apiValue == statusStr,
      orElse: () => LabOrderStatus.pending,
    );

    final testsRaw = data['tests'];
    List<LabTest> tests = [];
    if (testsRaw is List) {
      tests = testsRaw
          .whereType<Map<String, dynamic>>()
          .map(LabTest.fromJson)
          .toList();
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

    LaboratoryModel? laboratory;
    final labRaw = parseRelation(data['laboratory']);
    if (labRaw != null) laboratory = LaboratoryModel.fromJson(labRaw);

    return LabOrderModel(
      id: id,
      status: status,
      tests: tests,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      orderedAt: DateTime.tryParse(data['orderedAt'] as String? ?? '') ??
          DateTime.now(),
      completedAt: data['completedAt'] != null
          ? DateTime.tryParse(data['completedAt'] as String)
          : null,
      notes: data['notes'] as String?,
      results: data['results'] as String?,
      laboratory: laboratory,
      patient: parseRelation(data['patient']),
      doctor: parseRelation(data['doctor']),
    );
  }
}
