class DraftMedication {
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String instructions;

  const DraftMedication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instructions,
  });

  factory DraftMedication.fromJson(Map<String, dynamic> j) => DraftMedication(
        name: j['name'] as String? ?? '',
        dosage: j['dosage'] as String? ?? '',
        frequency: j['frequency'] as String? ?? '',
        duration: j['duration'] as String? ?? '',
        instructions: j['instructions'] as String? ?? '',
      );
}

class PrescriptionDraftModel {
  final String diagnosis;
  final List<DraftMedication> medications;
  final String notes;
  final String followUp;

  const PrescriptionDraftModel({
    required this.diagnosis,
    required this.medications,
    required this.notes,
    required this.followUp,
  });

  factory PrescriptionDraftModel.fromJson(Map<String, dynamic> j) {
    final meds = (j['medications'] as List? ?? [])
        .map((e) => DraftMedication.fromJson(e as Map<String, dynamic>))
        .toList();
    return PrescriptionDraftModel(
      diagnosis: j['diagnosis'] as String? ?? '',
      medications: meds,
      notes: j['notes'] as String? ?? '',
      followUp: j['followUp'] as String? ?? '',
    );
  }
}

class DiagnosticHypothesis {
  final String name;
  final String probability; // 'élevée' | 'moyenne' | 'faible'
  final String rationale;
  const DiagnosticHypothesis(
      {required this.name, required this.probability, required this.rationale});

  factory DiagnosticHypothesis.fromJson(Map<String, dynamic> j) =>
      DiagnosticHypothesis(
        name: j['name'] as String? ?? '',
        probability: j['probability'] as String? ?? '',
        rationale: j['rationale'] as String? ?? '',
      );
}

class DiagnosticSuggestionsModel {
  final List<DiagnosticHypothesis> hypotheses;
  final List<String> recommendedExams;
  final String disclaimer;

  const DiagnosticSuggestionsModel({
    required this.hypotheses,
    required this.recommendedExams,
    required this.disclaimer,
  });

  factory DiagnosticSuggestionsModel.fromJson(Map<String, dynamic> j) =>
      DiagnosticSuggestionsModel(
        hypotheses: (j['hypotheses'] as List? ?? [])
            .map((e) =>
                DiagnosticHypothesis.fromJson(e as Map<String, dynamic>))
            .toList(),
        recommendedExams: (j['recommended_exams'] as List? ?? [])
            .map((e) => e as String)
            .toList(),
        disclaimer: j['disclaimer'] as String? ?? '',
      );
}
